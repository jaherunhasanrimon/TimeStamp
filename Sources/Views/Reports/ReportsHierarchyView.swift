import SwiftUI

public struct ProjectTaskBreakdownRow: Identifiable {
    public let id: String
    public let project: Project?
    public let clientName: String?
    public let totalDuration: TimeInterval
    public let billableDuration: TimeInterval
    public let billableAmount: Double
    public let currency: String
    public let taskBreakdown: [(taskName: String, duration: TimeInterval, entryCount: Int)]
}

public struct ReportsHierarchyView: View {
    public let entries: [TimeEntry]
    public let projects: [Project]
    public let clients: [Client]
    public let tasks: [Task]
    public let defaultHourlyRate: Double

    @State private var expandedIds: Set<String> = []

    public init(
        entries: [TimeEntry],
        projects: [Project],
        clients: [Client],
        tasks: [Task],
        defaultHourlyRate: Double
    ) {
        self.entries = entries
        self.projects = projects
        self.clients = clients
        self.tasks = tasks
        self.defaultHourlyRate = defaultHourlyRate
    }

    private var rows: [ProjectTaskBreakdownRow] {
        let projMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        let clientMap = Dictionary(uniqueKeysWithValues: clients.map { ($0.id, $0) })
        let taskMap = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })

        var byProject: [String: [TimeEntry]] = [:]
        for entry in entries {
            let key = entry.projectId?.uuidString ?? "no-project"
            byProject[key, default: []].append(entry)
        }

        return byProject.map { key, groupEntries in
            let proj = groupEntries.first?.projectId.flatMap { projMap[$0] }
            let client = proj?.clientId.flatMap { clientMap[$0] }
            let currency = client?.currency ?? "$"
            let rate = proj?.hourlyRate ?? client?.hourlyRate ?? defaultHourlyRate

            let total = groupEntries.reduce(0.0) { $0 + $1.effectiveDuration }
            let billableSecs = groupEntries.filter(\.isBillable).reduce(0.0) { $0 + $1.effectiveDuration }
            let amount = (billableSecs / 3600.0) * rate

            var byTask: [String: (duration: TimeInterval, count: Int)] = [:]
            for e in groupEntries {
                let tName = e.taskId.flatMap { taskMap[$0]?.name } ?? "No Task"
                let cur = byTask[tName] ?? (0, 0)
                byTask[tName] = (cur.duration + e.effectiveDuration, cur.count + 1)
            }
            let sortedTasks = byTask.map { (taskName: $0.key, duration: $0.value.duration, entryCount: $0.value.count) }
                .sorted { $0.duration > $1.duration }

            return ProjectTaskBreakdownRow(
                id: key,
                project: proj,
                clientName: client?.name,
                totalDuration: total,
                billableDuration: billableSecs,
                billableAmount: amount,
                currency: currency,
                taskBreakdown: sortedTasks
            )
        }
        .sorted { $0.totalDuration > $1.totalDuration }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("PROJECT & TASK BREAKDOWN")
                .font(AppTypography.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(0.8)

            if rows.isEmpty {
                Text("No project data in the selected range.")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, AppSpacing.md)
            } else {
                VStack(spacing: 4) {
                    ForEach(rows) { row in
                        let isExpanded = expandedIds.contains(row.id)
                        VStack(alignment: .leading, spacing: 4) {
                            Button {
                                if expandedIds.contains(row.id) {
                                    expandedIds.remove(row.id)
                                } else {
                                    expandedIds.insert(row.id)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 12)

                                    Circle()
                                        .fill(Color(hex: row.project?.colorHex ?? "#8E8E93"))
                                        .frame(width: 9, height: 9)

                                    Text(row.project?.name ?? "No Project")
                                        .font(AppTypography.body)
                                        .foregroundStyle(.primary)

                                    if let c = row.clientName {
                                        Text("· \(c)")
                                            .font(AppTypography.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if row.billableAmount > 0 {
                                        Text("\(row.currency)\(String(format: "%.2f", row.billableAmount))")
                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(AppColors.billable)
                                    }

                                    Text(TimeCalculator.formatCompactDuration(row.totalDuration))
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(.primary)
                                        .frame(width: 72, alignment: .trailing)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(AppColors.insetBackground.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                            }
                            .buttonStyle(.plain)

                            if isExpanded {
                                ForEach(row.taskBreakdown, id: \.taskName) { t in
                                    HStack(spacing: 8) {
                                        Text(t.taskName)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(.secondary)
                                        Text("(\(t.entryCount))")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary.opacity(0.75))
                                        Spacer()
                                        Text(TimeCalculator.formatCompactDuration(t.duration))
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.leading, 32)
                                    .padding(.trailing, 8)
                                    .padding(.vertical, 3)
                                }
                            }
                        }
                    }
                }
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
