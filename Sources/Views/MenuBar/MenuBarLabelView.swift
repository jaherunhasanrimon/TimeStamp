import SwiftUI

public struct MenuBarLabelView: View {
    @Environment(TimerManager.self) private var timerManager
    @Environment(PomodoroManager.self) private var pomodoroManager
    @AppStorage("menuBarDisplayFormat") private var displayFormat: String = "icon_and_duration"

    public init() {}

    public var body: some View {
        Group {
            if pomodoroManager.isRunning {
                // Active Pomodoro Session in Menu Bar
                HStack(spacing: AppSpacing.xs) {
                    Text("🍅")
                    if displayFormat != "icon_only" {
                        Text(pomodoroManager.formattedRemainingTime)
                            .font(Font.system(size: 13, design: .default).monospacedDigit())
                            .foregroundStyle(pomodoroManager.sessionType == .work ? AppColors.togglMagenta : AppColors.success)
                    }
                }
                .help("Pomodoro (\(pomodoroManager.sessionType.rawValue)): \(pomodoroManager.formattedRemainingTime) left")
            } else if timerManager.isRunning {
                HStack(spacing: AppSpacing.xs) {
                    if displayFormat != "duration_only" {
                        Image(systemName: "stopwatch")
                    }
                    if displayFormat != "icon_only" {
                        Text(timerManager.formattedDuration)
                            .font(Font.system(size: 13, design: .default).monospacedDigit())
                    }
                }
                .help(runningTooltip)
            } else if timerManager.isPaused {
                HStack(spacing: AppSpacing.xs) {
                    if displayFormat != "duration_only" {
                        Image(systemName: "pause.fill")
                            .foregroundStyle(Color.orange)
                    }
                    if displayFormat != "icon_only" {
                        Text(timerManager.formattedDuration)
                            .font(Font.system(size: 13, design: .default).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .help("TimeStamp — Paused")
            } else {
                Image(systemName: "stopwatch")
                    .help("TimeStamp — Click to track time")
            }
        }
    }

    private var runningTooltip: String {
        if let description = timerManager.activeEntry?.entryDescription, !description.isEmpty {
            return "TimeStamp — Tracking: \(description)"
        } else {
            return "TimeStamp — Tracking session"
        }
    }
}
