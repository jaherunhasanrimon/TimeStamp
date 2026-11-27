import Foundation
import Observation

@Observable
@MainActor
public final class TimerManager {
    public static let shared = TimerManager(store: PersistenceStore.shared)

    public private(set) var activeEntry: TimeEntry?
    public private(set) var currentDuration: TimeInterval = 0
    public private(set) var formattedDuration: String = "00:00:00"
    public private(set) var compactFormattedDuration: String = "0:00:00"
    public private(set) var isPaused: Bool = false

    public var isRunning: Bool {
        activeEntry != nil && !isPaused
    }

    // Retained values for chained work on the same project (D-06)
    public var retainedProjectId: UUID?
    public var retainedTaskId: UUID?
    public var retainedTagIds: [UUID] = []
    public var retainedIsBillable: Bool = false

    private let store: PersistenceStore
    public var isInMemoryStore: Bool { store.isInMemory }
    private var sleepMonitor: SleepWakeMonitor?
    private var tickTimer: Timer?

    /// Optional callback invoked whenever a timer session starts or resumes.
    /// Set by `IdleDetectionManager` after both singletons are initialised to
    /// break the initialisation cycle (D-IDLE-01).
    public var onTimerSessionStarted: ((Date) -> Void)?

    public init(store: PersistenceStore) {
        self.store = store
        setupSleepMonitor()
        restoreActiveSession()
        applyDefaultProjectIfIdle()
    }

    /// Reads configured Default Project from UserDefaults if active/retained project is nil and store is not in-memory.
    public func applyDefaultProjectIfIdle(defaultProjectIdString: String? = nil) {
        guard activeEntry == nil, retainedProjectId == nil else { return }
        let resolvedIdStr: String?
        if let explicit = defaultProjectIdString {
            resolvedIdStr = explicit
        } else {
            guard !store.isInMemory else { return }
            resolvedIdStr = UserDefaults.standard.string(forKey: "defaultProjectId")
        }
        if let idStr = resolvedIdStr,
           let uuid = UUID(uuidString: idStr),
           let project = store.project(for: uuid),
           !project.isArchived {
            self.retainedProjectId = project.id
            if project.isBillableDefault {
                self.retainedIsBillable = true
            }
        }
    }

    private func setupSleepMonitor() {
        self.sleepMonitor = SleepWakeMonitor(
            onSleep: { [weak self] in
                self?.updateTick()
            },
            onWake: { [weak self] in
                self?.updateTick()
            }
        )
    }

    // MARK: - Timer Controls

    /// Starts a new active tracking session (TIMER-01)
    public func start(
        description: String = "",
        projectId: UUID? = nil,
        taskId: UUID? = nil,
        tagIds: [UUID] = [],
        isBillable: Bool = false
    ) {
        // If a timer is already running, stop it first to prevent collisions (D-10)
        if activeEntry != nil {
            _ = stop()
        }

        let entry = TimeEntry(
            entryDescription: description,
            startDate: Date(),
            endDate: nil,
            accumulatedDuration: 0,
            isPaused: false,
            projectId: projectId,
            taskId: taskId,
            tagIds: tagIds,
            isBillable: isBillable
        )

        self.activeEntry = entry
        self.isPaused = false
        self.retainedProjectId = projectId
        self.retainedTaskId = taskId
        self.retainedTagIds = tagIds
        self.retainedIsBillable = isBillable

        store.saveTimeEntry(entry)
        updateTick()
        startTickTimer()
        onTimerSessionStarted?(entry.startDate)
    }

    /// Pauses an active timer without losing accumulated duration (TIMER-02)
    public func pause() {
        guard let entry = activeEntry, !isPaused else { return }

        let now = Date()
        let elapsedSinceStart = max(0, now.timeIntervalSince(entry.startDate))
        entry.accumulatedDuration += elapsedSinceStart
        entry.isPaused = true
        entry.updatedAt = now

        self.isPaused = true
        stopTickTimer()
        updateTick()
        store.saveTimeEntry(entry)
    }

