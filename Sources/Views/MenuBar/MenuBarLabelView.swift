import SwiftUI

public struct MenuBarLabelView: View {
    @Environment(TimerManager.self) private var timerManager

    public init() {}

    public var body: some View {
        Group {
            if timerManager.isRunning {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "stopwatch")
                    Text(timerManager.formattedDuration)
                        .font(Font.system(size: 13, design: .default).monospacedDigit())
                }
                .help(runningTooltip)
            } else if timerManager.isPaused {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "pause.fill")
                        .foregroundStyle(Color.orange)
                    Text(timerManager.formattedDuration)
                        .font(Font.system(size: 13, design: .default).monospacedDigit())
                        .foregroundStyle(.secondary)
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
