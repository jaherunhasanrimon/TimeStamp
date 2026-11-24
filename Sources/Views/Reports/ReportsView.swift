import SwiftUI

public enum DateRangePreset: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case custom = "Custom Range"

    public var id: String { rawValue }
}

public enum ReportDimension: String, CaseIterable, Identifiable {
    case projects = "By Project"
    case clients = "By Client"
    case tags = "By Tag"

    public var id: String { rawValue }
}

public struct ReportsView: View {
    @Environment(PersistenceStore.self) private var store

    @State private var selectedRange: DateRangePreset = .thisWeek
    @State private var customStartDate: Date = Date()
    @State private var customEndDate: Date = Date()
    @State private var selectedDimension: ReportDimension = .projects

    public init() {}

    private var resolvedDateInterval: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch selectedRange {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)

        case .thisWeek:
            var cal = calendar
            cal.firstWeekday = 2 // Monday start
            let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            let start = cal.date(from: components) ?? cal.startOfDay(for: now)
            let end = cal.date(byAdding: .day, value: 7, to: start)!
            return (start, end)

        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: components) ?? calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)

        case .custom:
            let start = calendar.startOfDay(for: customStartDate)
            let rawEnd = calendar.startOfDay(for: customEndDate)
            let end = calendar.date(byAdding: .day, value: 1, to: rawEnd)!
            return (start, end)
        }
    }

    private var filteredEntries: [TimeEntry] {
        let interval = resolvedDateInterval
        return store.timeEntries.filter {
            $0.startDate >= interval.start && $0.startDate < interval.end && $0.endDate != nil
        }
    }

    private var totalDuration: TimeInterval {
        filteredEntries.reduce(0.0) { $0 + $1.effectiveDuration }
    }

    private var breakdownItems: [BreakdownItem] {
        let total = totalDuration
        guard total > 0 else { return [] }

        switch selectedDimension {
        case .projects:
            let grouped = Dictionary(grouping: filteredEntries) { $0.projectId }
            return grouped.map { projId, entries in
                let duration = entries.reduce(0.0) { $0 + $1.effectiveDuration }
                let percent = (duration / total) * 100.0
                let project = projId.flatMap { store.project(for: $0) }
                let name = project?.name ?? "No Project"
                let colorHex = project?.colorHex ?? "#8E8E93"

                return BreakdownItem(
                    id: projId ?? UUID(),
                    name: name,
                    colorHex: colorHex,
                    duration: duration,
                    percentage: percent
                )
            }
            .sorted { $0.duration > $1.duration }

        case .clients:
            // Map entries to client via their project
            var clientDurations: [UUID?: (name: String, colorHex: String, duration: TimeInterval)] = [:]

            for entry in filteredEntries {
                let duration = entry.effectiveDuration
                let project = entry.projectId.flatMap { store.project(for: $0) }
                let client = project?.clientId.flatMap { store.client(for: $0) }

                let clientId = client?.id
                let clientName = client?.name ?? (project != nil ? "No Client" : "Unassigned")
                let colorHex = project?.colorHex ?? "#8E8E93"

                if let current = clientDurations[clientId] {
                    clientDurations[clientId] = (current.name, current.colorHex, current.duration + duration)
                } else {
                    clientDurations[clientId] = (clientName, colorHex, duration)
                }
            }

            return clientDurations.map { clientId, data in
                let percent = (data.duration / total) * 100.0
                return BreakdownItem(
                    id: clientId ?? UUID(),
                    name: data.name,
                    colorHex: data.colorHex,
                    duration: data.duration,
                    percentage: percent
                )
            }
            .sorted { $0.duration > $1.duration }

        case .tags:
            var tagDurations: [UUID?: (name: String, colorHex: String, duration: TimeInterval)] = [:]
            for entry in filteredEntries {
                let duration = entry.effectiveDuration
                if entry.tagIds.isEmpty {
                    if let cur = tagDurations[nil] {
                        tagDurations[nil] = (cur.name, cur.colorHex, cur.duration + duration)
                    } else {
                        tagDurations[nil] = ("No Tag", "#8E8E93", duration)
                    }
                } else {
                    for tagId in entry.tagIds {
                        let tag = store.tags.first(where: { $0.id == tagId })
                        let name = tag?.name ?? "Unknown Tag"
                        let colorHex = tag?.colorHex ?? "#E54583"
                        if let cur = tagDurations[tagId] {
                            tagDurations[tagId] = (cur.name, cur.colorHex, cur.duration + duration)
                        } else {
                            tagDurations[tagId] = ("#\(name)", colorHex, duration)
                        }
                    }
                }
            }
            return tagDurations.map { tagId, data in
                let percent = (data.duration / total) * 100.0
                return BreakdownItem(
                    id: tagId ?? UUID(),
                    name: data.name,
                    colorHex: data.colorHex,
                    duration: data.duration,
                    percentage: percent
                )
            }
            .sorted { $0.duration > $1.duration }
        }
    }

    private var billableDuration: TimeInterval {
        filteredEntries.filter { $0.isBillable }.reduce(0.0) { $0 + $1.effectiveDuration }
    }

    private var billableAmount: Double {
        filteredEntries.reduce(0.0) { sum, entry in
            guard entry.isBillable else { return sum }
            let rate = entry.projectId.flatMap { store.project(for: $0)?.hourlyRate }
                ?? entry.projectId.flatMap { store.project(for: $0)?.clientId }.flatMap { store.client(for: $0)?.hourlyRate }
                ?? 50.0
            return sum + (entry.effectiveDuration / 3600.0) * rate
        }
    }

    private var dailyAverage: TimeInterval {
        let interval = resolvedDateInterval
        let days = max(1, Calendar.current.dateComponents([.day], from: interval.start, to: interval.end).day ?? 1)
        return totalDuration / Double(days)
    }

    private var topEntityName: String {
        breakdownItems.first?.name ?? "None"
    }

    public var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Toolbar Strip: Range, Custom Pickers, Dimension, and Export Button
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reports")
                                .font(AppTypography.heading)
                            Text("Productivity distribution and time exports")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Export Menu Button (D-08)
                        Menu {
                            Button("Export as CSV...") {
                                exportCSV()
                            }
                            Button("Export as JSON...") {
                                exportJSON()
                            }
                        } label: {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColors.brandAccent.opacity(0.12))
                            .foregroundStyle(AppColors.brandAccent)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                        }
                        .menuStyle(.borderlessButton)
                    }

                    // Filters Row
                    HStack(spacing: AppSpacing.md) {
                        Picker("Range", selection: $selectedRange) {
                            ForEach(DateRangePreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 340)

                        Picker("Dimension", selection: $selectedDimension) {
                            ForEach(ReportDimension.allCases) { dim in
                                Text(dim.rawValue).tag(dim)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 200)

                        Spacer()
                    }

                    // Custom Date Pickers when 'Custom Range' is selected (D-07)
                    if selectedRange == .custom {
                        HStack(spacing: AppSpacing.md) {
                            DatePicker("Start", selection: $customStartDate, displayedComponents: .date)
                                .labelsHidden()
                            Text("to")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                            DatePicker("End", selection: $customEndDate, displayedComponents: .date)
                                .labelsHidden()
                            Spacer()
                        }
                        .padding(.top, AppSpacing.xs)
                    }
                }

                // 4 Toggl Track KPI Metric Cards Strip (Reference Images 4 & 8)
                HStack(spacing: AppSpacing.md) {
                    summaryCard(
                        title: "TOTAL HOURS",
                        value: totalDuration > 0 ? DateHelper.formatHumanDuration(totalDuration) : "0h 0m",
                        icon: "clock"
                    )
                    summaryCard(
                        title: "BILLABLE HOURS",
                        value: billableDuration > 0 ? DateHelper.formatHumanDuration(billableDuration) : "0h 0m",
                        icon: "dollarsign.circle"
                    )
                    summaryCard(
                        title: "AMOUNT",
                        value: String(format: "$%.2f", billableAmount),
                        icon: "banknote"
                    )
                    summaryCard(
                        title: "AVERAGE DAILY HOURS",
                        value: dailyAverage > 0 ? DateHelper.formatHumanDuration(dailyAverage) : "0h 0m",
                        icon: "chart.bar"
                    )
                }

                // Main Analytics Card: Donut Chart + Breakdown Table
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("\(selectedDimension.rawValue) Distribution")
                        .font(AppTypography.heading)

                    HStack(alignment: .center, spacing: AppSpacing.xl) {
                        ReportsDonutChartView(
                            items: breakdownItems,
                            totalDuration: totalDuration
                        )
                        .frame(width: 240)

                        Divider()

                        ReportsBreakdownTableView(items: breakdownItems)
                            .frame(maxWidth: .infinity)
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
            .padding(AppSpacing.xl)
        }
        .background(AppColors.background)
    }

    @ViewBuilder
    private func summaryCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.brandAccent)
            }
            Text(value)
                .font(AppTypography.heading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                .stroke(AppColors.border, lineWidth: 0.5)
        )
    }

    private func exportCSV() {
        let csv = ExportService.generateCSV(
            entries: filteredEntries,
            projects: store.projects,
            clients: store.clients,
            tasks: store.tasks
        )
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        let filename = "TimeStamp-Report-\(dateStr).csv"
        ExportService.presentSavePanel(
            data: Data(csv.utf8),
            defaultFilename: filename,
            fileExtension: "csv"
        )
    }

    private func exportJSON() {
        let json = ExportService.generateJSON(
            entries: filteredEntries,
            projects: store.projects,
            clients: store.clients,
            tasks: store.tasks
        )
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        let filename = "TimeStamp-Report-\(dateStr).json"
        ExportService.presentSavePanel(
            data: json,
            defaultFilename: filename,
            fileExtension: "json"
        )
    }
}
