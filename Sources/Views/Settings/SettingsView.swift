import SwiftUI

public struct SettingsView: View {
    public init() {}

    public var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Settings")
                        .font(AppTypography.heading)
                    Text("Customize appearance, shortcuts, timer behavior, and local data")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, AppSpacing.xs)

                // 1. Appearance / Theme Card
                ThemePickerView()

                // 2. Global Shortcuts Card
                ShortcutRecorderView()

                // 3. Timer & Menu Bar Preferences Card
                TimerPreferencesSectionView()

                // 4. Data Management Utilities Card
                DataManagementSectionView()
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(AppSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(AppColors.background)
    }
}