    /// Resumes a paused timer session (TIMER-02)
    public func resume() {
        guard let entry = activeEntry, isPaused else { return }

        let now = Date()
        entry.startDate = now
        entry.isPaused = false
        entry.updatedAt = now

        self.isPaused = false
        updateTick()
        startTickTimer()
        store.saveTimeEntry(entry)
        // Notify idle detection so idle readings before this resume are ignored (D-IDLE-01)
        onTimerSessionStarted?(now)
    }

    /// Stops the timer and saves the completed TimeEntry (TIMER-03)
    @discardableResult
    public func stop() -> TimeEntry? {
        guard let entry = activeEntry else { return nil }

        stopTickTimer()

        let now = Date()
        if !isPaused {
            let session = max(0, now.timeIntervalSince(entry.startDate))
            entry.accumulatedDuration += session
        }

        entry.endDate = now
        entry.isPaused = false
        entry.updatedAt = now

        // Retain project & task for chaining (D-06)
        self.retainedProjectId = entry.projectId
        self.retainedTaskId = entry.taskId
        self.retainedTagIds = entry.tagIds
        self.retainedIsBillable = entry.isBillable

        store.saveTimeEntry(entry)

        let completed = entry
        self.activeEntry = nil
        self.isPaused = false
        self.currentDuration = 0
        self.formattedDuration = "00:00:00"
        self.compactFormattedDuration = "0:00:00"

        return completed
    }

    /// Discards the active timer without saving a completed entry (D-08)
    public func discard() {
        guard let entry = activeEntry else { return }

        stopTickTimer()
        store.deleteTimeEntry(id: entry.id)

        self.activeEntry = nil
        self.isPaused = false
        self.currentDuration = 0
        self.formattedDuration = "00:00:00"
        self.compactFormattedDuration = "0:00:00"
    }

    /// Continues tracking from a past entry with seamless auto-switch (TIMER-04, D-09, D-10, D-11, D-12)
    public func continueEntry(_ entry: TimeEntry) {
        start(
            description: entry.entryDescription,
            projectId: entry.projectId,
            taskId: entry.taskId,
            tagIds: entry.tagIds,
            isBillable: entry.isBillable
        )
    }

    /// Continues the most recently completed time entry (Cmd+O shortcut)
    public func continueLastEntry() {
        guard let last = store.timeEntries
            .filter({ $0.endDate != nil })
            .sorted(by: { $0.startDate > $1.startDate })
            .first else {
            return
        }
        continueEntry(last)
    }

    // MARK: - Rehydration / Auto-Restore (D-14)

    /// Restores any uncompleted running session from local storage on launch
    public func restoreActiveSession() {
        if let existingActive = store.timeEntries.first(where: { $0.endDate == nil }) {
            self.activeEntry = existingActive
            self.isPaused = existingActive.isPaused
            self.retainedProjectId = existingActive.projectId
            self.retainedTaskId = existingActive.taskId
            self.retainedTagIds = existingActive.tagIds
            self.retainedIsBillable = existingActive.isBillable

            updateTick()
            if !existingActive.isPaused {
                startTickTimer()
                // Baseline idle detection from "now" on launch so stale HID readings before
                // the user launched the app do not trigger an immediate idle sheet (D-IDLE-01)
                onTimerSessionStarted?(Date())
            }
        }
    }

    // MARK: - RunLoop Tick Loop (D-15)

    private func startTickTimer() {
        stopTickTimer()
        // 1-second cadence on .common RunLoop for battery & CPU efficiency (D-15)
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateTick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.tickTimer = timer
    }

    private func stopTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    public func updateTick() {
        guard let entry = activeEntry else {
            self.currentDuration = 0
            self.formattedDuration = "00:00:00"
            self.compactFormattedDuration = "0:00:00"
            return
        }

        let duration = TimeCalculator.calculateDuration(
            startDate: entry.startDate,
            endDate: entry.endDate,
            accumulatedDuration: entry.accumulatedDuration,
            isPaused: isPaused
        )

        self.currentDuration = duration
        self.formattedDuration = TimeCalculator.formatDuration(duration)
        self.compactFormattedDuration = TimeCalculator.formatCompactDuration(duration)
    }
}
