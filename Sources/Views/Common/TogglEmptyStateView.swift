import SwiftUI

/// Toggl Track authentic empty state illustrations.
/// Variant 1: "Let's get tracking!" typing hands on laptop (Reference Image 1).
/// Variant 2: "No entries found" purple binoculars with soft pink clouds (Reference Images 3 & 4).
public struct TogglEmptyStateView: View {
    public enum Style {
        case letsGetTracking
        case binoculars(title: String, subtitle: String, buttonTitle: String? = nil, onAction: (() -> Void)? = nil)
    }

    public let style: Style

    public init(style: Style = .letsGetTracking) {
        self.style = style
    }

    public var body: some View {
        VStack(spacing: 16) {
            switch style {
            case .letsGetTracking:
                // Spotlight with laptop & typing hands graphic
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 110, height: 110)

                    VStack(spacing: -8) {
                        // Hands
                        HStack(spacing: 24) {
                            Text("👐")
                                .font(.system(size: 32))
                        }

                        // Laptop base
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#2C1E32"))
                            .frame(width: 80, height: 12)
                    }
                }
                .padding(.top, 10)

                VStack(spacing: 6) {
                    Text("Let's get tracking!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.primary)

                    Text("Get ready to track time and boost your productivity.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

            case .binoculars(let title, let subtitle, let buttonTitle, let onAction):
                // Purple Binoculars under Soft Pink Clouds
                VStack(spacing: 12) {
                    ZStack {
                        // Soft Pink Clouds
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

                        // Purple Binoculars
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
                            .padding(.horizontal, 24)
                    }

                    if let btn = buttonTitle, let action = onAction {
                        Button(action: action) {
                            Text(btn)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.primary)
                                .padding(.horizontal, 16)
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
}
