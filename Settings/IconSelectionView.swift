//
//  IconSelectionView.swift
//  ximena
//

import SwiftUI

struct IconSelectionView: View {
    @Environment(SettingsManager.self) private var settings
    @State private var isChanging = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(AppIconOption.all) { option in
                    IconCell(
                        option: option,
                        isSelected: settings.selectedAppIcon == option.id,
                        isChanging: isChanging
                    ) {
                        applyIcon(option)
                    }
                }
            }
            .padding(24)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func applyIcon(_ option: AppIconOption) {
        guard !isChanging, settings.selectedAppIcon != option.id else { return }
        isChanging = true
        UIApplication.shared.setAlternateIconName(option.iconName) { error in
            DispatchQueue.main.async {
                isChanging = false
                guard error == nil else { return }
                settings.selectedAppIcon = option.id
                if settings.hapticsEnabled {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        IconSelectionView()
            .environment(SettingsManager())
    }
}
