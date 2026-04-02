//
//  SettingsView.swift
//  ximena
//

import SwiftUI

struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings

    private var currentIconName: String {
        AppIconOption.all.first { $0.id == settings.selectedAppIcon }?.displayName ?? "Default"
    }

    var body: some View {
        
        @Bindable var settings = settings

        List {

            // MARK: - Appearance

            Section("Appearance") {
                NavigationLink {
                    FontPickerView()
                } label: {
                    LabeledContent {
                        Text(settings.currentFont.displayName)
                    } label: {
                        Label("Text Font", systemImage: "textformat")
                    }
                }

                NavigationLink {
                    IconSelectionView()
                } label: {
                    LabeledContent {
                        Text(currentIconName)
                    } label: {
                        Label("App Icon", systemImage: "app.badge")
                    }
                }
            }

            // MARK: - Audio

            Section("Audio") {
                // .animation on the Binding wraps its setter in withAnimation,
                // which drives the conditional slider insertion/removal below.
                Toggle(isOn: $settings.musicEnabled.animation(.easeInOut(duration: 0.2))) {
                    Label("Music", systemImage: "music.note")
                }

                if settings.musicEnabled {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Slider(value: $settings.musicVolume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 22)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Toggle(isOn: $settings.sfxEnabled) {
                    Label("Sound Effects", systemImage: "speaker.wave.2")
                }
            }

            // MARK: - Feedback

            Section("Feedback") {
                Toggle(isOn: $settings.hapticsEnabled) {
                    Label("Haptics", systemImage: "hand.tap")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(SettingsManager())
    }
}
