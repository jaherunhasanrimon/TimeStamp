import SwiftUI

public enum AppColors {
    // MARK: - Semantic Background & Card Colors (Toggl Track Inspired)
    // Dark Plum #14101A in dark mode, Warm Cream #FDFBFA in light mode
    public static var background: Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.078, green: 0.063, blue: 0.102, alpha: 1.0) // #14101A
                : NSColor(red: 0.992, green: 0.984, blue: 0.980, alpha: 1.0) // #FDFBFA
        }))
        #else
        return Color(hex: "#14101A")
        #endif
    }

    // Card / Elevated Surface: #201A2C in dark mode, #FFFFFF in light mode
    public static var cardBackground: Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.125, green: 0.102, blue: 0.173, alpha: 1.0) // #201A2C
                : NSColor.white
        }))
        #else
        return Color(hex: "#201A2C")
        #endif
    }

    // Secondary Card / Popover / Hover: #2A223A in dark mode, #F4F0ED in light mode
    public static var secondaryCardBackground: Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.165, green: 0.133, blue: 0.227, alpha: 1.0) // #2A223A
                : NSColor(red: 0.957, green: 0.941, blue: 0.929, alpha: 1.0) // #F4F0ED
        }))
        #else
        return Color(hex: "#2A223A")
        #endif
    }

    public static var popoverBackground: Color {
        secondaryCardBackground
    }

    // Capsule segmented track & active thumb matching Toggl Track macOS
    public static var capsuleTrack: Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.110, green: 0.086, blue: 0.149, alpha: 1.0) // #1C1626
                : NSColor(red: 0.937, green: 0.922, blue: 0.910, alpha: 1.0) // #EFEBE8
        }))
        #else
        return Color(hex: "#1C1626")
        #endif
    }

    public static var capsuleActiveThumb: Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.180, green: 0.145, blue: 0.231, alpha: 1.0) // #2E253B
                : NSColor.white
        }))
        #else
        return Color(hex: "#2E253B")
        #endif
    }

    // Inset Background (Inputs, Segmented Controls): #100D15 in dark, #ECE8E4 in light
    public static var insetBackground: Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.063, green: 0.051, blue: 0.082, alpha: 1.0) // #100D15
                : NSColor(red: 0.925, green: 0.910, blue: 0.894, alpha: 1.0) // #ECE8E4
        }))
        #else
        return Color(hex: "#100D15")
        #endif
    }

    // MARK: - Borders & Dividers
    // #362B4A in dark mode, #EDE8E5 in light mode
    public static var border: Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.212, green: 0.169, blue: 0.290, alpha: 1.0) // #362B4A
                : NSColor(red: 0.929, green: 0.910, blue: 0.898, alpha: 1.0) // #EDE8E5
        }))
        #else
        return Color(hex: "#362B4A")
        #endif
    }

    public static let subtleBorder = Color.primary.opacity(0.08)
    public static let focusBorder = Color(hex: "#36B37E") // Toggl emerald green input focus

    // MARK: - Accent & Brand Colors (Toggl Track Magenta Signature)
    public static let togglMagenta = Color(hex: "#E54583")
    public static let togglPink = Color(hex: "#E0407B")
    public static let brandIndigoLight = Color(hex: "#E54583")
    public static let brandIndigoDark = Color(hex: "#E54583")

    // Dynamic brand accent resolving to Toggl Magenta #E54583
    public static var brandAccent: Color {
        return togglMagenta
    }

    // MARK: - Status & Utility Colors
    public static let destructive = Color(hex: "#FF453A")
    public static let success = Color(hex: "#30D158")
    public static let warning = Color(hex: "#FF9F0A")
    public static let billable = Color(hex: "#36B37E")
    public static let goalGold = Color(hex: "#D4973B")

    // MARK: - Curated Project Color Swatches (Toggl Track Palette)
    public static let projectColors: [String] = [
        "#E54583", // Magenta
        "#BF5AF2", // Purple
        "#5C3BFE", // Indigo
        "#0A84FF", // Blue
        "#30D158", // Green
        "#FF9F0A", // Orange
        "#FF453A", // Red
        "#64D2FF", // Teal
        "#FFD60A", // Yellow
        "#A2845E"  // Brown
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
            (a, r, g, b) = (255, 229, 69, 131) // Fallback to #E54583
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    public func toHex() -> String {
        #if os(macOS)
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            return "#E54583"
        }
        let r = Int(round(max(0, min(1, rgbColor.redComponent)) * 255))
        let g = Int(round(max(0, min(1, rgbColor.greenComponent)) * 255))
        let b = Int(round(max(0, min(1, rgbColor.blueComponent)) * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        return "#E54583"
        #endif
    }
}
