//
//  FirstSettingsView.swift
//  ximena
//

import SwiftUI

struct FirstSettingsView: View {
    @Environment(SettingsManager.self) private var settings
    let onComplete: () -> Void
    @State private var hasScrolledToBottom = false

    private let previewText = "Every detail matters."

    var body: some View {
        @Bindable var settings = settings

        List {

            // MARK: - Header
            
            Section {
                    Text("Settings")
                        .font(settings.currentFont.largeTitleFont)
                        .fontWeight(.bold)
                
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // MARK: - Appearance
            Section("Appearance") {

                // Live preview — .id() gives the Text a new identity on each selection,
                // triggering the opacity transition inside withAnimation.
                Text(previewText)
                    .font(settings.currentFont.largePresentationFont)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .id(settings.currentFont)
                    .transition(.opacity)
                    .listRowSeparator(.hidden)

                // Inline font picker — shown here rather than pushing a new screen,
                // so the user sees the effect on surrounding text immediately.
                ForEach(AppFont.allCases) { font in
                    FontRow(
                        font: font,
                        isSelected: settings.currentFont == font
                    ) {
                        selectFont(font)
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

            // MARK: - Sentinel
            // Zero-height row at the end of the list. When it enters the viewport
            // the user has seen all settings and the Continue button is revealed.
            Color.clear
                .frame(height: 1)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .onAppear { hasScrolledToBottom = true }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.2), value: settings.currentFont)
        // "Continue" is pinned to the bottom so it is always reachable without scrolling,
        // while the list scrolls freely behind it.
        .safeAreaInset(edge: .bottom) {
            if hasScrolledToBottom {
                Button {
                    onComplete()
                } label: {
                    Text("Continue")
                        .font(settings.currentFont.headlineFont)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: hasScrolledToBottom)
    }

    // MARK: - Private

    private func selectFont(_ font: AppFont) {
        guard settings.currentFont != font else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            settings.selectedFont = font.rawValue
        }
        guard settings.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

#Preview {
    FirstSettingsView { }
        .environment(SettingsManager())
}
