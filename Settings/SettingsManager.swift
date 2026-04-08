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

    /// Body-sized font applied throughout the app UI (17 pt)
    var bodyFont: Font {
        switch self {
        case .system:       .system(.body, design: .default)
        case .atkinson:     .custom("AtkinsonHyperlegible-Regular", size: 17, relativeTo: .body)
        case .lexend:       .custom("Lexend-Regular",               size: 17, relativeTo: .body)
        case .openDyslexic: .custom("OpenDyslexic-Regular",         size: 17, relativeTo: .body)
        }
    }

    /// Large title (34 pt, regular) — prominent display headings
    var largeTitleFont: Font {
        switch self {
        case .system:       .system(.largeTitle)
        case .atkinson:     .custom("AtkinsonHyperlegible-Regular", size: 34, relativeTo: .largeTitle)
        case .lexend:       .custom("Lexend-Regular",               size: 34, relativeTo: .largeTitle)
        case .openDyslexic: .custom("OpenDyslexic-Regular",         size: 34, relativeTo: .largeTitle)
        }
    }

    /// Title 3 (20 pt, regular) — secondary display text and page descriptions
    var title3Font: Font {
        switch self {
        case .system:       .system(.title3)
        case .atkinson:     .custom("AtkinsonHyperlegible-Regular", size: 20, relativeTo: .title3)
        case .lexend:       .custom("Lexend-Regular",               size: 20, relativeTo: .title3)
        case .openDyslexic: .custom("OpenDyslexic-Regular",         size: 20, relativeTo: .title3)
        }
    }

    /// Headline (17 pt, semibold) — list row labels, buttons, and emphasis text
    var headlineFont: Font {
        switch self {
        case .system:       .system(.headline)
        case .atkinson:     .custom("AtkinsonHyperlegible-Bold",    size: 17, relativeTo: .headline)
        case .lexend:       .custom("Lexend-SemiBold",              size: 17, relativeTo: .headline)
        case .openDyslexic: .custom("OpenDyslexic-Bold",            size: 17, relativeTo: .headline)
        }
    }

    /// Subheadline (15 pt, regular) — secondary labels and supporting text
    var subheadlineFont: Font {
        switch self {
        case .system:       .system(.subheadline)
        case .atkinson:     .custom("AtkinsonHyperlegible-Regular", size: 15, relativeTo: .subheadline)
        case .lexend:       .custom("Lexend-Regular",               size: 15, relativeTo: .subheadline)
        case .openDyslexic: .custom("OpenDyslexic-Regular",         size: 15, relativeTo: .subheadline)
        }
    }

    /// Footnote (13 pt, regular) — section headers and supplementary labels
    var footnoteFont: Font {
        switch self {
        case .system:       .system(.footnote)
        case .atkinson:     .custom("AtkinsonHyperlegible-Regular", size: 13, relativeTo: .footnote)
        case .lexend:       .custom("Lexend-Regular",               size: 13, relativeTo: .footnote)
        case .openDyslexic: .custom("OpenDyslexic-Regular",         size: 13, relativeTo: .footnote)
        }
    }

    /// Caption (12 pt, regular) — image captions and the smallest supporting labels
    var captionFont: Font {
        switch self {
        case .system:       .system(.caption)
        case .atkinson:     .custom("AtkinsonHyperlegible-Regular", size: 12, relativeTo: .caption)
        case .lexend:       .custom("Lexend-Regular",               size: 12, relativeTo: .caption)
        case .openDyslexic: .custom("OpenDyslexic-Regular",         size: 12, relativeTo: .caption)
        }
    }
}

// MARK: - App Icon

struct AppIconOption: Identifiable {
    let id: String
    let displayName: String
    /// Passed to UIApplication.setAlternateIconName — nil resets to primary icon
    let iconName: String?
    /// Name of the Image Set in the asset catalog used for in-app preview
    let previewImageName: String
}

extension AppIconOption {
    /// Each iconName must match an appiconset declared in
    /// Build Settings → Alternate App Icons (ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES).
    static let all: [AppIconOption] = [
        .init(id: "default", displayName: "Default", iconName: nil,           previewImageName: "icon-preview-default"),
        .init(id: "daru",    displayName: "Neon",    iconName: "AppIcon-Neon", previewImageName: "icon-preview-neon"),
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

    var leftHandedMode: Bool = UserDefaults.standard.object(forKey: "leftHandedMode") as? Bool ?? false {
        didSet { UserDefaults.standard.set(leftHandedMode, forKey: "leftHandedMode") }
    }

    var currentFont: AppFont {
        AppFont(rawValue: selectedFont) ?? .system
    }
}
