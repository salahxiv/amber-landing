import SwiftUI

/// Visuelle Themes für das Break-Overlay
enum OverlayTheme: String, CaseIterable, Identifiable {
    case ocean
    case sunset
    case forest
    case night
    case minimal

    var id: String { rawValue }

    // MARK: - Anzeige

    var displayName: String {
        switch self {
        case .ocean: return String(localized: "theme.ocean")
        case .sunset: return String(localized: "theme.sunset")
        case .forest: return String(localized: "theme.forest")
        case .night: return String(localized: "theme.night")
        case .minimal: return String(localized: "theme.minimal")
        }
    }

    var icon: String {
        switch self {
        case .ocean: return "water.waves"
        case .sunset: return "sunset.fill"
        case .forest: return "leaf.fill"
        case .night: return "moon.stars.fill"
        case .minimal: return "circle"
        }
    }

    // MARK: - Farben

    var gradientColors: [Color] {
        switch self {
        case .ocean:
            return [
                Color(red: 0.02, green: 0.05, blue: 0.12),
                Color(red: 0.05, green: 0.1, blue: 0.2),
                Color(red: 0.02, green: 0.08, blue: 0.15)
            ]
        case .sunset:
            return [
                Color(red: 0.15, green: 0.05, blue: 0.1),
                Color(red: 0.2, green: 0.08, blue: 0.05),
                Color(red: 0.12, green: 0.04, blue: 0.08)
            ]
        case .forest:
            return [
                Color(red: 0.02, green: 0.1, blue: 0.05),
                Color(red: 0.05, green: 0.15, blue: 0.08),
                Color(red: 0.03, green: 0.08, blue: 0.04)
            ]
        case .night:
            return [
                Color(red: 0.03, green: 0.03, blue: 0.08),
                Color(red: 0.05, green: 0.04, blue: 0.12),
                Color(red: 0.02, green: 0.02, blue: 0.06)
            ]
        case .minimal:
            return [
                Color(red: 0.08, green: 0.08, blue: 0.08),
                Color(red: 0.1, green: 0.1, blue: 0.1),
                Color(red: 0.06, green: 0.06, blue: 0.06)
            ]
        }
    }

    var accentColor: Color {
        switch self {
        case .ocean: return .mint
        case .sunset: return Color(red: 1.0, green: 0.6, blue: 0.3)
        case .forest: return .green
        case .night: return Color(red: 0.6, green: 0.5, blue: 1.0)
        case .minimal: return .white
        }
    }

    var secondaryAccent: Color {
        switch self {
        case .ocean: return .cyan
        case .sunset: return Color(red: 1.0, green: 0.4, blue: 0.5)
        case .forest: return Color(red: 0.5, green: 0.85, blue: 0.4)
        case .night: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .minimal: return .gray
        }
    }

    var textColor: Color {
        .white
    }

    var subtitleColor: Color {
        .white.opacity(0.5)
    }

    var particleColor: Color {
        accentColor
    }

    var particleSecondaryColor: Color {
        secondaryAccent
    }

    /// Vorschau-Gradient für ThemeCard
    var previewGradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
