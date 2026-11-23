import SwiftUI

public struct DailyProgressCardView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager
    @AppStorage("dailyTargetHours") private var targetHours: Double = 8.0

    private let targetPresets: [Double] = [4.0, 6.0, 7.5, 8.0, 9.0, 10.0]

    public init() {}

    private var todayDuration: TimeInterval {
        let todayStart = DateHelper.startOfDay(for: Date())
        let completed = store.timeEntries
            .filter { $0.startDate >= todayStart && $0.endDate != nil }
            .reduce(0.0) { $0 + $1.effectiveDuration }

        let active: TimeInterval
        if let current = timerManager.activeEntry, current.startDate >= todayStart {
            active = timerManager.currentDuration
        } else {
            active = 0
        }
        return completed + active
    }

    private var targetSeconds: TimeInterval {
        max(360.0, targetHours * 3600.0) // At least 0.1h to prevent division by zero
    }

    private var progressRatio: Double {
        min(1.0, todayDuration / targetSeconds)
    }

    private var percentage: Int {
        Int(round((todayDuration / targetSeconds) * 100))
    }

    private var isGoalReached: Bool {
        todayDuration >= targetSeconds
    }

    private var overtimeSeconds: TimeInterval {
        max(0, todayDuration - targetSeconds)
    }

    private var remainingSeconds: TimeInterval {
        max(0, targetSeconds - todayDuration)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header: Title & Target Selector
            HStack {
                Label("Today's Progress", systemImage: "target")
                    .font(AppTypography.heading)

                Spacer()

                Menu {
                    ForEach(targetPresets, id: \.self) { preset in
                        Button(action: { targetHours = preset }) {
                            HStack {
                                Text("\(formatTargetLabel(preset))")
                                if abs(targetHours - preset) < 0.01 {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Text("Target: \(formatTargetLabel(targetHours))")
                            .font(AppTypography.label)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                }
                .menuStyle(.borderlessButton)
            }

            // Card Body: Ring and Metrics
            HStack(spacing: AppSpacing.lg) {
                // Circular Progress Ring (140px diameter, 12px stroke)
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: CGFloat(progressRatio))
                        .stroke(
                            isGoalReached ? AppColors.success : AppColors.brandAccent,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progressRatio)

                    VStack(spacing: 2) {
                        Text(DateHelper.formatHumanDuration(todayDuration))
                            .font(AppTypography.displayTicker)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text("\(percentage)%")
                            .font(AppTypography.subheading)
                            .foregroundStyle(.secondary)
                    }
                    .padding(AppSpacing.xs)
                }
                .frame(width: 140, height: 140)

                // Metrics & Target Status
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    if isGoalReached {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.success)
                            Text("Goal Reached!")
                                .font(AppTypography.subheading)
                                .foregroundStyle(AppColors.success)
                        }

                        if overtimeSeconds > 60 {
                            Text("+\(DateHelper.formatHumanDuration(overtimeSeconds)) over goal")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.success)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(AppColors.success.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Remaining")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                            Text(DateHelper.formatHumanDuration(remainingSeconds))
                                .font(AppTypography.subheading)
                                .foregroundStyle(.primary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Target")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                        Text("\(formatTargetLabel(targetHours)) (8h recommended)")
                            .font(AppTypography.label)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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

    private func formatTargetLabel(_ hours: Double) -> String {
        if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(hours))h"
        } else {
            return String(format: "%.1fh", hours)
        }
    }
}
