import SwiftUI

public struct ProjectTaskPickerButton: View {
    @Environment(PersistenceStore.self) private var store

    @Binding public var selectedProjectId: UUID?
    @Binding public var selectedTaskId: UUID?

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
        Menu {
            // Option to deselect project
            Button {
                selectedProjectId = nil
                selectedTaskId = nil
            } label: {
                Label("No Project", systemImage: "xmark")
            }

            if !store.projects.isEmpty {
                Divider()

                ForEach(store.projects) { project in
                    let tasks = store.tasks.filter { $0.projectId == project.id && !$0.isCompleted }

                    if tasks.isEmpty {
                        Button {
                            selectedProjectId = project.id
                            selectedTaskId = nil
                        } label: {
                            Text(project.name)
                        }
                    } else {
                        Menu(project.name) {
                            Button("Project only (\(project.name))") {
                                selectedProjectId = project.id
                                selectedTaskId = nil
                            }

                            Divider()

                            ForEach(tasks) { task in
                                Button(task.name) {
                                    selectedProjectId = project.id
                                    selectedTaskId = task.id
                                }
                            }
                        }
                    }
                }
            }
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
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
