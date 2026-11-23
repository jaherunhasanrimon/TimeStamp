import SwiftUI

public struct ProjectsListView: View {
    public enum SegmentFilter: String, CaseIterable, Identifiable {
        case active = "Active"
        case archived = "Archived"

        public var id: String { rawValue }
    }

    public var onViewEntries: ((EntryFilter) -> Void)? = nil

    @Environment(PersistenceStore.self) private var store

    @State private var searchText: String = ""
    @State private var selectedSegment: SegmentFilter = .active
    @State private var isCreateSheetPresented: Bool = false
    @State private var projectToEdit: Project? = nil
    @State private var projectToDelete: Project? = nil
    @State private var isDeleteAlertPresented: Bool = false

    public init(onViewEntries: ((EntryFilter) -> Void)? = nil) {
        self.onViewEntries = onViewEntries
    }

    private var filteredProjects: [Project] {
        let isArchivedTarget = (selectedSegment == .archived)
        let segmentMatched = store.projects.filter { $0.isArchived == isArchivedTarget }

        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else {
            return segmentMatched.sorted { $0.createdAt < $1.createdAt }
        }

        return segmentMatched.filter { project in
            if project.name.lowercased().contains(query) {
                return true
            }
            if let clientId = project.clientId,
               let client = store.clients.first(where: { $0.id == clientId }),
               client.name.lowercased().contains(query) {
                return true
            }
            let childTasks = store.tasks.filter { $0.projectId == project.id }
            return childTasks.contains { $0.name.lowercased().contains(query) }
        }
        .sorted { $0.createdAt < $1.createdAt }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // View Toolbar (D-04)
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Projects")
                        .font(AppTypography.heading)
                        .foregroundStyle(.primary)

                    Text("\(store.projects.count) projects")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Search Bar
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))

                    TextField("Search projects...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(AppTypography.body)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 5)
                .frame(width: 180)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))

                // Segmented Picker [Active | Archived] (D-04)
                Picker("", selection: $selectedSegment) {
                    ForEach(SegmentFilter.allCases) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)

                // + New Project Button (D-04)
                Button {
                    isCreateSheetPresented = true
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "plus")
                        Text("New Project")
                    }
                    .font(AppTypography.label)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.brandAccent)
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .help("Create new project (⌘⇧P)")
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.background)

            Divider()

            // Project List or Empty State
            if filteredProjects.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(filteredProjects) { project in
                            ProjectRowView(
                                project: project,
                                onEdit: {
                                    projectToEdit = project
                                },
                                onDelete: {
                                    projectToDelete = project
                                    isDeleteAlertPresented = true
                                },
                                onViewEntries: onViewEntries
                            )
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
        .background(AppColors.background)
        .sheet(isPresented: $isCreateSheetPresented) {
            ProjectEditorSheet(mode: .create())
        }
        .sheet(item: $projectToEdit) { project in
            ProjectEditorSheet(mode: .edit(project))
        }
        .confirmationDialog(
            "Delete Project “\(projectToDelete?.name ?? "")”?",
            isPresented: $isDeleteAlertPresented,
            titleVisibility: .visible,
            presenting: projectToDelete
        ) { project in
            Button("Delete Project", role: .destructive) {
                store.deleteProject(id: project.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: { project in
            Text("Deleting this project will permanently remove its child tasks and unlink all associated time entries. Logged time will be preserved.")
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Image(systemName: selectedSegment == .active ? "folder.badge.plus" : "archivebox")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppColors.brandAccent.opacity(0.8))

            Text(selectedSegment == .active ? "No active projects" : "No archived projects")
                .font(AppTypography.subheading)
                .foregroundStyle(.primary)

            Text(searchText.isEmpty
                 ? (selectedSegment == .active ? "Create projects to categorize your time entries and tasks." : "Archived projects will appear here.")
                 : "No projects match “\(searchText)”.")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            if selectedSegment == .active && searchText.isEmpty {
                Button("+ New Project") {
                    isCreateSheetPresented = true
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.brandAccent)
                .padding(.top, AppSpacing.xs)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
    }
}
