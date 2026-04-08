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

    /// The file URL this manager reads from and writes to.
    /// Exposed so callers (e.g. AddNewView) can persist it in a DarumaEntry on save.
    let fileURL: URL

    private(set) var isRecording      = false
    private(set) var isPlaying        = false
    private(set) var hasRecording     = false
    private(set) var permissionDenied = false

    /// Normalised amplitude levels (0–1) sampled at 20 Hz during recording.
    /// Retained after stopRecording() so the UI can display a static summary.
    private(set) var audioLevels: [Float] = []

    /// Elapsed wall-clock seconds of the current recording session.
    private(set) var recordingDuration: TimeInterval = 0

    /// Total duration of the persisted recording file (seconds).
    private(set) var totalDuration: TimeInterval = 0

    /// Fraction (0–1) of the recording that has been played back.
    private(set) var playbackProgress: Double = 0

    // MARK: - Private

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer:   AVAudioPlayer?
    private var meterTimer:    Timer?
    private var durationTimer: Timer?
    private var progressTimer: Timer?

    // MARK: - Init

    /// - Parameter recordingURL: The file to load/save. When nil a fresh UUID-named
    ///   file is created so each entry has its own isolated recording.
    init(recordingURL: URL? = nil) {
        self.fileURL = recordingURL ?? Self.makeURL()
        super.init()
        // Recover state if a recording already exists at this URL.
        if FileManager.default.fileExists(atPath: self.fileURL.path) {
            hasRecording = true
            if let probe = try? AVAudioPlayer(contentsOf: self.fileURL) {
                totalDuration = probe.duration
            }
        }
    }

    /// Generates a unique file URL inside the app's Documents directory.
    private static func makeURL() -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(UUID().uuidString).m4a")
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

            let settings: [String: Any] = [
                AVFormatIDKey:            Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey:          44_100,
                AVNumberOfChannelsKey:    1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            audioLevels       = []
            recordingDuration = 0
            isRecording       = true

            startMetering()
            startDurationTimer()
        } catch {
            print("AudioRecorderManager — startRecording failed: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil          // release file handle + hardware resources
        isRecording   = false

        stopMetering()
        stopDurationTimer()

        hasRecording = FileManager.default.fileExists(atPath: fileURL.path)

        // Derive exact duration from the written file.
        if hasRecording, let probe = try? AVAudioPlayer(contentsOf: fileURL) {
            totalDuration = probe.duration
        }

        deactivateSession()
    }

    // MARK: - Playback

    func playRecording() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()

            playbackProgress = 0
            isPlaying        = true

            startProgressTimer()
        } catch {
            print("AudioRecorderManager — playRecording failed: \(error)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying   = false

        stopProgressTimer()
        playbackProgress = 0

        deactivateSession()
    }

    // MARK: - Delete

    /// Removes the recording file and resets all state.
    func deleteRecording() {
        stopPlayback()
        try? FileManager.default.removeItem(at: fileURL)
        hasRecording      = false
        audioLevels       = []
        recordingDuration = 0
        totalDuration     = 0
        playbackProgress  = 0
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
        audioLevels.append(normalized)
        if audioLevels.count > 80 {
            audioLevels = Array(audioLevels.suffix(80))
        }
    }

    // MARK: - Duration timer (private)

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.recordingDuration += 0.1 }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    // MARK: - Progress timer (private)

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.audioPlayer else { return }
                self.playbackProgress = player.duration > 0
                    ? player.currentTime / player.duration
                    : 0
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Audio session

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorderManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying        = false
            self.audioPlayer      = nil
            self.playbackProgress = 0
            self.stopProgressTimer()
            self.deactivateSession()
        }
    }
}
