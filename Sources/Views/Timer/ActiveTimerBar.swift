import SwiftUI

/// Toggl Track Authentic Two-Row Active Timer Bar (Reference: toggl_macos_main_empty.jpg, toggl_macos_autocomplete.jpg).
/// Supports Timer Mode vs Inline Manual Entry Mode (⌘D), live Description Autocomplete,
/// `@` Project trigger, `#` Tag trigger, Default Project, and Pomodoro / Running Edit sheets.
public struct ActiveTimerBar: View {
    @Environment(TimerManager.self) private var timerManager
    @Environment(PersistenceStore.self) private var store
    @Environment(PomodoroManager.self) private var pomodoroManager
    @Environment(\.openWindow) private var openWindow

    @AppStorage("defaultProjectId") private var defaultProjectIdString: String = ""

    @State private var descriptionText: String = ""
    @State private var selectedProjectId: UUID?
    @State private var selectedTaskId: UUID?
    @State private var selectedTagIds: [UUID] = []
    @State private var isBillable: Bool = false

    @State private var isProjectPickerPresented: Bool = false
    @State private var isTagPickerPresented: Bool = false
    @State private var isPomodoroPopoverPresented: Bool = false
    @State private var isManualLogSheetPresented: Bool = false
    @State private var entryForQuickEdit: TimeEntry? = nil

    // Inline Manual Mode state (Cmd+D)
    @State private var isManualMode: Bool = false
    @State private var manualDate: Date = Date()
    @State private var manualStartTime: Date = Date().addingTimeInterval(-1800)
    @State private var manualEndTime: Date = Date()

    // Autocomplete state
    @FocusState private var isDescriptionFocused: Bool
    @State private var showAutocomplete: Bool = false
    @State private var autocompleteIndex: Int = 0
    @State private var suppressAutocompleteOnce: Bool = false

    public init() {}

    private var selectedProject: Project? {
        guard let id = selectedProjectId else { return nil }
        return store.projects.first(where: { $0.id == id && !$0.isArchived })
    }

    private var selectedTask: Task? {
        guard let id = selectedTaskId else { return nil }
        return store.tasks.first(where: { $0.id == id })
    }

    private var autocompleteSuggestions: (entries: [TimeEntry], projects: [Project]) {
        AutocompletePopoverView.buildSuggestions(query: descriptionText, store: store)
    }

    private var totalAutocompleteCount: Int {
        autocompleteSuggestions.entries.count + autocompleteSuggestions.projects.count
    }

