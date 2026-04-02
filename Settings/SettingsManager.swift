//
//  SettingsManager.swift
//  ximena
//

import SwiftUI
import Observation

// MARK: - Font

enum AppFont: String, CaseIterable, Identifiable {
    case system       = "system"
    case atkinson     = "atkinson"
    case lexend       = "lexend"
    case openDyslexic = "openDyslexic"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:       "Default"
        case .atkinson:     "Atkinson"
        case .lexend:       "Lexend"
        case .openDyslexic: "OpenDyslexic"
        }
    }

    /// Large preview shown at the top of the font picker (size 26, regular weight)
    var largePresentationFont: Font {
        switch self {
        case .system:       .system(size: 26, weight: .regular, design: .default)
        case .atkinson:     .custom("AtkinsonHyperlegible-Regular", size: 26)
        case .lexend:       .custom("Lexend-Regular", size: 26)
        case .openDyslexic: .custom("OpenDyslexic-Regular", size: 26)
        }
    }

    /// Small preview shown inside each row of the font picker (size 17, regular weight)
    var previewFont: Font {
        switch self {
        case .system:       .system(size: 17, weight: .regular, design: .default)
        case .atkinson:     .custom("AtkinsonHyperlegible-Regular", size: 17)
        case .lexend:       .custom("Lexend-Regular", size: 17)
        case .openDyslexic: .custom("OpenDyslexic-Regular", size: 17)
        }
    }

    /// Body-sized font applied throughout the app UI
    var bodyFont: Font {
        switch self {
        case .system:       .system(.body, design: .default)
        case .atkinson:     .custom("AtkinsonHyperlegible-Regular", size: 17, relativeTo: .body)
        case .lexend:       .custom("Lexend-Regular", size: 17, relativeTo: .body)
        case .openDyslexic: .custom("OpenDyslexic-Regular", size: 17, relativeTo: .body)
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
