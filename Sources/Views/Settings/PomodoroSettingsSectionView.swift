import SwiftUI

public struct PomodoroSettingsSectionView: View {
    @Environment(PomodoroManager.self) private var pomodoro

    public init() {}

    public var body: some View {
        @Bindable var bindPomo = pomodoro

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Label("Pomodoro Timer Durations", systemImage: "timer")
                        .font(AppTypography.subheading)

                    Stepper("Focus duration: \(Int(pomodoro.workDuration / 60)) minutes", value: Binding(
                        get: { Int(pomodoro.workDuration / 60) },
                        set: { pomodoro.workDuration = TimeInterval(max(1, min(120, $0)) * 60) }
                    ), in: 1...120)

                    Stepper("Short break: \(Int(pomodoro.shortBreakDuration / 60)) minutes", value: Binding(
                        get: { Int(pomodoro.shortBreakDuration / 60) },
                        set: { pomodoro.shortBreakDuration = TimeInterval(max(1, min(60, $0)) * 60) }
                    ), in: 1...60)

                    Stepper("Long break: \(Int(pomodoro.longBreakDuration / 60)) minutes", value: Binding(
                        get: { Int(pomodoro.longBreakDuration / 60) },
                        set: { pomodoro.longBreakDuration = TimeInterval(max(1, min(60, $0)) * 60) }
                    ), in: 1...60)

                    Stepper("Long break after every \(pomodoro.targetIntervalCount) focus sessions",
                            value: $bindPomo.targetIntervalCount,
                            in: 1...10)
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Label("Behavior & Alerts", systemImage: "bell")
                        .font(AppTypography.subheading)

                    Toggle("Automatically start breaks when focus completes", isOn: $bindPomo.autoStartBreaks)
                    Toggle("Automatically start next focus session when break ends", isOn: $bindPomo.autoStartFocus)
                    Toggle("Count up instead of counting down inside dial", isOn: $bindPomo.countUpMode)
                    Toggle("Send macOS notification on session completion", isOn: $bindPomo.notificationsEnabled)
                    Toggle("Play alert sound on session completion", isOn: $bindPomo.soundEnabled)
                        .disabled(!pomodoro.notificationsEnabled)
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
            }
            .padding(AppSpacing.lg)
        }
    }
}
