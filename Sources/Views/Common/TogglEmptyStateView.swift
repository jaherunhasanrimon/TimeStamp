import SwiftUI

/// Authentic Toggl Track Empty State Illustrations:
/// 1. White circle spotlight with vector laptop, pink accent dot, & typing hands: "Let's get tracking!"
/// 2. Purple Binoculars under Soft Pink Clouds: "No entries found in the selected period" / "Nothing to see here..."
public struct TogglEmptyStateView: View {
    public enum Style {
        case letsGetTracking
        case binoculars(title: String, subtitle: String, buttonTitle: String? = nil, onAction: (() -> Void)? = nil)
    }

    public let style: Style

    public init(style: Style) {
        self.style = style
    }

    public var body: some View {
        VStack(spacing: 16) {
            switch style {
            case .letsGetTracking:
                // Clean-room SwiftUI vector illustration matching Toggl macOS welcome spotlight
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 112, height: 112)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)

                    VStack(spacing: 0) {
                        // Laptop lid with centered pink accent dot
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(hex: "#362545"))
                                .frame(width: 58, height: 42)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color(hex: "#6B577B"), lineWidth: 2)
                                )

                            Circle()
                                .fill(AppColors.togglMagenta)
                                .frame(width: 12, height: 12)
                        }
                        .offset(y: 4)

                        // Laptop keyboard deck + gold typing hands
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: "#261833"))
                                .frame(width: 82, height: 10)

                            HStack(spacing: 14) {
                                handShape(mirrored: false)
                                handShape(mirrored: true)
                            }
                            .offset(y: -8)
                        }
                    }
                }
                .padding(.top, 10)

                VStack(spacing: 6) {
                    Text("Let's get tracking!")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Color.primary)

                    Text("Get ready to track time and boost your productivity.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

            case .binoculars(let title, let subtitle, let buttonTitle, let onAction):
                // Purple Binoculars under Soft Pink Clouds
                VStack(spacing: 12) {
                    ZStack {
                        HStack(spacing: -10) {
                            Circle()
                                .fill(Color(hex: "#E8A0BF").opacity(0.85))
                                .frame(width: 44, height: 44)
                            Circle()
                                .fill(Color(hex: "#E8A0BF").opacity(0.95))
                                .frame(width: 58, height: 58)
                                .offset(y: -8)
                            Circle()
                                .fill(Color(hex: "#E8A0BF").opacity(0.85))
                                .frame(width: 40, height: 40)
                        }
                        .offset(y: -14)

                        HStack(spacing: 8) {
                            Circle()
                                .stroke(Color(hex: "#BF5AF2"), lineWidth: 9)
                                .frame(width: 46, height: 46)
                                .background(Circle().fill(AppColors.cardBackground))

                            Rectangle()
                                .fill(Color(hex: "#BF5AF2"))
                                .frame(width: 14, height: 6)

                            Circle()
                                .stroke(Color(hex: "#BF5AF2"), lineWidth: 9)
                                .frame(width: 46, height: 46)
                                .background(Circle().fill(AppColors.cardBackground))
                        }
                    }
                    .frame(height: 80)

                    VStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.primary)

                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                    }

                    if let btnTitle = buttonTitle, let action = onAction {
                        Button(action: action) {
                            Text(btnTitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(AppColors.secondaryCardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    @ViewBuilder
    private func handShape(mirrored: Bool) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color(hex: "#F2C66D"))
                    .frame(width: 4.5, height: idx == 1 || idx == 2 ? 12 : 9)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "#E6B655"))
        )
        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
    }
}
