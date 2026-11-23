import SwiftUI

public struct ClientRowView: View {
    public let client: Client
    public let onEdit: () -> Void
    public let onDelete: () -> Void
    public var onViewEntries: ((EntryFilter) -> Void)? = nil

    @Environment(PersistenceStore.self) private var store
    @State private var isExpanded: Bool = false
    @State private var isHovered: Bool = false

    public init(
        client: Client,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onViewEntries: ((EntryFilter) -> Void)? = nil
    ) {
        self.client = client
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onViewEntries = onViewEntries
    }

    private var assignedProjects: [Project] {
        store.projects.filter { $0.clientId == client.id }
    }

    private var totalTrackedDuration: TimeInterval {
        let projectIds = Set(assignedProjects.map { $0.id })
        return store.timeEntries
            .filter { entry in
                guard let pId = entry.projectId else { return false }
                return projectIds.contains(pId)
            }
            .reduce(0) { $0 + $1.effectiveDuration }
    }

    public var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                if assignedProjects.isEmpty {
                    Text("No projects assigned yet")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(assignedProjects) { project in
                        let projectDuration = store.timeEntries
                            .filter { $0.projectId == project.id }
                            .reduce(0) { $0 + $1.effectiveDuration }
                        let taskCount = store.tasks.filter { $0.projectId == project.id }.count

                        HStack(spacing: AppSpacing.sm) {
                            Circle()
                                .fill(Color(hex: project.colorHex))
                                .frame(width: 8, height: 8)

                            Text(project.name)
                                .font(AppTypography.body)
                                .foregroundStyle(.primary)

                            Spacer()

                            if taskCount > 0 {
                                Text("\(taskCount) tasks")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if projectDuration > 0 {
                                Text(DateHelper.formatHumanDuration(projectDuration))
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, AppSpacing.xs)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, AppSpacing.sm)
                        .background(Color.secondary.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                    }
                }
            }
            .padding(.leading, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                // Client Icon
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.brandAccent)
                    .frame(width: 24, height: 24)
                    .background(AppColors.brandAccent.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(client.name)
                        .font(AppTypography.heading)
                        .foregroundStyle(.primary)

                    if let notes = client.notes, !notes.isEmpty {
                        Text(notes)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Metrics
                HStack(spacing: AppSpacing.sm) {
                    Text("\(assignedProjects.count) \(assignedProjects.count == 1 ? "project" : "projects")")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)

                    if totalTrackedDuration > 0 {
                        Text(DateHelper.formatHumanDuration(totalTrackedDuration))
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                    }
                }

                // Hover Action Container
                HStack(spacing: AppSpacing.xs) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help("Edit client")

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help("Delete client")
                }
                .opacity(isHovered ? 1.0 : 0.0)
            }
            .frame(minHeight: 48)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(isHovered ? Color.secondary.opacity(0.03) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit Client...", systemImage: "pencil")
            }

            Button {
                onViewEntries?(.client(client.id))
            } label: {
                Label("View Entries", systemImage: "clock")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Client...", systemImage: "trash")
            }
        }
    }
}
