//
//  RecordingPanel.swift
//  ximena
//
//  Created by Salvatore De Rosa on 08/04/2026.
//

import SwiftUI

// MARK: - Recording state machine (UI-only)

enum RecordState: Equatable {
    case idle, recording, recorded, playing, denied
}

// MARK: - Recording panel

struct RecordingPanel: View {
    let audioManager: AudioRecorderManager

    @State private var showDeleteConfirmation = false
    /// Toggled on confirmed delete to fire the .warning haptic.
    @State private var hapticDeleteTrigger = false

    // MARK: Derived state

    var state: RecordState {
        if audioManager.permissionDenied { return .denied }
        if audioManager.isRecording      { return .recording }
        if audioManager.isPlaying        { return .playing }
        if audioManager.hasRecording     { return .recorded }
        return .idle
    }

    private var currentLevel: Float {
        audioManager.audioLevels.last ?? 0
    }

    private var showTrash: Bool {
        // Hidden during recording to prevent accidental deletion mid-capture.
        audioManager.hasRecording && !audioManager.isRecording
    }

    private var primaryIconName: String {
        switch state {
        case .idle, .denied: return "mic.circle"
        case .recording:     return "stop.circle.fill"
        case .recorded:      return "play.circle.fill"
        case .playing:       return "pause.circle.fill"
        }
    }

    private var primaryIconColor: Color {
        state == .recording ? .red : .primary
    }

    private var primaryA11yLabel: String {
        switch state {
        case .idle, .denied: return "Start recording"
        case .recording:     return "Stop recording"
        case .recorded:      return "Play recording"
        case .playing:       return "Pause playback"
        }
    }

    /// Returns nil when no duration information is relevant (idle / denied).
    private var durationText: String? {
        switch state {
        case .idle, .denied:
            return nil
        case .recording:
            return formatDuration(audioManager.recordingDuration)
        case .recorded:
            return formatDuration(audioManager.totalDuration)
        case .playing:
            let elapsed = audioManager.playbackProgress * audioManager.totalDuration
            return "\(formatDuration(elapsed)) / \(formatDuration(audioManager.totalDuration))"
        }
    }

    /// Full spoken description for VoiceOver — avoids "zero zero colon one four" reads.
    private var durationA11yLabel: String {
        switch state {
        case .recording:
            return "Recording duration, \(Int(audioManager.recordingDuration)) seconds"
        case .recorded:
            return "Recording length, \(Int(audioManager.totalDuration)) seconds"
        case .playing:
            let elapsed = Int(audioManager.playbackProgress * audioManager.totalDuration)
            return "Playing, \(elapsed) of \(Int(audioManager.totalDuration)) seconds"
        default:
            return ""
        }
    }

    // MARK: Body

    var body: some View {
        Group {
            if state == .denied {
                PermissionBanner()
            } else {
                controls
            }
        }
        // Haptics — fired only on the rising / falling edge of each boolean.
        // No haptic on playback start: the audio itself is the feedback.
        .sensoryFeedback(.impact(weight: .medium), trigger: audioManager.isRecording) { _, new in new }
        .sensoryFeedback(.impact(weight: .light),  trigger: audioManager.isRecording) { old, _ in old }
        .sensoryFeedback(.warning, trigger: hapticDeleteTrigger)
        .confirmationDialog(
            "Delete this recording?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                audioManager.deleteRecording()
                hapticDeleteTrigger.toggle()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can record a new one afterwards.")
        }
    }

    // MARK: Controls layout

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 16) {

            // Duration row — hidden in idle state (no text to show)
            if let text = durationText {
                Text(text)
                    .font(.title3.monospacedDigit().weight(.medium))
                    .foregroundStyle(state == .recording ? Color.red : Color.primary)
                    .contentTransition(.numericText())
                    .accessibilityLabel(durationA11yLabel)
            }

            // Controls row.
            // The invisible spacer on the right mirrors the trash button on the
            // left so the primary button stays visually centred in all states.
            HStack(spacing: 32) {

                // Trash — slides in when a recording exists
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.red)
                }
                .frame(width: 44, height: 44)
                .buttonStyle(.plain)
                .accessibilityLabel("Delete recording")
                .opacity(showTrash ? 1 : 0)
                .scaleEffect(showTrash ? 1 : 0.6)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: showTrash)

                // Primary button with amplitude ring overlay
                ZStack {
                    if state == .recording {
                        AmplitudeRing(level: currentLevel)
                            .frame(width: 80, height: 80)
                            .accessibilityHidden(true)
                            .transition(.opacity.combined(with: .scale(scale: 0.7)))
                    }

                    Button {
                        primaryAction()
                    } label: {
                        Image(systemName: primaryIconName)
                            .font(.system(size: 52))
                            .foregroundStyle(primaryIconColor)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .frame(width: 64, height: 64)
                    .buttonStyle(.plain)
                    .accessibilityLabel(primaryA11yLabel)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)

                // Mirror spacer — keeps primary button centred
                Color.clear
                    .frame(width: 44, height: 44)
            }

            // Idle affordance — visible only when nothing has been recorded yet
            if state == .idle {
                Text("Tap to record")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state)
    }

    // MARK: Action

    private func primaryAction() {
        switch state {
        case .idle, .denied:
            Task { await audioManager.startRecording() }
        case .recording:
            audioManager.stopRecording()
        case .recorded:
            audioManager.playRecording()
        case .playing:
            audioManager.stopPlayback()
        }
    }
}

// MARK: - Amplitude ring

/// A single pulsing circle whose scale and opacity track live microphone amplitude.
/// Always hidden from the accessibility tree — purely decorative.
struct AmplitudeRing: View {
    let level: Float

    var body: some View {
        let scale   = 1.0 + Double(level) * 0.5
        let opacity = 0.25 + Double(level) * 0.55

        Circle()
            .stroke(Color.red.opacity(opacity), lineWidth: 4)
            .scaleEffect(scale)
            // Tight spring so the ring tracks voice without perceptible lag.
            .animation(.spring(response: 0.12, dampingFraction: 0.65), value: level)
    }
}

// MARK: - Permission banner

/// Shown in place of the recording controls when microphone access has been denied.
struct PermissionBanner: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash.circle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("Microphone access is required to record.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            } label: {
                Text("Open Settings")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .accessibilityLabel("Open Settings to allow microphone access")
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Duration formatting

func formatDuration(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    return String(format: "%d:%02d", total / 60, total % 60)
}
