import SwiftUI

/// Toggl Track Authentic Two-Row Active Timer Bar.
/// Row 1: Pomodoro Tomato + Description + Monospace Ticker + Circular Magenta Play Button (#E54583) + Mode Toggle
/// Row 2: 📁 Project Picker + 🏷️ Tags + 💲 Billable Toggle
public struct ActiveTimerBar: View {
    @Environment(TimerManager.self) private var timerManager
    @Environment(PersistenceStore.self) private var store
    @Environment(PomodoroManager.self) private var pomodoroManager

    @State private var descriptionText: String = ""
    @State private var selectedProjectId: UUID?
    @State private var selectedTaskId: UUID?
    @State private var selectedTagIds: [UUID] = []
    @State private var isBillable: Bool = false
    @State private var isProjectPickerPresented: Bool = false
    @State private var isTagPickerPresented: Bool = false
    @State private var isPomodoroPopoverPresented: Bool = false
    @State private var isManualLogSheetPresented: Bool = false

    public init() {}

    private var selectedProject: Project? {
        guard let id = selectedProjectId else { return nil }
        return store.projects.first(where: { $0.id == id })
    }

    private var selectedTask: Task? {
        guard let id = selectedTaskId else { return nil }
        return store.tasks.first(where: { $0.id == id })
    }

    public var body: some View {
        VStack(spacing: 8) {
            // ROW 1: Pomodoro Icon + Description Field + Duration + Play Button + Mode Icon
            HStack(spacing: 10) {
                // Tomato Pomodoro Icon Button
                Button(action: {
                    isPomodoroPopoverPresented.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(pomodoroManager.isRunning ? AppColors.togglMagenta.opacity(0.18) : AppColors.insetBackground)
                            .frame(width: 28, height: 28)

                        if pomodoroManager.isRunning {
                            Circle()
                                .stroke(
                                    pomodoroManager.sessionType == .work ? AppColors.togglMagenta : AppColors.success,
                                    lineWidth: 1.5
                                )
                                .frame(width: 28, height: 28)
                        }

                        Text("🍅")
                            .font(.system(size: 14))
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

                // Borderless Description Field
                TextField("What are you working on?", text: $descriptionText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .onSubmit {
                        handleReturnKey()
                    }

                Spacer(minLength: 8)

                // Monospaced Duration Ticker
                Text(timerManager.formattedDuration)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(timerManager.isRunning ? Color.primary : .secondary)

                // Circular Magenta Start/Stop Button (#E54583 / #FF453A)
                CircularPlayButton(
                    isRunning: timerManager.isRunning,
                    isPaused: timerManager.isPaused,
                    onToggle: {
                        if timerManager.isRunning {
                            stopTimer()
                        } else {
                            startTimer()
                        }
                    },
                    onPauseToggle: timerManager.isRunning ? togglePause : nil
                )

                // Manual Entry Mode Button (Stacked play / plus icon)
                Button(action: {
                    isManualLogSheetPresented = true
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.secondaryCardBackground)
                            .frame(width: 22, height: 22)

                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .help("Manual time entry")
            }

            // ROW 2: Sub-toolbar containing 📁 Folder, 🏷️ Tags, and 💲 Billable
            HStack(spacing: 12) {
                // 📁 Project / Task Picker Button
                Button(action: {
                    isProjectPickerPresented.toggle()
                }) {
                    HStack(spacing: 5) {
                        if let project = selectedProject {
                            Circle()
                                .fill(Color(hex: project.colorHex))
                                .frame(width: 8, height: 8)

                            Text(project.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.primary)

                            if let task = selectedTask {
                                Text("• \(task.name)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(selectedProject != nil ? AppColors.secondaryCardBackground : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
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
                .help(selectedTagIds.isEmpty ? "Add tags" : "\(selectedTagIds.count) tag(s) selected")
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
                    if timerManager.isRunning, let active = timerManager.activeEntry {
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

                Spacer()

                // Discard Button when running
                if timerManager.isRunning {
                    Button(action: discardTimer) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Discard running timer")
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
        .sheet(isPresented: $isManualLogSheetPresented) {
            EntryEditSheet(mode: .manualLog(initialProjectId: nil, initialTaskId: nil))
        }
        .onAppear {
            syncFromManager()
        }
        .onChange(of: timerManager.activeEntry) { oldEntry, newEntry in
            if let entry = newEntry {
                descriptionText = entry.entryDescription
                selectedProjectId = entry.projectId
                selectedTaskId = entry.taskId
                selectedTagIds = entry.tagIds
                isBillable = entry.isBillable
            } else {
                descriptionText = ""
                selectedProjectId = timerManager.retainedProjectId
                selectedTaskId = timerManager.retainedTaskId
                selectedTagIds = timerManager.retainedTagIds
                isBillable = timerManager.retainedIsBillable
            }
        }
        .onChange(of: selectedProjectId) { _, newProjectId in
            if let pId = newProjectId, let project = store.project(for: pId) {
                if project.isBillableDefault {
                    isBillable = true
                }
            }
            if timerManager.isRunning, let active = timerManager.activeEntry {
                active.projectId = newProjectId
                store.saveTimeEntry(active)
            }
        }
        .onChange(of: selectedTagIds) { _, newTagIds in
            if timerManager.isRunning, let active = timerManager.activeEntry {
                active.tagIds = newTagIds
                store.saveTimeEntry(active)
            }
        }
    }

    private func syncFromManager() {
        if let entry = timerManager.activeEntry {
            descriptionText = entry.entryDescription
            selectedProjectId = entry.projectId
            selectedTaskId = entry.taskId
            selectedTagIds = entry.tagIds
            isBillable = entry.isBillable
        } else {
            selectedProjectId = timerManager.retainedProjectId
            selectedTaskId = timerManager.retainedTaskId
            selectedTagIds = timerManager.retainedTagIds
            isBillable = timerManager.retainedIsBillable
        }
    }

    private func handleReturnKey() {
        if timerManager.isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        timerManager.start(
            description: descriptionText,
            projectId: selectedProjectId,
            taskId: selectedTaskId,
            tagIds: selectedTagIds,
            isBillable: isBillable
        )
    }

    private func stopTimer() {
        _ = timerManager.stop()
        descriptionText = ""
        selectedProjectId = timerManager.retainedProjectId
        selectedTaskId = timerManager.retainedTaskId
        selectedTagIds = timerManager.retainedTagIds
        isBillable = timerManager.retainedIsBillable
    }

    private func togglePause() {
        if timerManager.isPaused {
            timerManager.resume()
        } else {
            timerManager.pause()
        }
    }

    private func discardTimer() {
        timerManager.discard()
        descriptionText = ""
        selectedProjectId = timerManager.retainedProjectId
        selectedTaskId = timerManager.retainedTaskId
        selectedTagIds = timerManager.retainedTagIds
        isBillable = timerManager.retainedIsBillable
    }
}
