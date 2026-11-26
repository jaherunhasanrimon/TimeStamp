import SwiftUI

public struct ReportsView: View {
    public enum ReportTab: String, CaseIterable, Identifiable {
        case summary = "Summary"
        case detailed = "Detailed"
        case weekly = "Weekly"

        public var id: String { rawValue }
    }

    public enum DateRangePreset: String, CaseIterable, Identifiable {
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case lastWeek = "Last Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case custom = "Custom Range"

        public var id: String { rawValue }
    }

    public enum BillableFilter: String, CaseIterable, Identifiable {
        case all = "All entries"
        case billableOnly = "Billable only"
        case nonBillableOnly = "Non-billable only"

        public var id: String { rawValue }
    }

    @Environment(PersistenceStore.self) private var store
    @AppStorage("defaultHourlyRate") private var defaultHourlyRate: Double = 0.0

    @State private var selectedTab: ReportTab = .summary
    @State private var selectedPreset: DateRangePreset = .thisWeek
    @State private var customStartDate: Date = DateHelper.startOfWeek(for: Date())
    @State private var customEndDate: Date = Date()

    @State private var selectedClientId: UUID? = nil
    @State private var selectedProjectId: UUID? = nil
    @State private var selectedTagId: UUID? = nil
    @State private var billableFilter: BillableFilter = .all
    @State private var searchQuery: String = ""

    public init() {}

    private var resolvedDateRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        let todayStart = cal.startOfDay(for: now)

