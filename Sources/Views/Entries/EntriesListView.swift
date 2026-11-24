import SwiftUI

public struct EntriesListView: View {
    @Binding private var externalFilter: EntryFilter
    @State private var localFilter: EntryFilter = .none
    private let isExternalBinding: Bool

    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    @State private var entryToDelete: TimeEntry?
    @State private var isDeleteAlertPresented: Bool = false
    @State public var selectedEntryForEdit: TimeEntry?
    @State public var isLogSheetPresented: Bool = false

    public init(filter: Binding<EntryFilter>? = nil) {
        if let filter = filter {
            self._externalFilter = filter
            self.isExternalBinding = true
        } else {
            self._externalFilter = .constant(.none)
            self.isExternalBinding = false
        }
    }

    private var activeFilterBinding: Binding<EntryFilter> {
        if isExternalBinding {
            return $externalFilter
        } else {
            return $localFilter
        }
    }

    private var currentFilter: EntryFilter {
        activeFilterBinding.wrappedValue
    }

    private var filteredEntries: [TimeEntry] {
        switch currentFilter {
        case .none:
            return store.timeEntries
        case .project(let projectId):
            return store.timeEntries.filter { $0.projectId == projectId }
        case .client(let clientId):
            let clientProjectIds = Set(store.projects.filter { $0.clientId == clientId }.map { $0.id })
            return store.timeEntries.filter { entry in
                guard let pId = entry.projectId else { return false }
                return clientProjectIds.contains(pId)
            }
        case .tag(let tagId):
            return store.timeEntries.filter { $0.tagIds.contains(tagId) }
        }
    }

    private var dayGroups: [DayGroup] {
        DateHelper.groupEntriesByDay(filteredEntries)
    }

    private var filterDescription: String {
        switch currentFilter {
        case .none:
            return ""
        case .project(let id):
            let name = store.projects.first(where: { $0.id == id })?.name ?? "Project"
            return "Project: \(name)"
        case .client(let id):
            let name = store.clients.first(where: { $0.id == id })?.name ?? "Client"
            return "Client: \(name)"
        case .tag(let id):
            let name = store.tags.first(where: { $0.id == id })?.name ?? "Tag"
            return "Tag: #\(name)"
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // View Toolbar / Action Header
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time Entries")
                        .font(AppTypography.heading)
                        .foregroundStyle(.primary)

                    Text("\(filteredEntries.count) logged sessions\(currentFilter != .none ? " (filtered)" : "")")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Filter Dropdown Menu (D-16)
                Menu {
                    Button {
                        activeFilterBinding.wrappedValue = .none
                    } label: {
                        if currentFilter == .none {
                            Label("All Entries", systemImage: "checkmark")
                        } else {
                            Text("All Entries")
                        }
                    }

                    if !store.projects.isEmpty {
                        Divider()
                        Text("Projects")
                        ForEach(store.projects.filter { !$0.isArchived }) { project in
                            Button {
                                activeFilterBinding.wrappedValue = .project(project.id)
                            } label: {
                                if currentFilter == .project(project.id) {
                                    Label(project.name, systemImage: "checkmark")
                                } else {
                                    Text(project.name)
                                }
                            }
                        }
                    }

                    if !store.clients.isEmpty {
                        Divider()
                        Text("Clients")
                        ForEach(store.clients) { client in
                            Button {
                                activeFilterBinding.wrappedValue = .client(client.id)
                            } label: {
                                if currentFilter == .client(client.id) {
                                    Label(client.name, systemImage: "checkmark")
                                } else {
                                    Text(client.name)
                                }
                            }
                        }
                    }

                    if !store.tags.isEmpty {
                        Divider()
                        Text("Tags")
                        ForEach(store.tags) { tag in
                            Button {
                                activeFilterBinding.wrappedValue = .tag(tag.id)
                            } label: {
                                if currentFilter == .tag(tag.id) {
                                    Label("#\(tag.name)", systemImage: "checkmark")
                                } else {
                                    Text("#\(tag.name)")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: currentFilter == .none ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        Text("Filter")
                    }
                    .font(AppTypography.label)
                }
                .menuStyle(.borderedButton)

                // Log Time Button
                Button {
                    isLogSheetPresented = true
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "plus")
                        Text("Log Time")
                    }
                    .font(AppTypography.label)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.brandAccent)
                .keyboardShortcut("n", modifiers: .command)
                .help("Log past time (⌘N)")
                .sheet(isPresented: $isLogSheetPresented) {
                    EntryEditSheet(mode: .manualLog(
                        initialProjectId: timerManager.retainedProjectId,
                        initialTaskId: timerManager.retainedTaskId
                    ))
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.background)

            // Active Filter Pill Bar (D-16)
            if currentFilter != .none {
                HStack {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.brandAccent)

                        Text(filterDescription)
                            .font(AppTypography.caption)
                            .foregroundStyle(.primary)

                        Button {
                            activeFilterBinding.wrappedValue = .none
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(2)
                        }
                        .buttonStyle(.plain)
                        .help("Clear filter")
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 3)
                    .background(AppColors.brandAccent.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.sm)
                .background(AppColors.background)
            }

            Divider()

            // List Content
            if filteredEntries.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                        ForEach(dayGroups) { group in
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                DayGroupHeaderView(date: group.date, totalDuration: group.totalDuration)

                                VStack(spacing: AppSpacing.xs) {
                                    ForEach(group.entries) { entry in
                                        TimeEntryRowView(
                                            entry: entry,
                                            onEdit: {
                                                selectedEntryForEdit = entry
                                            },
                                            onDelete: {
                                                entryToDelete = entry
                                                isDeleteAlertPresented = true
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
        .background(AppColors.background)
        .sheet(item: $selectedEntryForEdit) { entry in
            EntryEditSheet(mode: .edit(entry))
        }
        .confirmationDialog(
            "Delete Time Entry?",
            isPresented: $isDeleteAlertPresented,
            titleVisibility: .visible,
            presenting: entryToDelete
        ) { entry in
            Button("Delete", role: .destructive) {
                store.deleteTimeEntry(id: entry.id)
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        } message: { _ in
            Text("Are you sure you want to delete this time entry? This action cannot be undone.")
        }
    }

    private var emptyStateView: some View {
        Group {
            if currentFilter != .none {
                TogglEmptyStateView(
                    style: .binoculars(
                        title: "No entries found in the selected period",
                        subtitle: "There's no activity here matching “\(filterDescription)” — try a different filter or clear filters.",
                        buttonTitle: "Clear filter",
                        onAction: {
                            activeFilterBinding.wrappedValue = .none
                        }
                    )
                )
            } else {
                TogglEmptyStateView(style: .letsGetTracking)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}