    public var body: some View {
        VStack(spacing: 8) {
            // ROW 1: Pomodoro Icon + Description Field + Duration / Manual Times + Action + Stacked Mode Toggles
            HStack(spacing: 10) {
                // Tomato Pomodoro Icon Button
                Button(action: {
                    isPomodoroPopoverPresented.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(pomodoroManager.isRunning ? AppColors.togglMagenta.opacity(0.18) : AppColors.insetBackground)
                            .frame(width: 28, height: 28)

                        Circle()
                            .stroke(
                                pomodoroManager.isRunning
                                    ? (pomodoroManager.sessionType == .work ? AppColors.togglMagenta : AppColors.success)
                                    : AppColors.border.opacity(0.8),
                                lineWidth: pomodoroManager.isRunning ? 1.5 : 1.0
                            )
                            .frame(width: 28, height: 28)

                        Text("🍅")
                            .font(.system(size: 13))
                    }
                }
                .buttonStyle(.plain)
                .help(pomodoroManager.isRunning
                      ? "Pomodoro: \(pomodoroManager.formattedRemainingTime) (\(pomodoroManager.sessionType.rawValue))"
                      : "Pomodoro Focus Timer")
                .popover(isPresented: $isPomodoroPopoverPresented, arrowEdge: .bottom) {
                    PomodoroPopoverView(onDismiss: {
                        isPomodoroPopoverPresented = false
                    })
                }

                // Borderless Description Field (with @ and # triggers + Autocomplete)
                TextField(isManualMode ? "What have you done?" : "What are you working on?", text: $descriptionText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($isDescriptionFocused)
                    .onSubmit {
                        handleReturnKey()
                    }
                    .onKeyPress(.downArrow) {
                        guard showAutocomplete, totalAutocompleteCount > 0 else { return .ignored }
                        autocompleteIndex = (autocompleteIndex + 1) % totalAutocompleteCount
                        return .handled
                    }
                    .onKeyPress(.upArrow) {
                        guard showAutocomplete, totalAutocompleteCount > 0 else { return .ignored }
                        autocompleteIndex = (autocompleteIndex - 1 + totalAutocompleteCount) % totalAutocompleteCount
                        return .handled
                    }
                    .onKeyPress(.escape) {
                        if showAutocomplete {
                            showAutocomplete = false
                            return .handled
                        }
                        return .ignored
                    }
                    .onChange(of: descriptionText) { oldVal, newVal in
                        handleDescriptionChange(oldVal: oldVal, newVal: newVal)
                    }

                Spacer(minLength: 8)

                if isManualMode {
                    // Compact Inline Manual Entry Controls
                    HStack(spacing: 6) {
                        DatePicker("", selection: $manualStartTime, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .frame(width: 68)

                        Text("–")
                            .foregroundStyle(.secondary)

                        DatePicker("", selection: $manualEndTime, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .frame(width: 68)

                        Button(action: saveInlineManualEntry) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.togglMagenta)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Save manual entry (Return) or open full dialog")
                        .contextMenu {
                            Button("Open Full Manual Entry Sheet...") {
                                isManualLogSheetPresented = true
                            }
                        }
                    }
                } else {
                    // Compact H:MM:SS Ticker matching Toggl Track macOS (0:00:00)
                    Text(timerManager.compactFormattedDuration)
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(timerManager.isRunning ? Color.primary : .secondary)

                    // Circular Magenta Start/Stop Button (#E54583 / #FF453A)
                    CircularPlayButton(
                        isRunning: timerManager.isRunning,
                        isPaused: timerManager.isPaused,
                        onToggle: {
                            if timerManager.isRunning || timerManager.isPaused {
                                stopTimer()
                            } else {
                                startTimer()
                            }
                        },
                        onPauseToggle: (timerManager.isRunning || timerManager.isPaused) ? togglePause : nil
                    )
                }

                // Vertical Stacked Mode Switcher matching Reference Screenshot 1 (Timer Play / + Manual)
                VStack(spacing: 4) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isManualMode = false
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(!isManualMode ? AppColors.secondaryCardBackground : Color.clear)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(!isManualMode ? AppColors.border : Color.secondary.opacity(0.35), lineWidth: 1)
                                )
                            Image(systemName: "play.fill")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(!isManualMode ? Color.primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Timer Mode (⌘D)")

                    Button(action: {
                        if isManualMode {
                            isManualLogSheetPresented = true
                        } else {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                manualEndTime = Date()
                                manualStartTime = Date().addingTimeInterval(-1800)
                                isManualMode = true
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(isManualMode ? AppColors.togglMagenta.opacity(0.22) : AppColors.secondaryCardBackground)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(isManualMode ? AppColors.togglMagenta : AppColors.border, lineWidth: 1)
                                )
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(isManualMode ? AppColors.togglMagenta : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Manual Entry Mode (⌘D). Click again for full date/time sheet.")
                }
            }

            // ROW 2: Sub-toolbar containing 📁 Folder / Project Pill, 🏷️ Tags, 💲 Billable, and Favorites
            HStack(spacing: 10) {
                // 📁 Project / Task Picker Button (Screenshot 5 pill style when selected)
                HStack(spacing: 4) {
                    Button(action: {
                        isProjectPickerPresented.toggle()
                    }) {
                        HStack(spacing: 5) {
                            if let project = selectedProject {
                                Circle()
                                    .fill(Color(hex: project.colorHex))
                                    .frame(width: 7, height: 7)

                                Text(project.name)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundStyle(Color(hex: project.colorHex))
                                    .lineLimit(1)

                                if let task = selectedTask {
                                    Text("• \(task.name)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            } else {
                                Image(systemName: "folder")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    if selectedProject != nil {
                        Button(action: {
                            selectedProjectId = nil
                            selectedTaskId = nil
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Clear project")
                    }
                }
                .padding(.horizontal, selectedProject != nil ? 8 : 6)
                .padding(.vertical, 3)
                .background(selectedProject != nil ? AppColors.secondaryCardBackground : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .popover(isPresented: $isProjectPickerPresented, arrowEdge: .bottom) {
                    ProjectPickerPopover(
                        selectedProjectId: $selectedProjectId,
                        selectedTaskId: $selectedTaskId,
                        onDismiss: {
                            isProjectPickerPresented = false
                        }
                    )
                }

                // 🏷️ Tag Button
                Button(action: {
                    isTagPickerPresented.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: selectedTagIds.isEmpty ? "tag" : "tag.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(selectedTagIds.isEmpty ? Color.secondary : AppColors.togglMagenta)

                        if !selectedTagIds.isEmpty {
                            Text("\(selectedTagIds.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.togglMagenta)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(!selectedTagIds.isEmpty ? AppColors.togglMagenta.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help(selectedTagIds.isEmpty ? "Add tags (#)" : "\(selectedTagIds.count) tag(s) selected")
                .popover(isPresented: $isTagPickerPresented, arrowEdge: .bottom) {
                    TagPickerPopover(
                        selectedTagIds: $selectedTagIds,
                        onDismiss: {
                            isTagPickerPresented = false
                        }
                    )
                }

                // 💲 Billable Toggle Button
                Button(action: {
                    isBillable.toggle()
                    if let active = timerManager.activeEntry {
                        active.isBillable = isBillable
                        store.saveTimeEntry(active)
                    }
                }) {
                    Text("$")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isBillable ? AppColors.billable : Color.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(isBillable ? AppColors.billable.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help(isBillable ? "Billable entry" : "Non-billable entry")

                // ⭐ Favorites Quick-Start Menu (if favorites exist)
                if !store.favoriteEntries.isEmpty {
                    Menu {
                        ForEach(store.favoriteEntries) { fav in
                            let projName = fav.projectId.flatMap { store.project(for: $0)?.name }
                            Button(action: {
                                timerManager.continueEntry(fav)
                            }) {
                                Text(projName != nil
                                     ? "\(fav.entryDescription.isEmpty ? "(No description)" : fav.entryDescription) • \(projName!)"
                                     : (fav.entryDescription.isEmpty ? "(No description)" : fav.entryDescription))
                            }
                        }
                    } label: {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.goalGold)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                    }
                    .menuStyle(.borderlessButton)
                    .help("Quick-start from Favorite entries")
                }

                Spacer()

                if isManualMode {
                    Button("Full Sheet...") {
                        isManualLogSheetPresented = true
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }

                // Edit & Discard Buttons when timer active
                if timerManager.activeEntry != nil {
                    Button(action: openEditForActiveEntry) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Edit running entry (⌘E)")

                    Button(action: discardTimer) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Discard active timer")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(AppColors.border)
        }
        .overlay(alignment: .topLeading) {
            if showAutocomplete {
                AutocompletePopoverView(
                    query: descriptionText,
                    highlightedIndex: autocompleteIndex,
                    onSelectEntry: { entry in
                        applySuggestedEntry(entry)
                    },
                    onSelectProject: { project, task in
                        applySuggestedProject(project, task: task)
                    },
                    onDismiss: {
                        showAutocomplete = false
                    }
                )
                .offset(x: 48, y: 44)
            }
        }
        .zIndex(50)
        .sheet(isPresented: $isManualLogSheetPresented) {
            EntryEditSheet(mode: .manualLog(initialProjectId: selectedProjectId, initialTaskId: selectedTaskId))
        }
        .sheet(item: $entryForQuickEdit) { entry in
            EntryEditSheet(mode: .edit(entry))
        }
        .onAppear {
            syncFromManager()
        }
        .onChange(of: timerManager.activeEntry) { _, newEntry in
            suppressAutocompleteOnce = true
            if let entry = newEntry {
                descriptionText = entry.entryDescription
                selectedProjectId = entry.projectId
                selectedTaskId = entry.taskId
                selectedTagIds = entry.tagIds
                isBillable = entry.isBillable
            } else {
                descriptionText = ""
                applyDefaultOrRetainedSelection()
            }
            showAutocomplete = false
        }
        .onChange(of: defaultProjectIdString) { _, _ in
            if timerManager.activeEntry == nil {
                applyDefaultOrRetainedSelection()
            }
        }
        .onChange(of: selectedProjectId) { _, newProjectId in
            if let pId = newProjectId, let project = store.project(for: pId), project.isBillableDefault {
                isBillable = true
            }
            if let active = timerManager.activeEntry {
                active.projectId = newProjectId
                store.saveTimeEntry(active)
            }
        }
        .onChange(of: selectedTagIds) { _, newTagIds in
            if let active = timerManager.activeEntry {
                active.tagIds = newTagIds
                store.saveTimeEntry(active)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tsFocusTimerField)) { _ in
            isDescriptionFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .tsToggleManualMode)) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                isManualMode.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tsEditRunningEntry)) { _ in
            openEditForActiveEntry()
        }
    }

    private func handleDescriptionChange(oldVal: String, newVal: String) {
        if suppressAutocompleteOnce {
            suppressAutocompleteOnce = false
            return
        }

        // Check `@` inline project trigger
        if newVal.hasSuffix("@") && newVal.count > oldVal.count {
            descriptionText = String(newVal.dropLast())
            showAutocomplete = false
            isProjectPickerPresented = true
            return
        }

        // Check `#` inline tag trigger
        if newVal.hasSuffix("#") && newVal.count > oldVal.count {
            descriptionText = String(newVal.dropLast())
            showAutocomplete = false
            isTagPickerPresented = true
            return
        }

        // Sync live description to running entry
        if let active = timerManager.activeEntry {
            active.entryDescription = newVal
            active.updatedAt = Date()
            store.saveTimeEntry(active)
        }

        let trimmed = newVal.trimmingCharacters(in: .whitespaces)
        if isDescriptionFocused && !trimmed.isEmpty {
            let count = AutocompletePopoverView.buildSuggestions(query: newVal, store: store)
            showAutocomplete = !(count.entries.isEmpty && count.projects.isEmpty)
            autocompleteIndex = 0
        } else {
            showAutocomplete = false
        }
    }

    private func applySuggestedEntry(_ entry: TimeEntry) {
        suppressAutocompleteOnce = true
        showAutocomplete = false
        descriptionText = entry.entryDescription
        selectedProjectId = entry.projectId
        selectedTaskId = entry.taskId
        selectedTagIds = entry.tagIds
        isBillable = entry.isBillable
        if let active = timerManager.activeEntry {
            active.entryDescription = entry.entryDescription
            active.projectId = entry.projectId
            active.taskId = entry.taskId
            active.tagIds = entry.tagIds
            active.isBillable = entry.isBillable
            store.saveTimeEntry(active)
        }
    }

    private func applySuggestedProject(_ project: Project, task: Task?) {
        showAutocomplete = false
        selectedProjectId = project.id
        selectedTaskId = task?.id
        if project.isBillableDefault {
            isBillable = true
        }
        if descriptionText.lowercased() == project.name.lowercased() ||
            descriptionText.count <= 3 && project.name.lowercased().hasPrefix(descriptionText.lowercased()) {
            suppressAutocompleteOnce = true
            descriptionText = ""
        }
    }

    private func handleReturnKey() {
        if showAutocomplete && totalAutocompleteCount > 0 {
            let suggestions = autocompleteSuggestions
            if autocompleteIndex < suggestions.entries.count {
                applySuggestedEntry(suggestions.entries[autocompleteIndex])
                return
            } else {
                let pIdx = autocompleteIndex - suggestions.entries.count
                if pIdx >= 0 && pIdx < suggestions.projects.count {
                    applySuggestedProject(suggestions.projects[pIdx], task: nil)
                    return
                }
            }
        }
        showAutocomplete = false

        if isManualMode {
            saveInlineManualEntry()
        } else if timerManager.isRunning || timerManager.isPaused {
            stopTimer()
        } else {
            startTimer()
        }
    }

    private func syncFromManager() {
        suppressAutocompleteOnce = true
        if let entry = timerManager.activeEntry {
            descriptionText = entry.entryDescription
            selectedProjectId = entry.projectId
            selectedTaskId = entry.taskId
            selectedTagIds = entry.tagIds
            isBillable = entry.isBillable
        } else {
            applyDefaultOrRetainedSelection()
        }
    }

    private func applyDefaultOrRetainedSelection() {
        if let defaultUUID = UUID(uuidString: defaultProjectIdString),
           let defaultProj = store.project(for: defaultUUID),
           !defaultProj.isArchived {
            selectedProjectId = defaultProj.id
            selectedTaskId = nil
            isBillable = defaultProj.isBillableDefault
        } else {
            selectedProjectId = timerManager.retainedProjectId
            selectedTaskId = timerManager.retainedTaskId
            isBillable = timerManager.retainedIsBillable
        }
        selectedTagIds = timerManager.retainedTagIds
    }

    private func saveInlineManualEntry() {
        let start = DateHelper.combine(date: manualDate, time: manualStartTime)
        var end = DateHelper.combine(date: manualDate, time: manualEndTime)
        if end <= start {
            end = start.addingTimeInterval(60 * 15)
        }
        let duration = max(0, end.timeIntervalSince(start))
        let entry = TimeEntry(
            entryDescription: descriptionText.trimmingCharacters(in: .whitespaces),
            startDate: start,
            endDate: end,
            accumulatedDuration: duration,
            projectId: selectedProjectId,
            taskId: selectedTaskId,
            tagIds: selectedTagIds,
            isBillable: isBillable
        )
        store.saveTimeEntry(entry)
        suppressAutocompleteOnce = true
        descriptionText = ""
        showAutocomplete = false
        withAnimation(.easeInOut(duration: 0.15)) {
            isManualMode = false
        }
    }

    private func openEditForActiveEntry() {
        if let active = timerManager.activeEntry {
            entryForQuickEdit = active
        } else if let latest = store.timeEntries.filter({ $0.endDate != nil }).sorted(by: { $0.startDate > $1.startDate }).first {
            entryForQuickEdit = latest
        }
    }

    private func startTimer() {
        showAutocomplete = false
        timerManager.start(
            description: descriptionText,
            projectId: selectedProjectId,
            taskId: selectedTaskId,
            tagIds: selectedTagIds,
            isBillable: isBillable
        )
    }

    private func stopTimer() {
        showAutocomplete = false
        _ = timerManager.stop()
        suppressAutocompleteOnce = true
        descriptionText = ""
        applyDefaultOrRetainedSelection()
    }

    private func togglePause() {
        if timerManager.isPaused {
            timerManager.resume()
        } else {
            timerManager.pause()
        }
    }

    private func discardTimer() {
        showAutocomplete = false
        timerManager.discard()
        suppressAutocompleteOnce = true
        descriptionText = ""
        applyDefaultOrRetainedSelection()
    }
}
