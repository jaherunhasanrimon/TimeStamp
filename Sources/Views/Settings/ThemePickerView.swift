import SwiftUI

public struct ThemePickerView: View {
    @AppStorage("appTheme") private var appTheme: String = "system"

    public init() {}

    private let themes: [(id: String, label: String, icon: String)] = [
        ("system", "System", "circle.lefthalf.filled"),
        ("light", "Light", "sun.max.fill"),
        ("dark", "Dark", "moon.stars.fill")
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Appearance")
                    .font(AppTypography.heading)
                Text("Choose how TimeStamp looks on your Mac.")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: AppSpacing.md) {
                ForEach(themes, id: \.id) { theme in
                    let isSelected = appTheme == theme.id

                    Button(action: {
                        appTheme = theme.id
                    }) {
                        VStack(spacing: AppSpacing.sm) {
                            Image(systemName: theme.icon)
                                .font(.system(size: 24))
                                .foregroundStyle(isSelected ? AppColors.brandAccent : .secondary)

                            Text(theme.label)
                                .font(AppTypography.label)
                                .foregroundStyle(isSelected ? .primary : .secondary)
                        }
                        .frame(width: 110, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusSmall)
                                .fill(isSelected ? AppColors.brandAccent.opacity(0.12) : AppColors.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusSmall)
                                .stroke(isSelected ? AppColors.brandAccent : AppColors.border, lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                .stroke(AppColors.border, lineWidth: 0.5)
        )
    }
}
