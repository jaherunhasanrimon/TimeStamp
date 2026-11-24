import SwiftUI

/// Toggl Track Time Entry Row View (Reference Image 5).
/// Line 1: Description
/// Line 2: • Project Name (with colored circle dot) • Task • Client
/// Right: $ (Billable) + Monospace Duration + Play-Again Action
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

    private var client: Client? {
        guard let p = project, let cId = p.clientId else { return nil }
        return store.clients.first(where: { $0.id == cId })
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Left Column: Description (Line 1) and Project/Client Dot (Line 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.entryDescription.isEmpty ? "(No description)" : entry.entryDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(entry.entryDescription.isEmpty ? .secondary : Color.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let project = project {
                        Circle()
                            .fill(Color(hex: project.colorHex))
                            .frame(width: 7, height: 7)

                        Text(project.name)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(hex: project.colorHex))

                        if let task = task {
                            Text("• \(task.name)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        if let client = client {
                            Text("• \(client.name)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("• No Project")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    // Tag Badges
                    if !entry.tagIds.isEmpty {
                        ForEach(entry.tagIds, id: \.self) { tagId in
                            if let tag = store.tags.first(where: { $0.id == tagId }) {
                                Text("#\(tag.name)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color(hex: tag.colorHex).opacity(0.9))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1.5)
                                    .background(Color(hex: tag.colorHex).opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            // Right Column: Billable $ + Monospace Duration + Play-Again Hover
            HStack(spacing: 10) {
                if entry.isBillable {
                    Text("$")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColors.billable)
                }

                Text(TimeCalculator.formatDuration(entry.effectiveDuration))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.primary)

                if isHovered {
                    // Play-Again Quick Action
                    Button(action: startCopyTimer) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 22, height: 22)
                            .background(AppColors.togglMagenta)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Continue tracking this entry")
                    .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isHovered ? AppColors.secondaryCardBackground : AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppColors.border.opacity(0.8), lineWidth: 0.8)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button("Continue tracking") {
                startCopyTimer()
            }

            Button("Edit details...") {
                onEdit()
            }

            Divider()

            Button("Delete entry", role: .destructive) {
                onDelete()
            }
        }
    }

    private func startCopyTimer() {
        timerManager.start(
            description: entry.entryDescription,
            projectId: entry.projectId,
            taskId: entry.taskId,
            tagIds: entry.tagIds,
            isBillable: entry.isBillable
        )
    }
}
