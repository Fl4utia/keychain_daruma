//
//  IconsModel.swift
//  ximena
//
//  Created by Salvatore De Rosa on 01/04/2026.
//

import Foundation
import SwiftUI



public struct IconCell: View {
    let option: AppIconOption
    let isSelected: Bool
    let isChanging: Bool
    let action: () -> Void

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                iconPreview
                Text(option.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .opacity(isChanging && !isSelected ? 0.4 : 1)
        .animation(.spring(duration: 0.25), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isChanging)
    }

    private var iconPreview: some View {
        // Background uses the secondary grouped surface — sits naturally
        // on the screen's systemGroupedBackground without any forced color.
        // Replace the overlay Image with the real icon asset once available.
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(UIColor.secondarySystemGroupedBackground))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundStyle(.primary.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.primary : Color(UIColor.separator),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
