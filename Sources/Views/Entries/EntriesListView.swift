import SwiftUI

public struct EntriesListView: View {
    @Binding private var externalFilter: EntryFilter
    @State private var localFilter: EntryFilter = .none
    private let isExternalBinding: Bool
    public let isCompact: Bool

    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    @AppStorage("groupSimilarEntries") private var groupSimilarEntries: Bool = false

    @State private var searchText: String = ""
    @State private var expandedGroupIds: Set<String> = []
    @State public var selectedEntryForEdit: TimeEntry?
    @State public var isLogSheetPresented: Bool = false
    @State private var showUndoToast: Bool = false
    @State private var undoTimerTask: _Concurrency.Task<Void, Never>? = nil

    public init(filter: Binding<EntryFilter>? = nil, isCompact: Bool = false) {
        if let filter = filter {
            self._externalFilter = filter
            self.isExternalBinding = true
        } else {
            self._externalFilter = .constant(.none)
            self.isExternalBinding = false
        }
        self.isCompact = isCompact
    }

    private var activeFilterBinding: Binding<EntryFilter> {
        isExternalBinding ? $externalFilter : $localFilter
    }

    private var currentFilter: EntryFilter {
        activeFilterBinding.wrappedValue
    }

    private var filteredEntries: [TimeEntry] {
        var result = store.timeEntries.filter { $0.endDate != nil }

        switch currentFilter {
        case .none:
            break
        case .project(let projectId):
            result = result.filter { $0.projectId == projectId }
        case .client(let clientId):
            let clientProjectIds = Set(store.projects.filter { $0.clientId == clientId }.map { $0.id })
            result = result.filter { entry in
                guard let pId = entry.projectId else { return false }
                return clientProjectIds.contains(pId)
            }
        case .tag(let tagId):
            result = result.filter { $0.tagIds.contains(tagId) }
        case .billableOnly:
            result = result.filter { $0.isBillable }
        case .nonBillableOnly:
            result = result.filter { !$0.isBillable }
        }

        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            result = result.filter { entry in
                if entry.entryDescription.lowercased().contains(q) { return true }
                if let pId = entry.projectId, let proj = store.project(for: pId) {
                    if proj.name.lowercased().contains(q) { return true }
                    if let cId = proj.clientId, let client = store.client(for: cId),
                       client.name.lowercased().contains(q) { return true }
                }
                for tagId in entry.tagIds {
                    if let tag = store.tags.first(where: { $0.id == tagId }),
                       tag.name.lowercased().contains(q) { return true }
                }
                return false
            }
        }

