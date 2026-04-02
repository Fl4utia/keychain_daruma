//
//  FontPickerView.swift
//  ximena
//

import SwiftUI

struct FontPickerView: View {
    @Environment(SettingsManager.self) private var settings

    // Chosen to expose uppercase, lowercase, descenders (g, q) and digits —
    // the most diagnostic combination for comparing typefaces at a glance.
    private let previewText = "Every detail matters."

    var body: some View {
        List {

            // MARK: - Live Preview
            // .id(currentFont) gives the Text a new identity on each selection,
            // which triggers the .opacity transition inside withAnimation.
            Section {
                Text(previewText)
                    .font(settings.currentFont.largePresentationFont)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                    .id(settings.currentFont)
                    .transition(.opacity)
            }

            // MARK: - Font Options

            Section {
                ForEach(AppFont.allCases) { font in
                    FontRow(
                        font: font,
                        isSelected: settings.currentFont == font,
                        onSelect: { select(font) }
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Text Font")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private

    private func select(_ font: AppFont) {
        guard settings.currentFont != font else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            settings.selectedFont = font.rawValue
        }
        guard settings.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

#Preview {
    NavigationStack {
        FontPickerView()
            .environment(SettingsManager())
    }
}
