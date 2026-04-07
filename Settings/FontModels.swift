//
//  FontModels.swift
//  ximena
//
//  Created by Salvatore De Rosa on 02/04/2026.
//

import Foundation
import SwiftUI


public struct FontRow: View {
    let font: AppFont
    let isSelected: Bool
    let onSelect: () -> Void

    public var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(font.displayName)
                    .font(font.previewFont)
                    .foregroundStyle(.primary)

                Spacer()

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
        .contentShape(Rectangle())
    }
}
