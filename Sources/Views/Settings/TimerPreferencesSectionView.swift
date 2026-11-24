import SwiftUI

public struct TimerPreferencesSectionView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(PomodoroManager.self) private var pomodoroManager
    @Environment(NotificationManager.self) private var notificationManager

    @AppStorage("defaultProjectId") private var defaultProjectIdString: String = ""
    @AppStorage("menuBarDisplayFormat") private var menuBarDisplayFormat: String = "icon_and_duration"
    @AppStorage("playTimerSounds") private var playTimerSounds: Bool = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Timer & Pomodoro")
                    .font(AppTypography.heading)
                Text("Configure default tracking behavior, Pomodoro durations, and notifications.")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: AppSpacing.md) {
                // Default Project Selection
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Default Project")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                        Text("Automatically assign this project to newly started timers.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $defaultProjectIdString) {
                        Text("None (Select on start)").tag("")
                        ForEach(store.projects) { project in
                            Text(project.name).tag(project.id.uuidString)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }

                Divider()

                // Menu Bar Format
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Menu Bar Display")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                        Text("Choose what information appears in your macOS menu bar.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $menuBarDisplayFormat) {
                        Text("Icon & Duration").tag("icon_and_duration")
                        Text("Duration Only").tag("duration_only")
                        Text("Icon Only").tag("icon_only")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                }

                Divider()

                // Pomodoro Focus Duration
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Pomodoro Focus Duration")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                        Text("Length of productive work interval.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Picker("", selection: Binding(
                        get: { Int(pomodoroManager.workDuration / 60) },
                        set: { pomodoroManager.workDuration = TimeInterval($0 * 60) }
                    )) {
                        Text("15 min").tag(15)
                        Text("20 min").tag(20)
                        Text("25 min (Standard)").tag(25)
                        Text("30 min").tag(30)
                        Text("45 min").tag(45)
                        Text("50 min").tag(50)
                    }
                    .frame(width: 160)
                }

                Divider()

                // Short Break Duration
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Short Break Duration")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                        Text("Quick pause between focus sessions.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Picker("", selection: Binding(
                        get: { Int(pomodoroManager.shortBreakDuration / 60) },
                        set: { pomodoroManager.shortBreakDuration = TimeInterval($0 * 60) }
                    )) {
                        Text("3 min").tag(3)
                        Text("5 min (Standard)").tag(5)
                        Text("10 min").tag(10)
                    }
                    .frame(width: 160)
                }

                Divider()

                // Long Break Duration
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Long Break Duration")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                        Text("Extended recovery break after completed interval cycle.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Picker("", selection: Binding(
                        get: { Int(pomodoroManager.longBreakDuration / 60) },
                        set: { pomodoroManager.longBreakDuration = TimeInterval($0 * 60) }
                    )) {
                        Text("10 min").tag(10)
                        Text("15 min (Standard)").tag(15)
                        Text("20 min").tag(20)
                        Text("30 min").tag(30)
                    }
                    .frame(width: 160)
                }

                Divider()

                // Desktop Notifications Permission
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("macOS Desktop Notifications")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                        Text("Receive banner alerts when Pomodoro focus and break intervals end.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !notificationManager.isAuthorized {
                        Button("Enable in macOS") {
                            notificationManager.requestAuthorization()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.togglMagenta)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.success)
                            Text("Enabled")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.success)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                    .stroke(AppColors.border, lineWidth: 0.5)
            )
        }
    }
}
