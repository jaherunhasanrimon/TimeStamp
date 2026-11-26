import SwiftUI

/// Search-first project and task selection popover matching Toggl Track (Reference Image 2).
/// Features a green-outlined search bar, "• No Project" option, grouping by client,
/// colored project dots, and a sticky "+ Create project" footer.
public struct ProjectPickerPopover: View {
    @Environment(PersistenceStore.self) private var store

    @Binding public var selectedProjectId: UUID?
    @Binding public var selectedTaskId: UUID?
    public let onDismiss: () -> Void

    @State private var searchText: String = ""
    @State private var isCreatingProject: Bool = false
    @State private var expandedProjectIds: Set<UUID> = []
    @State private var highlightedIndex: Int = -1
    @FocusState private var isSearchFocused: Bool

    public init(
        selectedProjectId: Binding<UUID?>,
        selectedTaskId: Binding<UUID?>,
        onDismiss: @escaping () -> Void
    ) {
        self._selectedProjectId = selectedProjectId
        self._selectedTaskId = selectedTaskId
        self.onDismiss = onDismiss
    }

    private var filteredProjects: [Project] {
        let activeProjects = store.projects.filter { !$0.isArchived }
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty {
            return activeProjects
        }
        return activeProjects.filter { project in
            let matchesProject = project.name.lowercased().contains(query)
            let clientName = project.clientId.flatMap { store.client(for: $0) }?.name.lowercased() ?? ""
            let matchesClient = clientName.contains(query)
            let matchesTask = store.tasks.contains { $0.projectId == project.id && !$0.isCompleted && $0.name.lowercased().contains(query) }
            return matchesProject || matchesClient || matchesTask
        }
    }

    private var orderedVisibleProjects: [Project] {
        projectsWithoutClient + clientsWithProjects.flatMap(\.1)
    }

    private var projectsWithoutClient: [Project] {
        filteredProjects.filter { $0.clientId == nil }
    }

