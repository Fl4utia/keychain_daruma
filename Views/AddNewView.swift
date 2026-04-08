//
//  AddNewView.swift
//  ximena
//
//  Created by Salvatore De Rosa on 08/04/2026.
//

import SwiftUI

struct AddNewView: View {
    let onSave: (DarumaEntry) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedType: DarumaType = .basic
    @State private var audioManager = AudioRecorderManager()
    @FocusState private var titleFocused: Bool

    private var keyboardActive: Bool { titleFocused }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Title input
                TextField("Goal", text: $title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .focused($titleFocused)
                    .submitLabel(.done)
                    .onSubmit { titleFocused = false }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Color(.systemFill),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                // Carousel + recording panel appear only after keyboard dismisses.
                // This prevents the 270pt carousel from being compressed into the
                // ~252pt of space left when the keyboard is visible.
                if !keyboardActive {
                    DarumaCarouselView(selectedType: $selectedType)
                        .padding(.top, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

            }
            // Let the keyboard overlap the layout from below rather than
            // compressing the VStack. We control what's visible via keyboardActive.
            .ignoresSafeArea(.keyboard)
            .safeAreaInset(edge: .bottom) {
                if !keyboardActive {
                    RecordingPanel(audioManager: audioManager)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: keyboardActive)
            .navigationTitle("New Daruma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        audioManager.deleteRecording()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let entry = DarumaEntry(
                            title: title.trimmingCharacters(in: .whitespaces),
                            date: Date(),
                            recordingURL: audioManager.hasRecording ? audioManager.fileURL : nil,
                            darumaType: selectedType
                        )
                        onSave(entry)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
}

// MARK: - Daruma Carousel

private struct DarumaCarouselView: View {
    @Binding var selectedType: DarumaType
    @State private var scrolledID: DarumaType?

    private let cardWidth: CGFloat = 220
    private let cardSpacing: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let inset = (geo.size.width - cardWidth) / 2
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cardSpacing) {
                    ForEach(DarumaType.allCases) { type in
                        CarouselCard(type: type, isSelected: type == selectedType)
                            .frame(width: cardWidth)
                            .id(type)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, inset)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledID)
        }
        .frame(height: 270)
        .onChange(of: scrolledID) { _, newID in
            if let id = newID { selectedType = id }
        }
        .onAppear { scrolledID = selectedType }
    }
}

// MARK: - Carousel Card

private struct CarouselCard: View {
    let type: DarumaType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            DarumaPreviewView(darumaType: type, interactive: false, entityScale: 0.65)
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .scaleEffect(isSelected ? 1.0 : 0.84)
                .opacity(isSelected ? 1.0 : 0.4)
                .animation(.spring(response: 0.4, dampingFraction: 0.78), value: isSelected)

            Text(type.displayName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .animation(.easeOut(duration: 0.2), value: isSelected)
        }
    }
}

// MARK: - Preview

#Preview {
    AddNewView { entry in
        print("Saved: \(entry.title) — \(entry.darumaType.displayName)")
    }
}
