import SwiftUI

public struct TaskRowView: View {
    public let task: Task
    public let project: Project
    public let onDelete: () -> Void

    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    @State private var isHovered: Bool = false

    public init(task: Task, project: Project, onDelete: @escaping () -> Void) {
        self.task = task
        self.project = project
        self.onDelete = onDelete
    }

    private var trackedDuration: TimeInterval {
        store.timeEntries
            .filter { $0.taskId == task.id }
            .reduce(0) { $0 + $1.effectiveDuration }
    }

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Checkbox
            Button {
                toggleTaskCompletion()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(task.isCompleted ? AppColors.brandAccent : .secondary)
            }
            .buttonStyle(.plain)
            .help(task.isCompleted ? "Mark as active" : "Mark as completed")

            // Task Name
            Text(task.name)
                .font(AppTypography.body)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .strikethrough(task.isCompleted, color: .secondary)

            Spacer()

            // Metrics / Duration
            if trackedDuration > 0 {
                Text(DateHelper.formatHumanDuration(trackedDuration))
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
            }

            // Hover Action Container
            HStack(spacing: AppSpacing.xs) {
                // Play / Track Button
                Button {
                    startTracking()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.brandAccent)
                        .frame(width: 22, height: 22)
                        .background(AppColors.brandAccent.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Track time on this task")

                // Delete Button
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Delete task")
            }
            .opacity(isHovered ? 1.0 : 0.0)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 4)
        .frame(minHeight: 32)
        .background(isHovered ? Color.secondary.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button {
                startTracking()
            } label: {
                Label("Start Timer", systemImage: "play.fill")
            }

            Button {
                toggleTaskCompletion()
            } label: {
                Label(task.isCompleted ? "Mark as Active" : "Mark as Completed",
                      systemImage: task.isCompleted ? "circle" : "checkmark.circle")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }

    private func toggleTaskCompletion() {
        task.isCompleted.toggle()
        store.saveTask(task)
    }

    private func startTracking() {
        if task.isCompleted {
            task.isCompleted = false
            store.saveTask(task)
        }
        timerManager.start(description: task.name, projectId: project.id, taskId: task.id)
    }
}
