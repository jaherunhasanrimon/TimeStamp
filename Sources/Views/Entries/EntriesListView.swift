import SwiftUI

public struct EntriesListView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    @State private var entryToDelete: TimeEntry?
    @State private var isDeleteAlertPresented: Bool = false
    @State public var selectedEntryForEdit: TimeEntry?
    @State public var isLogSheetPresented: Bool = false

    public init() {}

    private var dayGroups: [DayGroup] {
        DateHelper.groupEntriesByDay(store.timeEntries)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // View Toolbar / Action Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time Entries")
                        .font(AppTypography.heading)
                        .foregroundStyle(.primary)

                    Text("\(store.timeEntries.count) logged sessions")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

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
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.background)

            Divider()

            // List Content
            if store.timeEntries.isEmpty {
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
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "stopwatch")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppColors.brandAccent)

            Text("No time entries yet")
                .font(AppTypography.heading)

            Text("Start the timer in the top bar or press ⌘N to log past work.")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            Button {
                isLogSheetPresented = true
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "plus")
                    Text("Log Time Entry")
                }
                .font(AppTypography.label)
            }
            .buttonStyle(.bordered)
            .padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xxl)
    }
}
