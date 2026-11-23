import SwiftUI

public struct ProjectRowView: View {
    public let project: Project
    public let onEdit: () -> Void
    public let onDelete: () -> Void
    public var onViewEntries: ((EntryFilter) -> Void)? = nil

    @Environment(PersistenceStore.self) private var store
    @State private var isExpanded: Bool = false
    @State private var isCompletedGroupExpanded: Bool = false
    @State private var isHovered: Bool = false
    @State private var taskToDelete: Task? = nil
    @State private var isDeleteTaskAlertPresented: Bool = false

    public init(
        project: Project,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onViewEntries: ((EntryFilter) -> Void)? = nil
    ) {
        self.project = project
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onViewEntries = onViewEntries
    }

    private var projectTasks: [Task] {
        store.tasks.filter { $0.projectId == project.id }
    }

    private var activeTasks: [Task] {
        projectTasks.filter { !$0.isCompleted }
    }

    private var completedTasks: [Task] {
        projectTasks.filter { $0.isCompleted }
    }

    private var clientName: String? {
        guard let clientId = project.clientId else { return nil }
        return store.clients.first(where: { $0.id == clientId })?.name
    }

    private var totalTrackedDuration: TimeInterval {
        store.timeEntries
            .filter { $0.projectId == project.id }
            .reduce(0) { $0 + $1.effectiveDuration }
    }

    public var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Active Tasks
                ForEach(activeTasks) { task in
                    TaskRowView(task: task, project: project) {
                        taskToDelete = task
                        isDeleteTaskAlertPresented = true
                    }
                }

                // Collapsible Completed Group (D-06)
                if !completedTasks.isEmpty {
                    DisclosureGroup(isExpanded: $isCompletedGroupExpanded) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            ForEach(completedTasks) { task in
                                TaskRowView(task: task, project: project) {
                                    taskToDelete = task
                                    isDeleteTaskAlertPresented = true
                                }
                            }
                        }
                        .padding(.top, 4)
                    } label: {
                        Text("Completed (\(completedTasks.count))")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                }

                // Inline Quick-Add Task Row (D-05)
                InlineTaskAddRow(projectId: project.id)
                    .padding(.top, AppSpacing.xs)
            }
            .padding(.leading, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                // Project Color Dot (D-10, D-11)
                Circle()
                    .fill(project.isArchived ? Color.secondary.opacity(0.6) : Color(hex: project.colorHex))
                    .frame(width: 10, height: 10)

                // Project Name
                Text(project.name)
                    .font(AppTypography.heading)
                    .foregroundStyle(project.isArchived ? .secondary : .primary)

                // Client Badge (D-10)
                if let clientName = clientName {
                    Text(clientName)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                }

                // Archived Badge (D-11)
                if project.isArchived {
                    Text("Archived")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                }

                Spacer()

                // Metrics
                HStack(spacing: AppSpacing.sm) {
                    if !projectTasks.isEmpty {
                        Text("\(activeTasks.count) tasks")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

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

                // Hover Actions Container (D-02)
                HStack(spacing: AppSpacing.xs) {
                    Button {
                        isExpanded = true
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "plus")
                            Text("Task")
                        }
                        .font(AppTypography.caption)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                    .help("Add task to project")

                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help("Edit project")
                }
                .opacity(isHovered ? 1.0 : 0.0)
            }
            .frame(minHeight: 40)
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
                isExpanded = true
            } label: {
                Label("Add Task", systemImage: "plus")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit Project...", systemImage: "pencil")
            }

            Button {
                onViewEntries?(.project(project.id))
            } label: {
                Label("View Entries", systemImage: "clock")
            }

            Divider()

            Button {
                project.isArchived.toggle()
                store.saveProject(project)
            } label: {
                Label(project.isArchived ? "Unarchive Project" : "Archive Project",
                      systemImage: project.isArchived ? "tray.and.arrow.up" : "archivebox")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Project...", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete Task “\(taskToDelete?.name ?? "")”?",
            isPresented: $isDeleteTaskAlertPresented,
            titleVisibility: .visible,
            presenting: taskToDelete
        ) { task in
            Button("Delete Task", role: .destructive) {
                store.deleteTask(id: task.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: { task in
            Text("Deleting this task will unlink it from all associated time entries. Logged time and project associations will be preserved.")
        }
    }
}
