import SwiftUI

public struct IdleAndRemindersSettingsView: View {
    @Environment(IdleDetectionManager.self) private var idleManager
    @Environment(ReminderManager.self) private var reminderManager

    private let weekdayItems: [(id: Int, short: String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun")
    ]

    public init() {}

    public var body: some View {
        @Bindable var bindIdle = idleManager
        @Bindable var bindReminder = reminderManager

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Idle Detection Card
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Label("Idle Detection (HID Activity)", systemImage: "moon.zzz")
                        .font(AppTypography.subheading)

                    Toggle("Detect keyboard/mouse inactivity while timer is running", isOn: $bindIdle.isEnabled)
                        .font(AppTypography.body)

                    Stepper("Trigger prompt after \(idleManager.idleThresholdMinutes) min idle",
                            value: $bindIdle.idleThresholdMinutes,
                            in: 1...120)
                    .font(AppTypography.body)
                    .disabled(!idleManager.isEnabled)

                    Text("Uses local macOS HID inactivity time cleanly without requiring Accessibility or Screen Recording access.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))

                // Workday Reminders Card
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Label("Workday Tracking Reminders", systemImage: "bell.badge")
                        .font(AppTypography.subheading)

                    Toggle("Send daily reminder notification", isOn: $bindReminder.isEnabled)
                        .font(AppTypography.body)

                    HStack(spacing: AppSpacing.md) {
                        Stepper("Hour: \(String(format: "%02d", reminderManager.reminderHour))",
                                value: $bindReminder.reminderHour,
                                in: 0...23)
                        Stepper("Min: \(String(format: "%02d", reminderManager.reminderMinute))",
                                value: $bindReminder.reminderMinute,
                                in: 0...59,
                                step: 5)
                    }
                    .font(AppTypography.body)
                    .disabled(!reminderManager.isEnabled)

                    HStack(spacing: 6) {
                        ForEach(weekdayItems, id: \.id) { day in
                            let selected = reminderManager.enabledWeekdays.contains(day.id)
                            Button {
                                if selected && reminderManager.enabledWeekdays.count > 1 {
                                    reminderManager.enabledWeekdays.remove(day.id)
                                } else {
                                    reminderManager.enabledWeekdays.insert(day.id)
                                }
                            } label: {
                                Text(day.short)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(selected ? .white : .primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(selected ? AppColors.togglMagenta : AppColors.insetBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .disabled(!reminderManager.isEnabled)

                    Toggle("Only notify when no timer is running", isOn: $bindReminder.onlyWhenTimerIdle)
                        .font(AppTypography.body)
                        .disabled(!reminderManager.isEnabled)
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
