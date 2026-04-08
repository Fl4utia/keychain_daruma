//
//  OnboardingMakeAWishPage.swift
//

import SwiftUI
import PhotosUI

/// Page 1 – "Make a Wish"
/// Uses the same input card pattern as AddNewView.
struct OnboardingMakeAWishPage: View {
    @Environment(SettingsManager.self) private var settings

    @Binding var wishText: String
    @Binding var wishDescription: String
    @Binding var darumaImage: UIImage?

    @State private var audioManager = AudioRecorderManager()
    @State private var photosPickerItem: PhotosPickerItem?

    enum InputField { case title, description }
    @FocusState private var focusedField: InputField?

    private var isInputActive: Bool { focusedField != nil }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "dd/MM/yy"; return f
    }()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                // Background tap to dismiss keyboard
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture { focusedField = nil }

                VStack(spacing: 0) {

                    // ── Title ────────────────────────────────────
                    VStack(spacing: 10) {
                        Text("Make a Wish")
                            .font(settings.currentFont.largeTitleFont)
                            .bold()
                            .multilineTextAlignment(.center)

                        Text("What goal do you want to achieve? Write it down")
                            .font(settings.currentFont.title3Font)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 0)

                    // ── Middle section: Image ────────────────────
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Daruma image
                        if !isInputActive {
                            Image("no_eye")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .transition(.opacity.combined(with: .scale))
                        }
                        
                        Spacer(minLength: 320)
                        
                    }
                }

                // ── Focus dimming ────────────────────────────────
                if isInputActive {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { focusedField = nil }
                        .transition(.opacity)
                }

                // ── Input zone ───────────────────────────────────
                VStack(spacing: 16) {
                    RecordingControlRow(audioManager: audioManager)
                        .frame(height: 52)

                    // Entry card — same pattern as AddNewView
                    VStack(spacing: 0) {

                        // Title field
                        HStack {
                            TextField("Goal title", text: $wishText)
                                .font(.headline)
                                .focused($focusedField, equals: .title)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .description }
                            if !wishText.isEmpty {
                                Button { wishText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)

                        Divider().padding(.horizontal, 16)

                        // Description field
                        TextField("Add a description...", text: $wishDescription, axis: .vertical)
                            .lineLimit(1...5)
                            .focused($focusedField, equals: .description)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                        // Photo + date row — hidden while keyboard active
                        if !isInputActive {
                            Divider().padding(.horizontal, 16)

                            HStack(spacing: 12) {
                                // Photo picker inline
                                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                                    if let img = darumaImage {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 28, height: 28)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } else {
                                        Image(systemName: "photo.badge.plus")
                                            .foregroundStyle(.secondary)
                                            .font(.system(size: 16))
                                    }
                                }

                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 13))
                                Text(Self.dateFmt.string(from: Date()))
                                    .foregroundStyle(.secondary)
                                    .font(settings.currentFont.footnoteFont)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isInputActive)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: wishDescription)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, geo.safeAreaInsets.bottom + 116)
                .zIndex(1)
            }
            .animation(.easeInOut(duration: 0.25), value: isInputActive)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    darumaImage = image
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var wish = ""
    @Previewable @State var desc = ""
    @Previewable @State var image: UIImage? = nil
    OnboardingMakeAWishPage(wishText: $wish, wishDescription: $desc, darumaImage: $image)
        .environment(SettingsManager())
}
