import SwiftUI

public struct ProjectTaskPickerButton: View {
    @Environment(PersistenceStore.self) private var store

    @Binding public var selectedProjectId: UUID?
    @Binding public var selectedTaskId: UUID?
    @State private var isPopoverPresented: Bool = false

    public init(selectedProjectId: Binding<UUID?>, selectedTaskId: Binding<UUID?>) {
        self._selectedProjectId = selectedProjectId
        self._selectedTaskId = selectedTaskId
    }

    private var selectedProject: Project? {
        guard let id = selectedProjectId else { return nil }
        return store.projects.first(where: { $0.id == id })
    }

    private var selectedTask: Task? {
        guard let id = selectedTaskId else { return nil }
        return store.tasks.first(where: { $0.id == id })
    }

    public var body: some View {
        Button {
            isPopoverPresented.toggle()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if let project = selectedProject {
                    Circle()
                        .fill(Color(hex: project.colorHex))
                        .frame(width: 8, height: 8)

                    Text(project.name)
                        .font(AppTypography.label)
                        .foregroundStyle(.primary)

                    if let task = selectedTask {
                        Text("•")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                        Text(task.name)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "folder")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("Add Project")
                        .font(AppTypography.label)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 5)
            .background(AppColors.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusSmall)
                    .stroke(AppColors.subtleBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
            ProjectPickerPopover(
                selectedProjectId: $selectedProjectId,
                selectedTaskId: $selectedTaskId,
                onDismiss: { isPopoverPresented = false }
            )
        }
    }
}