    private var clientsWithProjects: [(Client, [Project])] {
        store.clients.compactMap { client in
            let projects = filteredProjects.filter { $0.clientId == client.id }
            return projects.isEmpty ? nil : (client, projects)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Header with Toggl Green Focus Ring (#36B37E)
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                TextField("Search by project, task or client", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isSearchFocused)
                    .onKeyPress(.downArrow) {
                        let count = orderedVisibleProjects.count
                        if count > 0 {
                            highlightedIndex = min(count - 1, max(0, highlightedIndex + 1))
                        }
                        return .handled
                    }
                    .onKeyPress(.upArrow) {
                        if highlightedIndex > 0 {
                            highlightedIndex -= 1
                        }
                        return .handled
                    }
                    .onKeyPress(.return) {
                        let visible = orderedVisibleProjects
                        if highlightedIndex >= 0 && highlightedIndex < visible.count {
                            let proj = visible[highlightedIndex]
                            selectedProjectId = proj.id
                            selectedTaskId = nil
                            onDismiss()
                            return .handled
                        } else if visible.count == 1, let only = visible.first {
                            selectedProjectId = only.id
                            selectedTaskId = nil
                            onDismiss()
                            return .handled
                        }
                        return .ignored
                    }
                    .onKeyPress(.escape) {
                        onDismiss()
                        return .handled
                    }
            }
            .onAppear {
                isSearchFocused = true
            }
            .onChange(of: searchText) { _, _ in
                highlightedIndex = orderedVisibleProjects.isEmpty ? -1 : 0
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(AppColors.insetBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppColors.focusBorder, lineWidth: 1.5)
            )
            .padding(10)

            Divider()
                .overlay(AppColors.border)

            // Scrollable Selection List
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    // Option: No Project
                    Button(action: {
                        selectedProjectId = nil
                        selectedTaskId = nil
                        onDismiss()
                    }) {
                        HStack(spacing: 8) {
                            Text("•")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.secondary)
                            Text("No Project")
                                .font(.system(size: 12, weight: selectedProjectId == nil ? .semibold : .regular))
                                .foregroundStyle(selectedProjectId == nil ? AppColors.togglMagenta : Color.primary)
                            Spacer()
                            if selectedProjectId == nil {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.togglMagenta)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(selectedProjectId == nil ? AppColors.secondaryCardBackground : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)

                    // NO CLIENT Section
                    if !projectsWithoutClient.isEmpty {
                        Text("NO CLIENT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 2)

                        ForEach(projectsWithoutClient) { project in
                            projectRow(project)
                        }
                    }

                    // Grouped by Clients
                    ForEach(clientsWithProjects, id: \.0.id) { client, projects in
                        Text(client.name.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 2)

                        ForEach(projects) { project in
                            projectRow(project)
                        }
                    }

                    if filteredProjects.isEmpty && !searchText.isEmpty {
                        VStack(spacing: 6) {
                            Text("No matching projects")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 280)

            Divider()
                .overlay(AppColors.border)

            // Sticky Bottom Row: + Create project (with Magenta Plus)
            Button(action: {
                isCreatingProject = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColors.togglMagenta)

                    Text("Create project")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.primary)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppColors.cardBackground)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 360)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .sheet(isPresented: $isCreatingProject) {
            ProjectEditorSheet(mode: .create())
        }
    }

    @ViewBuilder
    private func projectRow(_ project: Project) -> some View {
        let isSelected = selectedProjectId == project.id
        let activeTasks = store.tasks.filter { $0.projectId == project.id && !$0.isCompleted }
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let matchingTasks: [Task] = query.isEmpty ? activeTasks : activeTasks.filter { $0.name.lowercased().contains(query) }
        let hasMatchingTaskSearch = !query.isEmpty && !matchingTasks.isEmpty
        let isTasksExpanded = expandedProjectIds.contains(project.id) || hasMatchingTaskSearch
        let isKeyboardHighlighted = highlightedIndex >= 0 &&
            highlightedIndex < orderedVisibleProjects.count &&
            orderedVisibleProjects[highlightedIndex].id == project.id

        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 6) {
                if !activeTasks.isEmpty {
                    Button(action: {
                        if expandedProjectIds.contains(project.id) {
                            expandedProjectIds.remove(project.id)
                        } else {
                            expandedProjectIds.insert(project.id)
                        }
                    }) {
                        Image(systemName: isTasksExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 14, height: 14)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: {
                    selectedProjectId = project.id
                    selectedTaskId = nil
                    onDismiss()
                }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: project.colorHex))
                            .frame(width: 8, height: 8)

                        Text(project.name)
                            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)

                        Spacer()

                        if !activeTasks.isEmpty {
                            Text("\(activeTasks.count) \(activeTasks.count == 1 ? "task" : "tasks")")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }

                        if isSelected && selectedTaskId == nil {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.togglMagenta)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isKeyboardHighlighted ? AppColors.togglMagenta.opacity(0.18) :
                    (isSelected ? AppColors.secondaryCardBackground : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))

            if isTasksExpanded {
                let tasksToRender = hasMatchingTaskSearch ? matchingTasks : activeTasks
                ForEach(tasksToRender) { task in
                    let isTaskSelected = selectedProjectId == project.id && selectedTaskId == task.id
                    Button(action: {
                        selectedProjectId = project.id
                        selectedTaskId = task.id
                        onDismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checklist")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(task.name)
                                .font(.system(size: 11, weight: isTaskSelected ? .semibold : .regular))
                                .foregroundStyle(isTaskSelected ? AppColors.togglMagenta : Color.primary)
                                .lineLimit(1)
                            Spacer()
                            if isTaskSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(AppColors.togglMagenta)
                            }
                        }
                        .padding(.leading, 30)
                        .padding(.trailing, 12)
                        .padding(.vertical, 4)
                        .background(isTaskSelected ? AppColors.secondaryCardBackground : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
