import SwiftUI

public struct ReportsDetailedTableView: View {
    public enum SortOrder: String, CaseIterable, Identifiable {
        case newestFirst = "Newest first"
        case oldestFirst = "Oldest first"
        case longestFirst = "Longest duration"

        public var id: String { rawValue }
    }

    @Environment(PersistenceStore.self) private var store

    public let entries: [TimeEntry]
    @State private var sortOrder: SortOrder = .newestFirst
    @State private var entryToEdit: TimeEntry? = nil

    public init(entries: [TimeEntry]) {
        self.entries = entries
    }

    private var sortedEntries: [TimeEntry] {
        switch sortOrder {
        case .newestFirst:
            return entries.sorted { $0.startDate > $1.startDate }
        case .oldestFirst:
            return entries.sorted { $0.startDate < $1.startDate }
        case .longestFirst:
            return entries.sorted { $0.effectiveDuration > $1.effectiveDuration }
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("DETAILED ENTRIES (\(entries.count))")
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.8)

                Spacer()

                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }

            if sortedEntries.isEmpty {
                TogglEmptyStateView(
                    style: .binoculars(
                        title: "No detailed entries found",
                        subtitle: "Adjust your filters or date range to inspect entries."
                    )
                )
                .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(sortedEntries) { entry in
                        detailedRow(entry)
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
        .sheet(item: $entryToEdit) { entry in
            EntryEditSheet(mode: .edit(entry))
        }
    }

    @ViewBuilder
    private func detailedRow(_ entry: TimeEntry) -> some View {
        let project = entry.projectId.flatMap { store.project(for: $0) }
        let client = project?.clientId.flatMap { store.client(for: $0) }
        let task = entry.taskId.flatMap { store.task(for: $0) }
        let entryTags = entry.tagIds.compactMap { store.tag(for: $0) }

        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.entryDescription.isEmpty ? "(No description)" : entry.entryDescription)
                    .font(AppTypography.body)
                    .foregroundStyle(entry.entryDescription.isEmpty ? .secondary : .primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let project {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: project.colorHex))
                                .frame(width: 7, height: 7)
                            Text(project.name)
                                .font(AppTypography.caption)
                                .foregroundStyle(Color(hex: project.colorHex))
                            if let client {
                                Text("· \(client.name)")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let task {
                                Text("· \(task.name)")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("No Project")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(entryTags) { tag in
                        Text("#\(tag.name)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text(DateHelper.formatTimeRange(start: entry.startDate, end: entry.endDate))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)

            if entry.isBillable {
                Text("$")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.billable)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.billable.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(TimeCalculator.formatCompactDuration(entry.effectiveDuration))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .frame(width: 72, alignment: .trailing)

            Button {
                entryToEdit = entry
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Edit entry")
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 8)
        .background(AppColors.insetBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
    }
}
