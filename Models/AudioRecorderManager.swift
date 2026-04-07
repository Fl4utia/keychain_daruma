//
//  AudioRecorderManager.swift
//  ximena
//
//  Created by Salvatore De Rosa on 03/04/2026.
//

import AVFoundation
import Observation

@MainActor
@Observable
final class AudioRecorderManager: NSObject {

    // MARK: - Public state

    private(set) var isRecording    = false
    private(set) var isPlaying      = false
    private(set) var hasRecording   = false
    private(set) var permissionDenied = false
    private(set) var recordingURL: URL?
    /// Normalised amplitude levels (0–1) sampled at 20 Hz during recording.
    private(set) var audioLevels: [Float] = []

    // MARK: - Private

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer:   AVAudioPlayer?
    private var meterTimer:    Timer?

    /// Stable per-session URL. One recording per manager instance.
    private static var sessionURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("daruma_recording.m4a")
    }

    // MARK: - Init

    override init() {
        super.init()
        // Recover state if a recording already exists from a previous session.
        let url = Self.sessionURL
        if FileManager.default.fileExists(atPath: url.path) {
            recordingURL  = url
            hasRecording  = true
        }
    }

    // MARK: - Recording

    func startRecording() async {
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else {
            permissionDenied = true
            return
        }
        permissionDenied = false

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)

            let url = Self.sessionURL
            let settings: [String: Any] = [
                AVFormatIDKey:            Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey:          44_100,
                AVNumberOfChannelsKey:    1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            recordingURL = url
            audioLevels  = []
            isRecording  = true
            startMetering()
        } catch {
            print("AudioRecorderManager — startRecording failed: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil          // release file handle + hardware resources
        isRecording   = false
        stopMetering()

        // Verify the file was actually written — recordingURL alone is not enough.
        hasRecording = recordingURL.map {
            FileManager.default.fileExists(atPath: $0.path)
        } ?? false

        deactivateSession()
    }

    // MARK: - Playback

    func playRecording() {
        guard let url = recordingURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("AudioRecorderManager — playRecording failed: \(error)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil            // release audio buffers
        isPlaying   = false
        deactivateSession()
    }

    // MARK: - Delete

    /// Discards the current recording and resets all state.
    /// Call this when the user wants to re-record.
    func deleteRecording() {
        stopPlayback()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL  = nil
        hasRecording  = false
        audioLevels   = []
    }

    // MARK: - Metering (private)

    private func startMetering() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.sampleMeter() }
        }
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
    }

    private func sampleMeter() {
        audioRecorder?.updateMeters()
        let db         = audioRecorder?.averagePower(forChannel: 0) ?? -60
        let normalized = Float(max(0.0, (db + 60.0) / 60.0))

        // Keep a fixed-size sliding window with a single O(1) append + one conditional slice.
        audioLevels.append(normalized)
        if audioLevels.count > 80 {
            audioLevels = Array(audioLevels.suffix(80))   // slice, not removeFirst shift
        }
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorderManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.audioPlayer = nil
            self.isPlaying   = false
            self.deactivateSession()
        }
    }
}
