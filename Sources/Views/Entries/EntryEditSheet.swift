import SwiftUI

public enum EntryEditMode: Identifiable {
    case edit(TimeEntry)
    case manualLog(initialProjectId: UUID?, initialTaskId: UUID?)

    public var id: String {
        switch self {
        case .edit(let entry):
            return "edit-\(entry.id.uuidString)"
        case .manualLog(let projectId, let taskId):
            return "manual-\(projectId?.uuidString ?? "none")-\(taskId?.uuidString ?? "none")"
        }
    }
}

public struct EntryEditSheet: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager
    @Environment(\.dismiss) private var dismiss

    public let mode: EntryEditMode

    @State private var descriptionText: String
    @State private var selectedProjectId: UUID?
    @State private var selectedTaskId: UUID?
    @State private var selectedTagIds: [UUID]
    @State private var isBillable: Bool
    @State private var isFavorite: Bool
    @State private var isTagPickerPresented: Bool = false
    @State private var entryDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var durationSeconds: TimeInterval
    @State private var validationError: String?

    public init(mode: EntryEditMode) {
        self.mode = mode

        switch mode {
        case .edit(let entry):
            _descriptionText = State(initialValue: entry.entryDescription)
            _selectedProjectId = State(initialValue: entry.projectId)
            _selectedTaskId = State(initialValue: entry.taskId)
            _selectedTagIds = State(initialValue: entry.tagIds)
            _isBillable = State(initialValue: entry.isBillable)
            _isFavorite = State(initialValue: entry.isFavorite)
            _entryDate = State(initialValue: entry.startDate)
            _startTime = State(initialValue: entry.startDate)
            let effectiveEnd = entry.endDate ?? entry.startDate.addingTimeInterval(max(60, entry.effectiveDuration))
            _endTime = State(initialValue: effectiveEnd)
            _durationSeconds = State(initialValue: max(60, entry.effectiveDuration))

        case .manualLog(let initialProjectId, let initialTaskId):
            let now = Date()
            let hourAgo = now.addingTimeInterval(-3600)
            _descriptionText = State(initialValue: "")
            _selectedProjectId = State(initialValue: initialProjectId)
            _selectedTaskId = State(initialValue: initialTaskId)
            _selectedTagIds = State(initialValue: [])
            _isBillable = State(initialValue: false)
            _isFavorite = State(initialValue: false)
            _entryDate = State(initialValue: now)
            _startTime = State(initialValue: hourAgo)
            _endTime = State(initialValue: now)
            _durationSeconds = State(initialValue: 3600)
        }
    }

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var isEditingActiveTimer: Bool {
        if case .edit(let entry) = mode { return entry.endDate == nil }
        return false
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isEdit ? "Edit Time Entry" : "Log Time Entry")
                        .font(AppTypography.heading)
                        .foregroundStyle(.primary)

                    Text(isEdit ? "Update entry details, duration, or project allocation." : "Record past work with custom date, time, and project.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Form Inputs
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Description field
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Description")
                        .font(AppTypography.label)
                        .foregroundStyle(.secondary)

                    TextField("What did you work on?", text: $descriptionText)
                        .textFieldStyle(.roundedBorder)
                }

                // Project and Task selection
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Project & Task")
                        .font(AppTypography.label)
                        .foregroundStyle(.secondary)

                    HStack {
                        ProjectTaskPickerButton(
                            selectedProjectId: $selectedProjectId,
                            selectedTaskId: $selectedTaskId
                        )
                        Spacer()
                    }
                }

                // Billable, Favorite & Tags
                HStack(spacing: AppSpacing.md) {
                    Toggle(isOn: $isBillable) {
                        HStack(spacing: 4) {
                            Text("$")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isBillable ? AppColors.billable : Color.secondary)
                            Text("Billable")
                                .font(AppTypography.label)
                        }
                    }
                    .toggleStyle(.checkbox)

                    Toggle(isOn: $isFavorite) {
                        HStack(spacing: 4) {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .font(.system(size: 11))
                                .foregroundStyle(isFavorite ? AppColors.goalGold : Color.secondary)
                            Text("Favorite")
                                .font(AppTypography.label)
                        }
                    }
                    .toggleStyle(.checkbox)

                    Spacer()

                    Button(action: {
                        isTagPickerPresented.toggle()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: selectedTagIds.isEmpty ? "tag" : "tag.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(selectedTagIds.isEmpty ? Color.secondary : AppColors.togglMagenta)

                            Text(selectedTagIds.isEmpty ? "Add tags..." : "\(selectedTagIds.count) tag(s)")
                                .font(AppTypography.caption)
                                .foregroundStyle(selectedTagIds.isEmpty ? .secondary : .primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.secondaryCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isTagPickerPresented, arrowEdge: .bottom) {
                        TagPickerPopover(
                            selectedTagIds: $selectedTagIds,
                            onDismiss: { isTagPickerPresented = false }
                        )
                    }
                }

                if !selectedTagIds.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(selectedTagIds, id: \.self) { tagId in
                                if let tag = store.tags.first(where: { $0.id == tagId }) {
                                    HStack(spacing: 4) {
                                        Text("#\(tag.name)")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(Color.white)

                                        Button(action: {
                                            selectedTagIds.removeAll { $0 == tagId }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(Color.white.opacity(0.8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: tag.colorHex).opacity(0.85))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                // Date & Time pickers
                Grid(alignment: .leading, horizontalSpacing: AppSpacing.md, verticalSpacing: AppSpacing.sm) {
                    GridRow {
                        Text("Date")
                            .font(AppTypography.label)
                            .foregroundStyle(.secondary)

                        DatePicker("", selection: $entryDate, displayedComponents: [.date])
                            .labelsHidden()
                    }

                    GridRow {
                        Text("Start Time")
                            .font(AppTypography.label)
                            .foregroundStyle(.secondary)

                        DatePicker("", selection: $startTime, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                    }

                    if !isEditingActiveTimer {
                        GridRow {
                            Text("End Time")
                                .font(AppTypography.label)
                                .foregroundStyle(.secondary)

                            DatePicker("", selection: $endTime, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                        }

                        GridRow {
                            Text("Duration")
                                .font(AppTypography.label)
                                .foregroundStyle(.secondary)

                            HStack(spacing: AppSpacing.sm) {
                                Text(TimeCalculator.formatDuration(durationSeconds))
                                    .font(AppTypography.subTicker)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, 4)
                                    .background(AppColors.secondaryCardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))

                                Button("-15m") {
                                    adjustDuration(by: -15 * 60)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(durationSeconds <= 15 * 60)

                                Button("+15m") {
                                    adjustDuration(by: 15 * 60)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button("+1h") {
                                    adjustDuration(by: 60 * 60)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    } else {
                        GridRow {
                            Text("Status")
                                .font(AppTypography.label)
                                .foregroundStyle(.secondary)

                            Text("Currently running — start time changes adjust elapsed live")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.togglMagenta)
                        }
                    }
                }
            }

            if let error = validationError {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.destructive)
            }

            Divider()

            // Footer Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEdit ? "Save Changes" : "Add Entry") {
                    saveEntry()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.brandAccent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppSpacing.xl)
        .frame(width: 460)
        .background(AppColors.cardBackground)
        // Bidirectional reactive synchronization (D-06, D-08)
        .onChange(of: entryDate) { _, newDate in
            startTime = DateHelper.combine(date: newDate, time: startTime)
            endTime = DateHelper.combine(date: newDate, time: endTime)
        }
        .onChange(of: startTime) { _, newStart in
            let newEnd = newStart.addingTimeInterval(durationSeconds)
            if newEnd != endTime {
                endTime = newEnd
            }
        }
        .onChange(of: endTime) { _, newEnd in
            if newEnd > startTime {
                let computed = newEnd.timeIntervalSince(startTime)
                if abs(computed - durationSeconds) >= 1.0 {
                    durationSeconds = computed
                }
            } else {
                let fixedEnd = startTime.addingTimeInterval(60)
                endTime = fixedEnd
                durationSeconds = 60
            }
        }
        .onChange(of: selectedProjectId) { _, newProjectId in
            if let pId = newProjectId, let project = store.project(for: pId), project.isBillableDefault {
                isBillable = true
            }
        }
    }

    private func adjustDuration(by delta: TimeInterval) {
        let newDuration = max(60, durationSeconds + delta)
        durationSeconds = newDuration
        endTime = startTime.addingTimeInterval(newDuration)
    }

    private func saveEntry() {
        let trimmedDesc = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .edit(let entry):
            entry.entryDescription = trimmedDesc
            entry.projectId = selectedProjectId
            entry.taskId = selectedTaskId
            entry.tagIds = selectedTagIds
            entry.isBillable = isBillable
            entry.isFavorite = isFavorite
            entry.updatedAt = Date()

            if entry.endDate == nil {
                // Preserve running/paused state cleanly without stopping
                entry.startDate = min(startTime, Date())
                store.saveTimeEntry(entry)
                if timerManager.activeEntry?.id == entry.id {
                    timerManager.updateTick()
                }
            } else {
                guard endTime > startTime else {
                    validationError = "End time must be after start time."
                    return
                }
                let duration = max(0, endTime.timeIntervalSince(startTime))
                entry.startDate = startTime
                entry.endDate = endTime
                entry.accumulatedDuration = duration
                entry.isPaused = false
                store.saveTimeEntry(entry)
            }

        case .manualLog:
            guard endTime > startTime else {
                validationError = "End time must be after start time."
                return
            }
            let duration = max(0, endTime.timeIntervalSince(startTime))
            let newEntry = TimeEntry(
                entryDescription: trimmedDesc,
                startDate: startTime,
                endDate: endTime,
                accumulatedDuration: duration,
                isPaused: false,
                createdAt: Date(),
                updatedAt: Date(),
                projectId: selectedProjectId,
                taskId: selectedTaskId,
                tagIds: selectedTagIds,
                isBillable: isBillable,
                isFavorite: isFavorite
            )
            store.saveTimeEntry(newEntry)

            // Retain last selected project/task/tags/billable for chained work
            timerManager.retainedProjectId = selectedProjectId
            timerManager.retainedTaskId = selectedTaskId
            timerManager.retainedTagIds = selectedTagIds
            timerManager.retainedIsBillable = isBillable
        }

        dismiss()
    }
}
