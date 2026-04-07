//
//  DarumaModels.swift
//  ximena
//
//  Created by Salvatore De Rosa on 03/04/2026.
//

import Foundation
import SwiftData
import CloudKit

enum DarumaType: String, CaseIterable, Identifiable {
    case basic = "base_basic_shaded"
    // future: case samurai = "daruma_samurai"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .basic: return "Classic"
        }
    }

    /// Name of the image asset used as card preview.
    /// Replace with your actual asset name when available.
    var previewImageName: String {
        switch self {
        case .basic: return "daruma_preview_basic"
        }
    }

    /// Matches the .reality / .usdz file name loaded in KeychainViewModel.
    var modelFileName: String { rawValue }
}
