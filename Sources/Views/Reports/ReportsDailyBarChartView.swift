import SwiftUI
import Charts

public struct DailyProjectSlice: Identifiable {
    public let id: String
    public let dayDate: Date
    public let dayLabel: String
    public let projectName: String
    public let colorHex: String
    public let hours: Double
}

public struct ReportsDailyBarChartView: View {
    public let entries: [TimeEntry]
    public let projects: [Project]
    public let startDate: Date
    public let endDate: Date

    public init(entries: [TimeEntry], projects: [Project], startDate: Date, endDate: Date) {
        self.entries = entries
        self.projects = projects
        self.startDate = startDate
        self.endDate = endDate
    }

    private var slices: [DailyProjectSlice] {
        let calendar = Calendar.current
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })

        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        let dayDiff = max(0, calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0)
        // Limit dense ranges to 31 individual day bars, otherwise aggregate weekly
        let stepDays = min(31, dayDiff + 1)

        var days: [Date] = []
        for offset in 0..<stepDays {
            if let d = calendar.date(byAdding: .day, value: offset, to: startDay) {
                days.append(d)
            }
        }

        let df = DateFormatter()
        df.dateFormat = stepDays <= 7 ? "EEE d" : "M/d"

        var grouped: [String: (day: Date, label: String, projName: String, hex: String, seconds: TimeInterval)] = [:]
        for day in days {
            let dayLabel = df.string(from: day)
            let dayEntries = entries.filter { calendar.isDate($0.startDate, inSameDayAs: day) }
            for entry in dayEntries {
                let proj = entry.projectId.flatMap { projectMap[$0] }
                let pName = proj?.name ?? "No Project"
                let pHex = proj?.colorHex ?? "#8E8E93"
                let key = "\(day.timeIntervalSince1970)|\(pName)"
                if let existing = grouped[key] {
                    grouped[key] = (day, dayLabel, pName, pHex, existing.seconds + entry.effectiveDuration)
                } else {
                    grouped[key] = (day, dayLabel, pName, pHex, entry.effectiveDuration)
                }
            }
        }

        return grouped.map { key, val in
            DailyProjectSlice(
                id: key,
                dayDate: val.day,
                dayLabel: val.label,
                projectName: val.projName,
                colorHex: val.hex,
                hours: val.seconds / 3600.0
            )
        }
        .sorted { $0.dayDate < $1.dayDate }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("DURATION BY DAY & PROJECT")
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
                Spacer()
            }

            if slices.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Text("No entries recorded in this date range")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                Chart(slices) { slice in
                    BarMark(
                        x: .value("Day", slice.dayLabel),
                        y: .value("Hours", slice.hours)
                    )
                    .foregroundStyle(Color(hex: slice.colorHex))
                    .cornerRadius(3)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hrs = value.as(Double.self) {
                                Text(String(format: "%.1fh", hrs))
                                    .font(.system(size: 10))
                            }
                        }
                    }
                }
                .frame(height: 190)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                .stroke(AppColors.border, lineWidth: 0.5)
        )
    }
}
