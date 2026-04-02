//
//  IconSelectionView.swift
//  ximena
//

import SwiftUI

struct IconSelectionView: View {
    @Environment(SettingsManager.self) private var settings
    @State private var isChanging = false
    @State private var showErrorAlert = false

    // Drives both sections reactively — no extra @State needed.
    private var currentOption: AppIconOption {
        AppIconOption.all.first { $0.id == settings.selectedAppIcon } ?? AppIconOption.all[0]
    }

    private var otherOptions: [AppIconOption] {
        AppIconOption.all.filter { $0.id != settings.selectedAppIcon }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: Active Icon
                // Position alone communicates "current" — no redundant label needed.
                ActiveIconView(option: currentOption)
                    .padding(.top, 36)
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity)

                // MARK: Other Icons
                SectionHeader(title: "Other Icons")

                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(otherOptions) { option in
                        IconCell(
                            option: option,
                            isSelected: false,
                            isChanging: isChanging
                        ) {
                            applyIcon(option)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            // Single animation driver: both sections reflow when selectedAppIcon changes.
            .animation(.easeInOut(duration: 0.25), value: settings.selectedAppIcon)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn't Change Icon", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your app icon couldn't be updated. Please try again later.")
        }
    }

    // MARK: - Private

    private func applyIcon(_ option: AppIconOption) {
        guard !isChanging, settings.selectedAppIcon != option.id else { return }
        guard UIApplication.shared.supportsAlternateIcons else { return }
        isChanging = true
        UIApplication.shared.setAlternateIconName(option.iconName) { error in
            DispatchQueue.main.async {
                isChanging = false
                if error != nil {
                    showErrorAlert = true
                    return
                }
                withAnimation(.easeInOut(duration: 0.25)) {
                    settings.selectedAppIcon = option.id
                }
                if settings.hapticsEnabled {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }
}

// MARK: - Active Icon View

private struct ActiveIconView: View {
    let option: AppIconOption

    var body: some View {
        VStack(spacing: 14) {
            Image(option.previewImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color(UIColor.separator), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)

            Text(option.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
    }
}

#Preview {
    NavigationStack {
        IconSelectionView()
            .environment(SettingsManager())
    }
}
