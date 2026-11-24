import SwiftUI

/// Authentic Toggl Track-style Pomodoro Companion Popover.
/// Displays active phase, large countdown digits, interval indicators,
/// and Start / Pause / Resume / Skip / Reset controls.
public struct PomodoroPopoverView: View {
    @Environment(PomodoroManager.self) private var pomodoroManager
    @Environment(TimerManager.self) private var timerManager

    public let onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Header: Title & Cycle indicator (e.g. 🍅 2/4)
            HStack {
                HStack(spacing: 6) {
                    Text("🍅")
                        .font(.system(size: 16))
                    Text("Pomodoro")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.primary)
                }

                Spacer()

                // Completed interval badges
                HStack(spacing: 4) {
                    ForEach(0..<pomodoroManager.targetIntervalCount, id: \.self) { index in
                        Circle()
                            .fill(index < (pomodoroManager.completedWorkSessions % pomodoroManager.targetIntervalCount)
                                  ? AppColors.togglMagenta
                                  : AppColors.border)
                            .frame(width: 8, height: 8)
                    }

                    Text("\(pomodoroManager.completedWorkSessions % pomodoroManager.targetIntervalCount)/\(pomodoroManager.targetIntervalCount)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }

            Divider()
                .overlay(AppColors.border)

            // Center Countdown & Phase Ring
            VStack(spacing: 6) {
                Text(pomodoroManager.sessionType.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(pomodoroManager.sessionType == .work ? AppColors.togglMagenta : AppColors.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        (pomodoroManager.sessionType == .work ? AppColors.togglMagenta : AppColors.success)
                            .opacity(0.12)
                    )
                    .clipShape(Capsule())

                ZStack {
                    // Circular progress background
                    Circle()
                        .stroke(AppColors.insetBackground, lineWidth: 8)
                        .frame(width: 140, height: 140)

                    // Progress ring
                    Circle()
                        .trim(from: 0.0, to: CGFloat(pomodoroManager.progressPercentage))
                        .stroke(
                            pomodoroManager.sessionType == .work ? AppColors.togglMagenta : AppColors.success,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 140, height: 140)
                        .animation(.linear(duration: 0.5), value: pomodoroManager.progressPercentage)

                    VStack(spacing: 2) {
                        Text(pomodoroManager.formattedRemainingTime)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.primary)

                        if pomodoroManager.isPaused {
                            Text("PAUSED")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                        } else if pomodoroManager.isRunning {
                            Text(pomodoroManager.sessionType == .work ? "Tracking" : "Resting")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Ready")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()
                .overlay(AppColors.border)

            // Primary Control Buttons (Start / Pause / Skip / Reset)
            HStack(spacing: 12) {
                if !pomodoroManager.isRunning {
                    Button(action: {
                        pomodoroManager.start()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text(pomodoroManager.sessionType == .work ? "Start Focus" : "Start Break")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(pomodoroManager.sessionType == .work ? AppColors.togglMagenta : AppColors.success)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                } else {
                    // Pause / Resume Button
                    Button(action: {
                        if pomodoroManager.isPaused {
                            pomodoroManager.resume()
                        } else {
                            pomodoroManager.pause()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: pomodoroManager.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(pomodoroManager.isPaused ? "Resume" : "Pause")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(AppColors.secondaryCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    // Skip Button
                    Button(action: {
                        pomodoroManager.skip()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("Skip")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppColors.secondaryCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .help("Skip to next session")

                    // Reset Button
                    Button(action: {
                        pomodoroManager.reset()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(AppColors.secondaryCardBackground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Reset countdown")
                }
            }
        }
        .padding(16)
        .frame(width: 250)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
