import Foundation
import Observation
import CoreGraphics

/// Detects keyboard and mouse inactivity via CoreGraphics HID idle timer (`CGEventSource.secondsSinceLastEventType`).
/// Requires zero Accessibility or Screen Recording permissions.
@Observable
@MainActor
public final class IdleDetectionManager {
    public static let shared = IdleDetectionManager(
        store: PersistenceStore.shared,
        timerManager: TimerManager.shared,
        isInMemory: false
    )

    public var isEnabled: Bool {
        didSet { persistSettings() }
    }
    public var idleThresholdMinutes: Int {
        didSet { persistSettings() }
    }

    public private(set) var isPromptPresented: Bool = false
    public private(set) var detectedIdleSeconds: TimeInterval = 0
    public private(set) var idleStartedAt: Date? = nil
    public private(set) var affectedEntryDescription: String = ""

    private let store: PersistenceStore
    private let timerManager: TimerManager
    private let isInMemory: Bool
    private let idleSecondsProvider: () -> TimeInterval
    private var monitorTimer: Timer?

    public init(
        store: PersistenceStore,
        timerManager: TimerManager,
        isInMemory: Bool = false,
        idleSecondsProvider: (() -> TimeInterval)? = nil
    ) {
        self.store = store
        self.timerManager = timerManager
        self.isInMemory = isInMemory
        self.idleSecondsProvider = idleSecondsProvider ?? {
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .null)
        }

        if isInMemory || store.isInMemory {
            self.isEnabled = true
            self.idleThresholdMinutes = 10
        } else {
            let defaults = UserDefaults.standard
            if defaults.object(forKey: "idleDetectionEnabled") != nil {
                self.isEnabled = defaults.bool(forKey: "idleDetectionEnabled")
            } else {
                self.isEnabled = true
            }
            let mins = defaults.integer(forKey: "idleThresholdMinutes")
            self.idleThresholdMinutes = mins > 0 ? mins : 10
            startMonitoring()
        }
    }

    private func persistSettings() {
        guard !isInMemory && !store.isInMemory else { return }
        UserDefaults.standard.set(isEnabled, forKey: "idleDetectionEnabled")
        UserDefaults.standard.set(idleThresholdMinutes, forKey: "idleThresholdMinutes")
    }

    public func startMonitoring() {
        stopMonitoring()
        let timer = Timer(timeInterval: 15.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.evaluateIdleState(now: Date())
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        monitorTimer = timer
    }

    public func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    /// Evaluates current system HID inactivity against threshold when a timer is actively running.
    public func evaluateIdleState(now: Date = Date()) {
        guard isEnabled else { return }
        guard timerManager.isRunning, let active = timerManager.activeEntry else { return }
        guard !isPromptPresented else { return }

        let idleSeconds = max(0, idleSecondsProvider())
        let thresholdSeconds = TimeInterval(max(1, idleThresholdMinutes) * 60)
        if idleSeconds >= thresholdSeconds {
            let calculatedIdleStart = now.addingTimeInterval(-idleSeconds)
            self.idleStartedAt = max(active.startDate, calculatedIdleStart)
            self.detectedIdleSeconds = max(0, now.timeIntervalSince(self.idleStartedAt ?? now))
            self.affectedEntryDescription = active.entryDescription.isEmpty ? "Running timer" : active.entryDescription
            self.isPromptPresented = true
        }
    }

    // MARK: - Resolution Actions

    /// Action 1: Keep all idle time as part of the current running entry.
    public func keepIdleTime() {
        dismissPrompt()
    }

    /// Action 2: Discard idle time by stopping the entry at when inactivity started.
    public func discardIdleTime(now: Date = Date()) {
        guard let active = timerManager.activeEntry else {
            dismissPrompt()
            return
        }
        let cutoff = clampCutoff(idleStartedAt ?? now, active: active, now: now)
        let activeDesc = active.entryDescription
        let projId = active.projectId
        let taskId = active.taskId
        let tagIds = active.tagIds
        let isBillable = active.isBillable
        let preCutoffDuration = active.accumulatedDuration + max(0, cutoff.timeIntervalSince(active.startDate))

        timerManager.discard()
        if preCutoffDuration >= 1.0 {
            let trimmed = TimeEntry(
                entryDescription: activeDesc,
                startDate: cutoff.addingTimeInterval(-preCutoffDuration),
                endDate: cutoff,
                accumulatedDuration: preCutoffDuration,
                projectId: projId,
                taskId: taskId,
                tagIds: tagIds,
                isBillable: isBillable
            )
            store.saveTimeEntry(trimmed)
        }
        dismissPrompt()
    }

    /// Action 3: Discard idle time and immediately start a fresh timer from now.
    public func discardIdleTimeAndContinue(now: Date = Date()) {
        guard let active = timerManager.activeEntry else {
            dismissPrompt()
            return
        }
        let desc = active.entryDescription
        let projId = active.projectId
        let taskId = active.taskId
        let tagIds = active.tagIds
        let isBillable = active.isBillable

        discardIdleTime(now: now)
        timerManager.start(
            description: desc,
            projectId: projId,
            taskId: taskId,
            tagIds: tagIds,
            isBillable: isBillable
        )
    }

    /// Action 4: End current work at idle start, save idle period as its own separate entry, and continue tracking.
    public func addIdleTimeAsNewEntry(idleDescription: String = "Away / Meeting", now: Date = Date()) {
        guard let active = timerManager.activeEntry else {
            dismissPrompt()
            return
        }
        let cutoff = clampCutoff(idleStartedAt ?? now, active: active, now: now)
        let desc = active.entryDescription
        let projId = active.projectId
        let taskId = active.taskId
        let tagIds = active.tagIds
        let isBillable = active.isBillable

        discardIdleTime(now: now)
        let idleDur = max(60.0, now.timeIntervalSince(cutoff))
        let awayEntry = TimeEntry(
            entryDescription: idleDescription,
            startDate: cutoff,
            endDate: cutoff.addingTimeInterval(idleDur),
            accumulatedDuration: idleDur,
            projectId: nil,
            isBillable: false
        )
        store.saveTimeEntry(awayEntry)

        timerManager.start(
            description: desc,
            projectId: projId,
            taskId: taskId,
            tagIds: tagIds,
            isBillable: isBillable
        )
    }

    public func dismissPrompt() {
        isPromptPresented = false
        detectedIdleSeconds = 0
        idleStartedAt = nil
    }

    private func clampCutoff(_ candidate: Date, active: TimeEntry, now: Date) -> Date {
        min(now, max(active.startDate, candidate))
    }
}
