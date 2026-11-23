import SwiftUI

public struct TimeEntryRowView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    public let entry: TimeEntry
    public let onEdit: () -> Void
    public let onDelete: () -> Void

    @State private var isHovered: Bool = false

    public init(entry: TimeEntry, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.entry = entry
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    private var project: Project? {
        guard let id = entry.projectId else { return nil }
        return store.projects.first(where: { $0.id == id })
    }

    private var task: Task? {
        guard let id = entry.taskId else { return nil }
        return store.tasks.first(where: { $0.id == id })
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Left: Project Swatch, Task & Description
            HStack(spacing: AppSpacing.sm) {
                if let project = project {
                    Circle()
                        .fill(Color(hex: project.colorHex))
                        .frame(width: 8, height: 8)

                    Text(project.name)
                        .font(AppTypography.label)
                        .foregroundStyle(Color(hex: project.colorHex))

                    if let task = task {
                        Text("•")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                        Text(task.name)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("—")
                        .font(AppTypography.caption)
                        .foregroundStyle(.tertiary)
                }

                Text(entry.entryDescription.isEmpty ? "(No description)" : entry.entryDescription)
                    .font(AppTypography.body)
                    .foregroundStyle(entry.entryDescription.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
            }

            Spacer()

            // Right: Time Range & Duration
            HStack(spacing: AppSpacing.md) {
                Text(DateHelper.formatTimeRange(start: entry.startDate, end: entry.endDate))
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)

                Text(TimeCalculator.formatDuration(entry.effectiveDuration))
                    .font(AppTypography.subTicker)
                    .foregroundStyle(entry.isRunning ? AppColors.brandAccent : .primary)
                    .frame(minWidth: 65, alignment: .trailing)

                // Hover Actions
                HStack(spacing: AppSpacing.xs) {
                    if isHovered {
                        Button {
                            timerManager.continueEntry(entry)
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppColors.brandAccent)
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                        .background(AppColors.cardBackground)
                        .clipShape(Circle())
                        .help("Continue tracking")

                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                        .help("Delete entry")
                    } else {
                        Color.clear
                            .frame(width: 48, height: 22)
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(isHovered ? AppColors.cardBackground.opacity(0.8) : AppColors.cardBackground.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusSmall)
                .stroke(AppColors.subtleBorder, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button {
                timerManager.continueEntry(entry)
            } label: {
                Label("Continue Timer", systemImage: "play.fill")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit...", systemImage: "pencil")
            }

            Button {
                duplicateEntry()
            } label: {
                Label("Duplicate Entry", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete...", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func duplicateEntry() {
        let duplicate = TimeEntry(
            entryDescription: entry.entryDescription,
            startDate: Date(),
            endDate: Date().addingTimeInterval(entry.effectiveDuration),
            accumulatedDuration: entry.accumulatedDuration,
            isPaused: false,
            projectId: entry.projectId,
            taskId: entry.taskId,
            tagIds: entry.tagIds
        )
        store.saveTimeEntry(duplicate)
    }
}
