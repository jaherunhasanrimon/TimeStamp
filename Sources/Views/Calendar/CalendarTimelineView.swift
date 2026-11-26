import SwiftUI

private struct CalendarSlotDraft: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
}

public struct CalendarTimelineView: View {
    public enum CalendarViewMode: String, CaseIterable, Identifiable {
        case day = "Day"
        case week = "Week"

        public var id: String { rawValue }
    }

    @Environment(PersistenceStore.self) private var store
    @AppStorage("calendarSnapMinutes") private var snapMinutes: Int = 15
    @AppStorage("showAppleCalendarOverlay") private var showAppleCalendarOverlay: Bool = false

    @State private var selectedMode: CalendarViewMode = .week
    @State private var selectedDate: Date = Date()
    @State private var entryToEdit: TimeEntry? = nil
    @State private var draftToCreate: CalendarSlotDraft? = nil
    @State private var calendarService = AppleCalendarService.shared

    public init() {}

    private var weekStartDate: Date {
        DateHelper.startOfWeek(for: selectedDate)
    }

    private var weekEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate) ?? selectedDate
    }

    private var dateRangeTitle: String {
        let df = DateFormatter()
        if selectedMode == .day {
            df.dateFormat = "EEEE, MMM d, yyyy"
            return df.string(from: selectedDate)
        } else {
            let start = weekStartDate
            let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
            let startFmt = DateFormatter()
            startFmt.dateFormat = "MMM d"
            let endFmt = DateFormatter()
            endFmt.dateFormat = "MMM d, yyyy"
            return "\(startFmt.string(from: start)) – \(endFmt.string(from: end))"
        }
    }

    private var totalSelectedDuration: TimeInterval {
        let calendar = Calendar.current
        if selectedMode == .day {
            let start = calendar.startOfDay(for: selectedDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? selectedDate
            return store.timeEntries
                .filter { $0.startDate >= start && $0.startDate < end && $0.endDate != nil }
                .reduce(0) { $0 + $1.effectiveDuration }
        } else {
            let start = weekStartDate
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
            return store.timeEntries
                .filter { $0.startDate >= start && $0.startDate < end && $0.endDate != nil }
                .reduce(0) { $0 + $1.effectiveDuration }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar Header
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateRangeTitle)
                        .font(AppTypography.heading)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text("Total: \(TimeCalculator.formatCompactDuration(totalSelectedDuration))")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                        Text("• Double-click empty slot to create • Drag blocks to move/resize")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.8))
                    }
                }

                Spacer()

                // Snap Interval Selector
                Picker("Snap", selection: $snapMinutes) {
                    Text("1m snap").tag(1)
                    Text("5m snap").tag(5)
                    Text("15m snap").tag(15)
                    Text("30m snap").tag(30)
                }
                .labelsHidden()
                .frame(width: 96)
                .help("Snap increment when dragging or creating calendar blocks")

                // Opt-in Apple Calendar Overlay Toggle
                Button {
                    showAppleCalendarOverlay.toggle()
                    if showAppleCalendarOverlay {
                        _Concurrency.Task {
                            await calendarService.requestAccessAndLoad(from: weekStartDate, to: weekEndDate)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showAppleCalendarOverlay ? "calendar.badge.checkmark" : "calendar")
                            .font(.system(size: 11))
                        Text("Apple Cal")
                            .font(AppTypography.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(showAppleCalendarOverlay ? AppColors.togglMagenta.opacity(0.16) : Color.secondary.opacity(0.1))
                    .foregroundStyle(showAppleCalendarOverlay ? AppColors.togglMagenta : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Overlay local macOS Apple Calendar events (read-only). Google/Outlook require external OAuth.")

                // Navigation Controls: < Today >
                HStack(spacing: 4) {
                    Button { stepDate(by: -1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    Button("Today") {
                        selectedDate = Date()
                        refreshOverlayIfEnabled()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button { stepDate(by: 1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                // Segmented Picker [Day | Week]
                Picker("", selection: $selectedMode) {
                    ForEach(CalendarViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            Divider()

            // Timeline Content
            if selectedMode == .day {
                DayTimelineGridView(
                    selectedDate: selectedDate,
                    snapMinutes: snapMinutes,
                    showAppleCalendarOverlay: showAppleCalendarOverlay && calendarService.isAuthorized,
                    appleCalendarEvents: calendarService.events,
                    onSelectEntry: { entry in
                        entryToEdit = entry
                    },
                    onCreateAtDate: { clickedStart in
                        draftToCreate = CalendarSlotDraft(
                            startDate: clickedStart,
                            endDate: clickedStart.addingTimeInterval(Double(max(15, snapMinutes)) * 60.0)
                        )
                    }
                )
            } else {
                WeekTimelineGridView(
                    weekStartDate: weekStartDate,
                    snapMinutes: snapMinutes,
                    showAppleCalendarOverlay: showAppleCalendarOverlay && calendarService.isAuthorized,
                    appleCalendarEvents: calendarService.events,
                    onSelectEntry: { entry in
                        entryToEdit = entry
                    },
                    onCreateAtDate: { clickedStart in
                        draftToCreate = CalendarSlotDraft(
                            startDate: clickedStart,
                            endDate: clickedStart.addingTimeInterval(Double(max(15, snapMinutes)) * 60.0)
                        )
                    }
                )
            }
        }
        .background(AppColors.background)
        .onAppear {
            refreshOverlayIfEnabled()
        }
        .sheet(item: $entryToEdit) { entry in
            EntryEditSheet(mode: .edit(entry))
        }
        .sheet(item: $draftToCreate) { draft in
            CalendarQuickCreateSheet(initialStart: draft.startDate, initialEnd: draft.endDate)
        }
    }

    private func stepDate(by offset: Int) {
        let days = selectedMode == .day ? offset : offset * 7
        if let updated = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = updated
            refreshOverlayIfEnabled()
        }
    }

    private func refreshOverlayIfEnabled() {
        guard showAppleCalendarOverlay else { return }
        calendarService.loadEvents(from: weekStartDate, to: weekEndDate)
    }
}

private struct CalendarQuickCreateSheet: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var entryDescription: String = ""
    @State private var selectedProjectId: UUID? = nil
    @State private var selectedTaskId: UUID? = nil
    @State private var selectedTagIds: [UUID] = []
    @State private var isBillable: Bool = false
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isTagPopoverPresented: Bool = false

    init(initialStart: Date, initialEnd: Date) {
        _startDate = State(initialValue: initialStart)
        _endDate = State(initialValue: initialEnd)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("New Calendar Time Entry")
                .font(AppTypography.heading)

            TextField("What did you work on?", text: $entryDescription)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: AppSpacing.sm) {
                ProjectTaskPickerButton(
                    selectedProjectId: $selectedProjectId,
                    selectedTaskId: $selectedTaskId
                )

                Button {
                    isTagPopoverPresented.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                        Text(selectedTagIds.isEmpty ? "Tags" : "\(selectedTagIds.count) tags")
                    }
                    .font(AppTypography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AppColors.secondaryCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isTagPopoverPresented) {
                    TagPickerPopover(selectedTagIds: $selectedTagIds) {
                        isTagPopoverPresented = false
                    }
                }

                Spacer()

                Toggle("Billable", isOn: $isBillable)
                    .toggleStyle(.checkbox)
            }

            HStack(spacing: AppSpacing.md) {
                DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                Text("to")
                    .foregroundStyle(.secondary)
                DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Create Entry") {
                    let resolvedEnd = max(startDate.addingTimeInterval(60), endDate)
                    let entry = TimeEntry(
                        entryDescription: entryDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                        startDate: startDate,
                        endDate: resolvedEnd,
                        accumulatedDuration: resolvedEnd.timeIntervalSince(startDate),
                        projectId: selectedProjectId,
                        taskId: selectedTaskId,
                        tagIds: selectedTagIds,
                        isBillable: isBillable
                    )
                    store.saveTimeEntry(entry)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.brandAccent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppSpacing.lg)
        .frame(width: 440)
        .background(AppColors.background)
        .onChange(of: selectedProjectId) { _, newId in
            if let pId = newId, store.project(for: pId)?.isBillableDefault == true {
                isBillable = true
            }
        }
    }
}
