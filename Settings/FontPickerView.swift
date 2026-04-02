//
//  FontPickerView.swift
//  ximena
//

import SwiftUI

struct FontPickerView: View {
    @Environment(SettingsManager.self) private var settings

    // Chosen to expose uppercase, lowercase, descenders (g, q) and digits —
    // the most diagnostic combination for comparing typefaces at a glance.
    private let previewText = "Handmade with care.\nEvery detail matters."

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
                    FontOptionRow(
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

// MARK: - Font Option Row

private struct FontOptionRow: View {
    let font: AppFont
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Name always rendered in system font for guaranteed legibility
                Text(font.displayName)
                    .foregroundStyle(.primary)

                Spacer()

                // Sample rendered in the candidate font — "Ag Qq 123" surfaces
                // cap height, x-height, descenders and numeral style simultaneously
                Text("Ag Qq 123")
                    .font(font.previewFont)
                    .foregroundStyle(.secondary)

                if isSelected {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                        .padding(.leading, 8)
                }
            }
        }
        // Expand the tap target to the full row width, not just the text frames
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        FontPickerView()
            .environment(SettingsManager())
    }
}
