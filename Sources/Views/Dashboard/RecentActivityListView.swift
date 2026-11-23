import SwiftUI

public struct RecentActivityListView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    public init() {}

    private var recentEntries: [TimeEntry] {
        Array(
            store.timeEntries
                .filter { $0.endDate != nil }
                .sorted { $0.startDate > $1.startDate }
                .prefix(5)
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Label("Recent Activity", systemImage: "clock.arrow.circlepath")
                    .font(AppTypography.heading)

                Spacer()

                Text("Last 5 entries")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            if recentEntries.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "timer")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text("No recent activity recorded yet.")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentEntries.enumerated()), id: \.element.id) { index, entry in
                        recentEntryRow(entry)

                        if index < recentEntries.count - 1 {
                            Divider()
                                .padding(.leading, 24)
                        }
                    }
                }
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                        .stroke(AppColors.border, lineWidth: 0.5)
                )
            }
        }
    }

    @ViewBuilder
    private func recentEntryRow(_ entry: TimeEntry) -> some View {
        let project = entry.projectId.flatMap { store.project(for: $0) }
        let task = entry.taskId.flatMap { store.task(for: $0) }

        HStack(spacing: AppSpacing.md) {
            // Project swatch dot
            Circle()
                .fill(project.map { Color(hex: $0.colorHex) } ?? Color.secondary.opacity(0.4))
                .frame(width: 8, height: 8)

            // Description & Project / Task
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.entryDescription.isEmpty ? "(No description)" : entry.entryDescription)
                    .font(AppTypography.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.xs) {
                    Text(project?.name ?? "No Project")
                        .font(AppTypography.caption)
                        .foregroundStyle(project != nil ? Color(hex: project!.colorHex) : .secondary)

                    if let task = task {
                        Text("•")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                        Text(task.name)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Relative date
            Text(DateHelper.formatRelativeDay(entry.startDate))
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)

            // Formatted duration
            Text(DateHelper.formatHumanDuration(entry.effectiveDuration))
                .font(AppTypography.ticker)
                .foregroundStyle(.primary)
                .frame(minWidth: 64, alignment: .trailing)

            // Continue Play Button (D-03)
            Button(action: {
                timerManager.continueEntry(entry)
            }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.brandAccent)
                    .frame(width: 28, height: 28)
                    .background(AppColors.brandAccent.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Continue this entry")
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}
