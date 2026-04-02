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

                Toggle(isOn: $settings.leftHandedMode) {
                    Label("Left-handed Layout", systemImage: "hand.raised.fill")
                }
            }

            // MARK: - Audio

            Section("Audio") {
                
                Toggle(isOn: $settings.musicEnabled) {
                    Label("Music", systemImage: "music.note")
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
