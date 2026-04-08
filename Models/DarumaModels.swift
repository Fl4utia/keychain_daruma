//
//  DarumaModels.swift
//  ximena
//
//  Created by Salvatore De Rosa on 03/04/2026.
//

import Foundation
import SwiftData
import CloudKit

// MARK: - Daruma Entry

struct DarumaEntry: Identifiable {
    var id = UUID()
    var title: String
    var date: Date
    var recordingURL: URL?
    var darumaType: DarumaType = .basic
}

// MARK: - Daruma Type

enum DarumaType: String, CaseIterable, Identifiable {
    case basic       = "base_basic_shaded"
    case bilouPink   = "bilou_pink"
    case deerBoy     = "deer_boy_girl_them"
    case madalunians = "madalunians"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .basic:       return "Classic"
        case .bilouPink:   return "Bilou"
        case .deerBoy:     return "Deer"
        case .madalunians: return "Special"
        }
    }

    /// Matches the file name loaded by Entity.load(named:) from the bundle.
    var modelFileName: String { rawValue }
}
