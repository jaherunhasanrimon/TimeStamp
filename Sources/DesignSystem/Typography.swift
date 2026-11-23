import SwiftUI

public enum AppTypography {
    // MARK: - Type Hierarchy
    public static let display = Font.system(size: 28, weight: .bold, design: .default)
    public static let heading = Font.system(size: 20, weight: .semibold, design: .default)
    public static let subheading = Font.system(size: 15, weight: .semibold, design: .default)
    public static let body = Font.system(size: 13, weight: .regular, design: .default)
    public static let label = Font.system(size: 12, weight: .medium, design: .default)
    public static let caption = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Monospaced Timer Ticker
    public static let ticker = Font.system(size: 14, weight: .semibold, design: .default).monospacedDigit()
    public static let displayTicker = Font.system(size: 28, weight: .bold, design: .default).monospacedDigit()
    public static let subTicker = Font.system(size: 13, weight: .medium, design: .default).monospacedDigit()
}
