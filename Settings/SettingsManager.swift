//
//  SettingsManager.swift
//  ximena
//

import SwiftUI
import Observation

// MARK: - Font

enum AppFont: String, CaseIterable, Identifiable {
    case system     = "system"
    case rounded    = "rounded"
    case serif      = "serif"
    case monospaced = "monospaced"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:     "System"
        case .rounded:    "Rounded"
        case .serif:      "Serif"
        case .monospaced: "Mono"
        }
    }

    /// Large preview shown inside the font chip
    var previewFont: Font {
        switch self {
        case .system:     .system(size: 20, weight: .semibold, design: .default)
        case .rounded:    .system(size: 20, weight: .semibold, design: .rounded)
        case .serif:      .system(size: 20, weight: .semibold, design: .serif)
        case .monospaced: .system(size: 20, weight: .semibold, design: .monospaced)
        }
    }

    /// Body-sized font for general UI use
    var bodyFont: Font {
        switch self {
        case .system:     .system(.body, design: .default)
        case .rounded:    .system(.body, design: .rounded)
        case .serif:      .system(.body, design: .serif)
        case .monospaced: .system(.body, design: .monospaced)
        }
    }
}

// MARK: - App Icon

struct AppIconOption: Identifiable {
    let id: String
    let displayName: String
    /// Passed to UIApplication.setAlternateIconName — nil resets to primary
    let iconName: String?
    let accentColor: Color
}

extension AppIconOption {
    /// Register alternate icons in Xcode: target → Build Settings → "Alternate App Icons".
    /// Each iconName must match the icon set name in your asset catalog.
    static let all: [AppIconOption] = [
        .init(id: "default", displayName: "Default", iconName: nil,              accentColor: .red),
        .init(id: "dark",    displayName: "Dark",    iconName: "AppIcon-Dark",    accentColor: Color(white: 0.15)),
        .init(id: "neon",    displayName: "Neon",    iconName: "AppIcon-Neon",    accentColor: .green),
        .init(id: "minimal", displayName: "Minimal", iconName: "AppIcon-Minimal", accentColor: Color(white: 0.9)),
    ]
}

// MARK: - Settings Manager

@Observable
final class SettingsManager {
    // Using UserDefaults directly — @AppStorage is a DynamicProperty designed for Views only.
    // The `as? T ?? default` pattern correctly handles missing keys (vs. .bool() returning false).

    var selectedFont: String = UserDefaults.standard.string(forKey: "selectedFont") ?? AppFont.system.rawValue {
        didSet { UserDefaults.standard.set(selectedFont, forKey: "selectedFont") }
    }

    var selectedAppIcon: String = UserDefaults.standard.string(forKey: "selectedAppIcon") ?? "default" {
        didSet { UserDefaults.standard.set(selectedAppIcon, forKey: "selectedAppIcon") }
    }

    var musicEnabled: Bool = UserDefaults.standard.object(forKey: "musicEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(musicEnabled, forKey: "musicEnabled") }
    }

    var musicVolume: Double = UserDefaults.standard.object(forKey: "musicVolume") as? Double ?? 0.7 {
        didSet { UserDefaults.standard.set(musicVolume, forKey: "musicVolume") }
    }

    var sfxEnabled: Bool = UserDefaults.standard.object(forKey: "sfxEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(sfxEnabled, forKey: "sfxEnabled") }
    }

    var hapticsEnabled: Bool = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled") }
    }

    var currentFont: AppFont {
        AppFont(rawValue: selectedFont) ?? .system
    }
}
