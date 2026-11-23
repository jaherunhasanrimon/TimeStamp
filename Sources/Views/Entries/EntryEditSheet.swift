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
    }

    private func adjustDuration(by delta: TimeInterval) {
        let newDuration = max(60, durationSeconds + delta)
        durationSeconds = newDuration
        endTime = startTime.addingTimeInterval(newDuration)
    }

    private func saveEntry() {
        guard endTime > startTime else {
            validationError = "End time must be after start time."
            return
        }

        let trimmedDesc = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .edit(let entry):
            entry.entryDescription = trimmedDesc
            entry.projectId = selectedProjectId
            entry.taskId = selectedTaskId
            entry.startDate = startTime
            entry.endDate = endTime
            entry.accumulatedDuration = 0
            entry.isPaused = false
            entry.updatedAt = Date()
            store.saveTimeEntry(entry)

        case .manualLog:
            let newEntry = TimeEntry(
                entryDescription: trimmedDesc,
                startDate: startTime,
                endDate: endTime,
                accumulatedDuration: 0,
                isPaused: false,
                createdAt: Date(),
                updatedAt: Date(),
                projectId: selectedProjectId,
                taskId: selectedTaskId,
                tagIds: []
            )
            store.saveTimeEntry(newEntry)

            // Retain last selected project/task for chained work
            timerManager.retainedProjectId = selectedProjectId
            timerManager.retainedTaskId = selectedTaskId
        }

        dismiss()
    }
}