        switch selectedPreset {
        case .today:
            return (todayStart, now)
        case .yesterday:
            let yStart = cal.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
            let yEnd = todayStart.addingTimeInterval(-1)
            return (yStart, yEnd)
        case .thisWeek:
            let wStart = DateHelper.startOfWeek(for: now)
            let wEnd = cal.date(byAdding: .day, value: 7, to: wStart)?.addingTimeInterval(-1) ?? now
            return (wStart, wEnd)
        case .lastWeek:
            let thisW = DateHelper.startOfWeek(for: now)
            let lastWStart = cal.date(byAdding: .day, value: -7, to: thisW) ?? thisW
            let lastWEnd = thisW.addingTimeInterval(-1)
            return (lastWStart, lastWEnd)
        case .thisMonth:
            let comps = cal.dateComponents([.year, .month], from: now)
            let mStart = cal.date(from: comps) ?? todayStart
            let mEnd = cal.date(byAdding: .month, value: 1, to: mStart)?.addingTimeInterval(-1) ?? now
            return (mStart, mEnd)
        case .lastMonth:
            let comps = cal.dateComponents([.year, .month], from: now)
            let thisM = cal.date(from: comps) ?? todayStart
            let lastMStart = cal.date(byAdding: .month, value: -1, to: thisM) ?? thisM
            let lastMEnd = thisM.addingTimeInterval(-1)
            return (lastMStart, lastMEnd)
        case .custom:
            let start = cal.startOfDay(for: customStartDate)
            let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: customEndDate))?.addingTimeInterval(-1) ?? customEndDate
            return (start, max(start, end))
        }
    }

    private var periodDisplayLabel: String {
        let range = resolvedDateRange
        let df = DateFormatter()
        df.dateStyle = .medium
        return "\(df.string(from: range.start)) – \(df.string(from: range.end))"
    }

    private var filteredEntries: [TimeEntry] {
        let range = resolvedDateRange
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return store.timeEntries.filter { entry in
            guard entry.endDate != nil else { return false }
            guard entry.startDate >= range.start && entry.startDate <= range.end else { return false }

            if let projFilter = selectedProjectId, entry.projectId != projFilter {
                return false
            }

            if let clientFilter = selectedClientId {
                guard let pId = entry.projectId,
                      let project = store.project(for: pId),
                      project.clientId == clientFilter else {
                    return false
                }
            }

            if let tagFilter = selectedTagId, !entry.tagIds.contains(tagFilter) {
                return false
            }

            switch billableFilter {
            case .all: break
            case .billableOnly: guard entry.isBillable else { return false }
            case .nonBillableOnly: guard !entry.isBillable else { return false }
            }

            if !query.isEmpty {
                let descMatch = entry.entryDescription.lowercased().contains(query)
                let projMatch = entry.projectId.flatMap { store.project(for: $0)?.name.lowercased().contains(query) } ?? false
                if !descMatch && !projMatch { return false }
            }

            return true
        }
    }

    private var totalTrackedDuration: TimeInterval {
        filteredEntries.reduce(0) { $0 + $1.effectiveDuration }
    }

    private var billableDuration: TimeInterval {
        filteredEntries.filter(\.isBillable).reduce(0) { $0 + $1.effectiveDuration }
    }

    private var billablePercentage: Int {
        guard totalTrackedDuration > 0 else { return 0 }
        return Int(round((billableDuration / totalTrackedDuration) * 100.0))
    }

    private var totalBillableEarnings: Double {
        filteredEntries.filter(\.isBillable).reduce(0.0) { sum, entry in
            let proj = entry.projectId.flatMap { store.project(for: $0) }
            let client = proj?.clientId.flatMap { store.client(for: $0) }
            let rate = proj?.hourlyRate ?? client?.hourlyRate ?? defaultHourlyRate
            return sum + (entry.effectiveDuration / 3600.0) * rate
        }
    }

    private var primaryCurrencySymbol: String {
        for entry in filteredEntries where entry.isBillable {
            if let pId = entry.projectId,
               let cId = store.project(for: pId)?.clientId,
               let sym = store.client(for: cId)?.currency {
                return sym
            }
        }
        return "$"
    }

    private var projectBreakdown: [BreakdownItem] {
        let total = totalTrackedDuration
        guard total > 0 else { return [] }

        var byProject: [UUID?: TimeInterval] = [:]
        for entry in filteredEntries {
            byProject[entry.projectId, default: 0] += entry.effectiveDuration
        }

        return byProject.map { projId, duration in
            let proj = projId.flatMap { store.project(for: $0) }
            return BreakdownItem(
                id: projId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                name: proj?.name ?? "No Project",
                colorHex: proj?.colorHex ?? "#8E8E93",
                duration: duration,
                percentage: (duration / total) * 100.0
            )
        }
        .sorted { $0.duration > $1.duration }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header + Controls Toolbar
            VStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.md) {
                    Text("Reports")
                        .font(AppTypography.heading)
                        .foregroundStyle(.primary)

                    Picker("", selection: $selectedTab) {
                        ForEach(ReportTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)

                    Spacer()

                    // Period Stepper & Preset Picker
                    HStack(spacing: 4) {
                        Button { stepPeriod(by: -1) } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                        Picker("", selection: $selectedPreset) {
                            ForEach(DateRangePreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 135)

                        Button { stepPeriod(by: 1) } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Menu {
                        Button { exportCSV() } label: {
                            Label("Export CSV", systemImage: "tablecells")
                        }
                        Button { exportJSON() } label: {
                            Label("Export JSON", systemImage: "curlybraces")
                        }
                        Button { exportPDF() } label: {
                            Label("Export PDF Report", systemImage: "doc.richtext")
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .font(AppTypography.label)
                    }
                    .menuStyle(.borderedButton)
                    .fixedSize()
                }

                // Filters & Custom Range Row
                HStack(spacing: AppSpacing.sm) {
                    if selectedPreset == .custom {
                        DatePicker("From", selection: $customStartDate, displayedComponents: .date)
                            .labelsHidden()
                        Text("→").foregroundStyle(.secondary)
                        DatePicker("To", selection: $customEndDate, displayedComponents: .date)
                            .labelsHidden()
                    } else {
                        Text(periodDisplayLabel)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Search
                    TextField("Description / project...", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .font(AppTypography.caption)
                        .frame(width: 150)

                    // Client Filter
                    Picker("Client", selection: $selectedClientId) {
                        Text("All Clients").tag(Optional<UUID>.none)
                        ForEach(store.clients) { c in
                            Text(c.name).tag(Optional<UUID>.some(c.id))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 115)

                    // Project Filter
                    Picker("Project", selection: $selectedProjectId) {
                        Text("All Projects").tag(Optional<UUID>.none)
                        ForEach(store.projects) { p in
                            Text(p.name).tag(Optional<UUID>.some(p.id))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)

                    // Tag Filter
                    Picker("Tag", selection: $selectedTagId) {
                        Text("All Tags").tag(Optional<UUID>.none)
                        ForEach(store.tags) { t in
                            Text("#\(t.name)").tag(Optional<UUID>.some(t.id))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 105)

                    // Billable Filter
                    Picker("Billable", selection: $billableFilter) {
                        ForEach(BillableFilter.allCases) { bf in
                            Text(bf.rawValue).tag(bf)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 115)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            Divider()

            // Main Report Content
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // KPI Metrics Row
                    HStack(spacing: AppSpacing.md) {
                        kpiCard(
                            title: "Total Tracked",
                            value: TimeCalculator.formatCompactDuration(totalTrackedDuration),
                            icon: "clock.fill",
                            color: AppColors.brandAccent
                        )
                        kpiCard(
                            title: "Billable Time",
                            value: TimeCalculator.formatCompactDuration(billableDuration),
                            icon: "dollarsign.circle.fill",
                            color: AppColors.billable
                        )
                        kpiCard(
                            title: "Billable Share",
                            value: "\(billablePercentage)%",
                            icon: "chart.pie.fill",
                            color: AppColors.togglMagenta
                        )
                        kpiCard(
                            title: "Estimated Earnings",
                            value: "\(primaryCurrencySymbol)\(String(format: "%.2f", totalBillableEarnings))",
                            icon: "banknote.fill",
                            color: AppColors.goalGold
                        )
                    }

                    switch selectedTab {
                    case .summary:
                        HStack(alignment: .top, spacing: AppSpacing.lg) {
                            ReportsDailyBarChartView(
                                entries: filteredEntries,
                                projects: store.projects,
                                startDate: resolvedDateRange.start,
                                endDate: resolvedDateRange.end
                            )

                            VStack(spacing: AppSpacing.sm) {
                                ReportsDonutChartView(
                                    items: projectBreakdown,
                                    totalDuration: totalTrackedDuration
                                )
                            }
                            .padding(AppSpacing.lg)
                            .frame(width: 280)
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                                    .stroke(AppColors.border, lineWidth: 0.5)
                            )
                        }

                        ReportsHierarchyView(
                            entries: filteredEntries,
                            projects: store.projects,
                            clients: store.clients,
                            tasks: store.tasks,
                            defaultHourlyRate: defaultHourlyRate
                        )

                    case .detailed:
                        ReportsDetailedTableView(entries: filteredEntries)

                    case .weekly:
                        ReportsWeeklyMatrixView(
                            entries: filteredEntries,
                            projects: store.projects,
                            clients: store.clients,
                            referenceDate: resolvedDateRange.start
                        )
                    }
                }
                .padding(AppSpacing.lg)
            }
        }
        .background(AppColors.background)
    }

    @ViewBuilder
    private func kpiCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                .stroke(AppColors.border, lineWidth: 0.5)
        )
    }

    private func stepPeriod(by direction: Int) {
        let range = resolvedDateRange
        let spanDays = max(1, (Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 0) + 1)
        let cal = Calendar.current
        if let newStart = cal.date(byAdding: .day, value: direction * spanDays, to: range.start),
           let newEnd = cal.date(byAdding: .day, value: direction * spanDays, to: range.end) {
            customStartDate = newStart
            customEndDate = newEnd
            selectedPreset = .custom
        }
    }

    private func exportCSV() {
        let csv = ExportService.generateCSV(
            entries: filteredEntries,
            projects: store.projects,
            clients: store.clients,
            tasks: store.tasks,
            tags: store.tags,
            defaultHourlyRate: defaultHourlyRate,
            includeExtendedColumns: true
        )
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        ExportService.presentSavePanel(
            data: Data(csv.utf8),
            defaultFilename: "TimeStamp-Report-\(dateStr).csv",
            fileExtension: "csv"
        )
    }

    private func exportJSON() {
        let json = ExportService.generateJSON(
            entries: filteredEntries,
            projects: store.projects,
            clients: store.clients,
            tasks: store.tasks,
            tags: store.tags,
            defaultHourlyRate: defaultHourlyRate
        )
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        ExportService.presentSavePanel(
            data: json,
            defaultFilename: "TimeStamp-Report-\(dateStr).json",
            fileExtension: "json"
        )
    }

    private func exportPDF() {
        let pdf = ExportService.generatePDF(
            title: "TimeStamp Report (\(selectedTab.rawValue))",
            periodLabel: periodDisplayLabel,
            entries: filteredEntries,
            projects: store.projects,
            clients: store.clients,
            tasks: store.tasks,
            defaultHourlyRate: defaultHourlyRate
        )
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        ExportService.presentSavePanel(
            data: pdf,
            defaultFilename: "TimeStamp-Report-\(dateStr).pdf",
            fileExtension: "pdf"
        )
    }
}
