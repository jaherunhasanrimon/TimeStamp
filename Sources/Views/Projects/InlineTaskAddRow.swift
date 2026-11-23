import SwiftUI

public struct InlineTaskAddRow: View {
    public let projectId: UUID
    public var onTaskCreated: ((Task) -> Void)? = nil

    @Environment(PersistenceStore.self) private var store
    @State private var taskName: String = ""
    @FocusState private var isFocused: Bool

    public init(projectId: UUID, onTaskCreated: ((Task) -> Void)? = nil) {
        self.projectId = projectId
        self.onTaskCreated = onTaskCreated
    }

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("+ Add task...", text: $taskName)
                .textFieldStyle(.plain)
                .font(AppTypography.body)
                .focused($isFocused)
                .onSubmit {
                    submitTask()
                }
                .onExitCommand {
                    taskName = ""
                    isFocused = false
                }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(Color.secondary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
    }

    private func submitTask() {
        let trimmed = taskName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let task = Task(name: trimmed, isCompleted: false, projectId: projectId)
        store.saveTask(task)
        onTaskCreated?(task)

        taskName = ""
        // Keep focus for rapid multi-task creation
        isFocused = true
    }
}
