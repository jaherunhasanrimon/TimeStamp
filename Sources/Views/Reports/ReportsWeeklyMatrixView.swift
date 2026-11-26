import SwiftUI

public struct WeeklyMatrixRow: Identifiable {
    public let id: String
    public let projectName: String
    public let clientName: String?
    public let colorHex: String
    public let dailySeconds: [TimeInterval] // 7 elements: Mon..Sun
    public var rowTotal: TimeInterval { dailySeconds.reduce(0, +) }
}

public struct ReportsWeeklyMatrixView: View {
    public let entries: [TimeEntry]
    public let projects: [Project]
    public let clients: [Client]
    public let referenceDate: Date

    public init(entries: [TimeEntry], projects: [Project], clients: [Client], referenceDate: Date) {
        self.entries = entries
        self.projects = projects
        self.clients = clients
        self.referenceDate = referenceDate
    }

    private var weekDays: [Date] {
        let cal = DateHelper.isoCalendar
        let monday = DateHelper.startOfWeek(for: referenceDate, in: cal)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    private var rows: [WeeklyMatrixRow] {
        let cal = DateHelper.isoCalendar
        let days = weekDays
        guard days.count == 7 else { return [] }

        let projMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        let clientMap = Dictionary(uniqueKeysWithValues: clients.map { ($0.id, $0) })

        var buckets: [String: (name: String, client: String?, hex: String, daily: [TimeInterval])] = [:]

        for entry in entries {
            let proj = entry.projectId.flatMap { projMap[$0] }
            let client = proj?.clientId.flatMap { clientMap[$0]?.name }
            let key = proj?.id.uuidString ?? "no-project"
            let name = proj?.name ?? "No Project"
            let hex = proj?.colorHex ?? "#8E8E93"

            for (idx, day) in days.enumerated() where cal.isDate(entry.startDate, inSameDayAs: day) {
                var arr = buckets[key]?.daily ?? Array(repeating: 0.0, count: 7)
                arr[idx] += entry.effectiveDuration
                buckets[key] = (name, client, hex, arr)
            }
        }

        return buckets.map { key, val in
            WeeklyMatrixRow(
                id: key,
                projectName: val.name,
                clientName: val.client,
                colorHex: val.hex,
                dailySeconds: val.daily
            )
        }
        .sorted { $0.rowTotal > $1.rowTotal }
    }

    private var columnTotals: [TimeInterval] {
        (0..<7).map { idx in
            rows.reduce(0.0) { $0 + $1.dailySeconds[idx] }
        }
    }

    private var grandTotal: TimeInterval {
        columnTotals.reduce(0.0, +)
    }

    private func dayHeaderLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE d"
        return df.string(from: date)
    }

    private func cellFormatted(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "–" }
        let mins = Int(seconds / 60)
        let h = mins / 60
        let m = mins % 60
        return String(format: "%d:%02d", h, m)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("WEEKLY HOURS MATRIX (MON – SUN)")
                .font(AppTypography.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(0.8)

            if rows.isEmpty {
                TogglEmptyStateView(
                    style: .binoculars(
                        title: "No weekly entries recorded",
                        subtitle: "Track or add time entries during this week to populate the matrix."
                    )
                )
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 8) {
                        Text("PROJECT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(weekDays, id: \.self) { day in
                            Text(dayHeaderLabel(day).uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 56, alignment: .trailing)
                        }

                        Text("TOTAL")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 64, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)

                    Divider()

                    ForEach(rows) { row in
                        HStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: row.colorHex))
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(row.projectName)
                                        .font(AppTypography.body)
                                        .lineLimit(1)
                                    if let c = row.clientName {
                                        Text(c)
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(0..<7, id: \.self) { idx in
                                Text(cellFormatted(row.dailySeconds[idx]))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(row.dailySeconds[idx] > 0 ? Color.primary : Color.secondary.opacity(0.45))
                                    .frame(width: 56, alignment: .trailing)
                            }

                            Text(cellFormatted(row.rowTotal))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .frame(width: 64, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        Divider().opacity(0.5)
                    }

                    // Daily Totals Footer
                    HStack(spacing: 8) {
                        Text("Total")
                            .font(.system(size: 12, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(0..<7, id: \.self) { idx in
                            Text(cellFormatted(columnTotals[idx]))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .frame(width: 56, alignment: .trailing)
                        }

                        Text(cellFormatted(grandTotal))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColors.togglMagenta)
                            .frame(width: 64, alignment: .trailing)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    .background(AppColors.insetBackground)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
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
