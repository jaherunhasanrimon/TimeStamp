import SwiftUI
import Charts

public struct DailyProjectActivity: Identifiable {
    public let id = UUID()
    public let dayName: String
    public let date: Date
    public let projectName: String
    public let projectColor: Color
    public let durationHours: Double
}

public struct WeeklyActivityChartView: View {
    @Environment(PersistenceStore.self) private var store
    @AppStorage("dailyTargetHours") private var targetHours: Double = 8.0

    public init() {}

    private var weeklyData: (items: [DailyProjectActivity], totalDuration: TimeInterval) {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday start

        let now = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        guard let weekStart = calendar.date(from: components) else {
            return ([], 0)
        }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        var activities: [DailyProjectActivity] = []
        var totalSec: TimeInterval = 0

        // Iterate Monday (0) through Sunday (6)
        for dayOffset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: dayDate) else {
                continue
            }

            let dayName = dayFormatter.string(from: dayDate)

            let dayEntries = store.timeEntries.filter {
                $0.startDate >= dayDate && $0.startDate < nextDay
            }

            // Group by projectId
            let grouped = Dictionary(grouping: dayEntries) { $0.projectId }

            if grouped.isEmpty {
                // Add a placeholder 0h item so all 7 days render on X-axis
                activities.append(
                    DailyProjectActivity(
                        dayName: dayName,
                        date: dayDate,
                        projectName: "None",
                        projectColor: .clear,
                        durationHours: 0
                    )
                )
            } else {
                for (projId, entries) in grouped {
                    let duration = entries.reduce(0.0) { $0 + $1.effectiveDuration }
                    totalSec += duration

                    let project = projId.flatMap { store.project(for: $0) }
                    let projName = project?.name ?? "No Project"
                    let color = project.map { Color(hex: $0.colorHex) } ?? Color.secondary.opacity(0.4)

                    activities.append(
                        DailyProjectActivity(
                            dayName: dayName,
                            date: dayDate,
                            projectName: projName,
                            projectColor: color,
                            durationHours: duration / 3600.0
                        )
                    )
                }
            }
        }

        return (activities, totalSec)
    }

    public var body: some View {
        let data = weeklyData

        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Activity")
                        .font(AppTypography.heading)
                    Text("Mon – Sun • Total: \(DateHelper.formatHumanDuration(data.totalDuration))")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: AppSpacing.xs) {
                    Circle()
                        .fill(AppColors.brandAccent)
                        .frame(width: 8, height: 8)
                    Text("Target: \(Int(targetHours))h/day")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Swift Charts Stacked Bar Chart
            Chart {
                ForEach(data.items) { item in
                    BarMark(
                        x: .value("Day", item.dayName),
                        y: .value("Hours", item.durationHours)
                    )
                    .foregroundStyle(item.projectColor)
                }

                RuleMark(y: .value("Target", targetHours))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Target (\(Int(targetHours))h)")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(AppTypography.caption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisValueLabel()
                        .font(AppTypography.label)
                }
            }
            .frame(height: 200)
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
