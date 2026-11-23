import SwiftUI

public enum AppColors {
    // MARK: - Semantic Background & Card Colors (60% Dominant)
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let cardBackground = Color(nsColor: .controlBackgroundColor)
    public static let secondaryCardBackground = Color(nsColor: .underPageBackgroundColor)

    // MARK: - Borders & Dividers (30% Structural)
    public static let border = Color(nsColor: .separatorColor)
    public static let subtleBorder = Color.primary.opacity(0.08)

    // MARK: - Accent & Brand Colors (10% Focus)
    // Toggl Track Inspired Indigo: #5C3BFE in light mode, #7B61FF in dark mode
    public static let accent = Color("AccentColor", bundle: nil)
    public static let brandIndigoLight = Color(hex: "#5C3BFE")
    public static let brandIndigoDark = Color(hex: "#7B61FF")

    // Dynamic brand accent resolving light/dark
    public static var brandAccent: Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.482, green: 0.380, blue: 1.0, alpha: 1.0) // #7B61FF
                : NSColor(red: 0.361, green: 0.231, blue: 0.996, alpha: 1.0) // #5C3BFE
        }))
        #else
        return brandIndigoLight
        #endif
    }

    // MARK: - Status & Utility Colors
    public static let destructive = Color.red
    public static let success = Color.green
    public static let warning = Color.orange

    // MARK: - Curated Project Color Swatches
    public static let projectColors: [String] = [
        "#5C3BFE", // Indigo (Default)
        "#0A84FF", // Blue
        "#30D158", // Green
        "#FF9F0A", // Orange
        "#FF375F", // Pink
        "#BF5AF2", // Purple
        "#64D2FF", // Teal
        "#FFD60A"  // Yellow
    ]
}

// MARK: - Color Hex Initializer
extension Color {
    public init(hex: String) {
        let hexCleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexCleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexCleaned.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 92, 59, 254) // Fallback to #5C3BFE
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