        return result
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
        case .billableOnly:
            return "Billable Only"
        case .nonBillableOnly:
            return "Non-Billable Only"
        }
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if !isCompact {
                    fullToolbarHeader
                } else if !store.timeEntries.filter({ $0.endDate != nil }).isEmpty {
                    compactFilterStrip
                }

                // Active Filter Pill Bar
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
                    .padding(.horizontal, isCompact ? 0 : AppSpacing.lg)
                    .padding(.bottom, AppSpacing.sm)
                }

                // Favorites Strip when starred items exist
                if !store.favoriteEntries.isEmpty && searchText.isEmpty && currentFilter == .none {
                    favoritesBar
                }

                if !isCompact {
                    Divider()
                }

                // List Content (CompactTrackerView wraps us in its own ScrollView)
                if filteredEntries.isEmpty {
                    emptyStateView
                } else if isCompact {
                    dayGroupsStack
                        .padding(.top, 4)
                } else {
                    ScrollView {
                        dayGroupsStack
                            .padding(AppSpacing.lg)
                    }
                }
            }
            .background(AppColors.background)

            // Non-blocking Undo Delete Toast
            if showUndoToast, let deleted = store.lastDeletedEntry {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Deleted “\(deleted.entryDescription.isEmpty ? "Time entry" : deleted.entryDescription)”")
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                    Button("Undo") {
                        performUndoDelete()
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.togglMagenta)
                    .buttonStyle(.plain)

                    Button {
                        withAnimation { showUndoToast = false }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.secondaryCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: 4)
                .padding(.horizontal, isCompact ? 4 : 24)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $selectedEntryForEdit) { entry in
            EntryEditSheet(mode: .edit(entry))
        }
    }

    @ViewBuilder
    private var fullToolbarHeader: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Time Entries")
                    .font(AppTypography.heading)
                    .foregroundStyle(.primary)

                Text("\(filteredEntries.count) logged sessions\(currentFilter != .none || !searchText.isEmpty ? " (filtered)" : "")")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Search Bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextField("Search entries...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(AppTypography.body)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(width: 190)
            .background(AppColors.insetBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusSmall)
                    .stroke(AppColors.border, lineWidth: 0.8)
            )

            // Group Similar Toggle
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    groupSimilarEntries.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: groupSimilarEntries ? "rectangle.stack.fill" : "rectangle.stack")
                        .font(.system(size: 11))
                    Text("Group")
                        .font(AppTypography.label)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(groupSimilarEntries ? AppColors.togglMagenta.opacity(0.14) : AppColors.secondaryCardBackground)
                .foregroundStyle(groupSimilarEntries ? AppColors.togglMagenta : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
            }
            .buttonStyle(.plain)
            .help("Group similar time entries on the same day")

            filterMenu

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
            .help("Log past time")
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
    }

    @ViewBuilder
    private var compactFilterStrip: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11.5))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.insetBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Button {
                groupSimilarEntries.toggle()
            } label: {
                Image(systemName: groupSimilarEntries ? "rectangle.stack.fill" : "rectangle.stack")
                    .font(.system(size: 11))
                    .foregroundStyle(groupSimilarEntries ? AppColors.togglMagenta : .secondary)
                    .padding(6)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .help("Group similar entries")

            filterMenu
        }
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var filterMenu: some View {
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

            Divider()
            Text("Billable")
            Button {
                activeFilterBinding.wrappedValue = .billableOnly
            } label: {
                if currentFilter == .billableOnly {
                    Label("Billable Only", systemImage: "checkmark")
                } else {
                    Text("Billable Only")
                }
            }
            Button {
                activeFilterBinding.wrappedValue = .nonBillableOnly
            } label: {
                if currentFilter == .nonBillableOnly {
                    Label("Non-Billable Only", systemImage: "checkmark")
                } else {
                    Text("Non-Billable Only")
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
                    .foregroundStyle(currentFilter == .none ? Color.primary : AppColors.togglMagenta)
                if !isCompact {
                    Text("Filter")
                }
            }
            .font(AppTypography.label)
        }
        .menuStyle(.borderedButton)
    }

    @ViewBuilder
    private var favoritesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.goalGold)
                    Text("FAVORITES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }

                ForEach(store.favoriteEntries) { fav in
                    let proj = fav.projectId.flatMap { store.project(for: $0) }
                    Button {
                        timerManager.continueEntry(fav)
                    } label: {
                        HStack(spacing: 5) {
                            if let p = proj {
                                Circle()
                                    .fill(Color(hex: p.colorHex))
                                    .frame(width: 6, height: 6)
                            }
                            Text(fav.entryDescription.isEmpty ? (proj?.name ?? "Favorite") : fav.entryDescription)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)
                            Image(systemName: "play.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(AppColors.togglMagenta)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.cardBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AppColors.border, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, isCompact ? 0 : AppSpacing.lg)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private var dayGroupsStack: some View {
        LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
            ForEach(dayGroups) { group in
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    DayGroupHeaderView(date: group.date, totalDuration: group.totalDuration)

                    if groupSimilarEntries {
                        let groupedItems = EntryGroupingHelper.groupSimilar(group.entries)
                        VStack(spacing: AppSpacing.xs) {
                            ForEach(groupedItems) { item in
                                if item.isGroup {
                                    groupedEntryRow(item: item)
                                } else {
                                    entryRowView(for: item.representative)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: AppSpacing.xs) {
                            ForEach(group.entries) { entry in
                                entryRowView(for: entry)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func entryRowView(for entry: TimeEntry) -> some View {
        TimeEntryRowView(
            entry: entry,
            onEdit: {
                selectedEntryForEdit = entry
            },
            onDelete: {
                deleteWithUndo(entry: entry)
            }
        )
    }

    @ViewBuilder
    private func groupedEntryRow(item: GroupedEntryItem) -> some View {
        let isExpanded = expandedGroupIds.contains(item.id)
        let rep = item.representative
        let project = rep.projectId.flatMap { store.project(for: $0) }
        let client = project?.clientId.flatMap { store.client(for: $0) }

        VStack(spacing: 2) {
            HStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if isExpanded {
                            expandedGroupIds.remove(item.id)
                        } else {
                            expandedGroupIds.insert(item.id)
                        }
                    }
                } label: {
                    Text("\(item.count)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(isExpanded ? Color.white : Color.primary)
                        .frame(width: 22, height: 22)
                        .background(isExpanded ? AppColors.togglMagenta : AppColors.secondaryCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help(isExpanded ? "Collapse group" : "Expand \(item.count) similar entries")

                VStack(alignment: .leading, spacing: 3) {
                    Text(rep.entryDescription.isEmpty ? "(No description)" : rep.entryDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(rep.entryDescription.isEmpty ? .secondary : Color.primary)
                        .lineLimit(1)

                    if let proj = project {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color(hex: proj.colorHex))
                                .frame(width: 7, height: 7)
                            Text(proj.name)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: proj.colorHex))
                            if let client = client {
                                Text("• \(client.name)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                if rep.isBillable {
                    Text("$")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColors.billable)
                }

                Text(TimeCalculator.formatDuration(item.totalDuration))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.primary)

                Button {
                    timerManager.continueEntry(rep)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 22, height: 22)
                        .background(AppColors.togglMagenta)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Continue tracking")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppColors.border.opacity(0.8), lineWidth: 0.8)
            )

            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(item.entries) { subEntry in
                        entryRowView(for: subEntry)
                            .padding(.leading, 18)
                    }
                }
            }
        }
    }

    private func deleteWithUndo(entry: TimeEntry) {
        withAnimation {
            store.deleteTimeEntry(id: entry.id)
            showUndoToast = true
        }
        undoTimerTask?.cancel()
        undoTimerTask = _Concurrency.Task {
            try? await _Concurrency.Task.sleep(for: .seconds(6))
            guard !_Concurrency.Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    showUndoToast = false
                    store.clearUndoBuffer()
                }
            }
        }
    }

    private func performUndoDelete() {
        undoTimerTask?.cancel()
        withAnimation {
            _ = store.undoLastDelete()
            showUndoToast = false
        }
    }

    private var emptyStateView: some View {
        Group {
            if currentFilter != .none || !searchText.isEmpty {
                TogglEmptyStateView(
                    style: .binoculars(
                        title: "No entries found in the selected period",
                        subtitle: "There's no activity matching your current search or filters.",
                        buttonTitle: "Clear filters",
                        onAction: {
                            searchText = ""
                            activeFilterBinding.wrappedValue = .none
                        }
                    )
                )
            } else {
                TogglEmptyStateView(style: .letsGetTracking)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, isCompact ? 16 : 40)
    }
}
