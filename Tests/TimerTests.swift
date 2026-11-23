import Testing
@testable import TimeStamp
import Foundation

@Suite("Timer Engine & Drift-Free Math Tests")
@MainActor
struct TimerTests {

    // MARK: - TimeCalculator Tests

    @Test("TimeCalculator accurately computes running, paused, and completed durations")
    func timeCalculatorDurations() {
        let start = Date(timeIntervalSince1970: 1000)
        let now = Date(timeIntervalSince1970: 1060)

        // Running session
        let runningDuration = TimeCalculator.calculateDuration(
            startDate: start,
            endDate: nil,
            accumulatedDuration: 30,
            isPaused: false,
            now: now
        )
        #expect(runningDuration == 90) // 30 accumulated + 60 running

        // Paused session
        let pausedDuration = TimeCalculator.calculateDuration(
            startDate: start,
            endDate: nil,
            accumulatedDuration: 45,
            isPaused: true,
            now: now
        )
        #expect(pausedDuration == 45) // Only accumulated duration

        // Completed session
        let end = Date(timeIntervalSince1970: 1100)
        let completedDuration = TimeCalculator.calculateDuration(
            startDate: start,
            endDate: end,
            accumulatedDuration: 20,
            isPaused: false,
            now: now
        )
        #expect(completedDuration == 120) // 20 accumulated + 100 between start and end
    }

    @Test("TimeCalculator formats duration strings as zero-padded HH:MM:SS")
    func timeCalculatorFormatting() {
        #expect(TimeCalculator.formatDuration(0) == "00:00:00")
        #expect(TimeCalculator.formatDuration(45) == "00:00:45")
        #expect(TimeCalculator.formatDuration(252) == "00:04:12")
        #expect(TimeCalculator.formatDuration(3665) == "01:01:05")
        #expect(TimeCalculator.formatDuration(90065) == "25:01:05")
    }

    @Test("TimeCalculator safely handles negative clock skew without going negative")
    func timeCalculatorClockSkewSafety() {
        let start = Date(timeIntervalSince1970: 2000)
        let nowBeforeStart = Date(timeIntervalSince1970: 1500) // Clock went backwards

        let duration = TimeCalculator.calculateDuration(
            startDate: start,
            endDate: nil,
            accumulatedDuration: 10,
            isPaused: false,
            now: nowBeforeStart
        )
        #expect(duration == 10) // 10 accumulated + max(0, -500) = 10
    }

    // MARK: - TimerManager State Machine Tests

    @Test("TimerManager starts, stops, and persists completed TimeEntry")
    func timerManagerStartStopPersist() {
        let store = PersistenceStore(inMemory: true)
        let manager = TimerManager(store: store)

        let projectId = UUID()
        let taskId = UUID()

        #expect(!manager.isRunning)
        #expect(manager.activeEntry == nil)

        // Start timer
        manager.start(description: "Writing unit tests", projectId: projectId, taskId: taskId)
        #expect(manager.isRunning)
        #expect(manager.activeEntry?.entryDescription == "Writing unit tests")
        #expect(manager.activeEntry?.projectId == projectId)
        #expect(manager.activeEntry?.taskId == taskId)
        #expect(store.timeEntries.count == 1)

        // Stop timer
        let completed = manager.stop()
        #expect(!manager.isRunning)
        #expect(manager.activeEntry == nil)
        #expect(completed != nil)
        #expect(completed?.endDate != nil)
        #expect(manager.retainedProjectId == projectId)
        #expect(manager.retainedTaskId == taskId)
        #expect(store.timeEntries.count == 1)
        #expect(store.timeEntries.first?.endDate != nil)
    }

    @Test("TimerManager pause and resume maintains accumulated duration")
    func timerManagerPauseResume() {
        let store = PersistenceStore(inMemory: true)
        let manager = TimerManager(store: store)

        manager.start(description: "Pause testing")
        #expect(manager.isRunning)
        #expect(!manager.isPaused)

        // Pause
        manager.pause()
        #expect(!manager.isRunning)
        #expect(manager.isPaused)
        #expect(manager.activeEntry != nil)

        // Resume
        manager.resume()
        #expect(manager.isRunning)
        #expect(!manager.isPaused)

        _ = manager.stop()
        #expect(!manager.isRunning)
    }

    @Test("TimerManager discard deletes active entry without saving")
    func timerManagerDiscard() {
        let store = PersistenceStore(inMemory: true)
        let manager = TimerManager(store: store)

        manager.start(description: "Accidental session")
        #expect(store.timeEntries.count == 1)

        manager.discard()
        #expect(manager.activeEntry == nil)
        #expect(!manager.isRunning)
        #expect(store.timeEntries.isEmpty)
    }

    @Test("TimerManager continueEntry auto-stops current and starts fresh session with cloned attributes")
    func timerManagerContinueAutoSwitch() {
        let store = PersistenceStore(inMemory: true)
        let manager = TimerManager(store: store)

        let pId = UUID()
        let tId = UUID()
        let tagId = UUID()

        let pastEntry = TimeEntry(
            entryDescription: "Refactoring architecture",
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date().addingTimeInterval(-1800),
            accumulatedDuration: 1800,
            projectId: pId,
            taskId: tId,
            tagIds: [tagId]
        )
        store.saveTimeEntry(pastEntry)

        // Start an existing active session
        manager.start(description: "Existing session")
        #expect(manager.activeEntry?.entryDescription == "Existing session")

        // Continue the past entry
        manager.continueEntry(pastEntry)

        // Prior session should be stopped with endDate
        let existingSession = store.timeEntries.first(where: { $0.entryDescription == "Existing session" })
        #expect(existingSession?.endDate != nil)

        // Active session should be the continued one
        #expect(manager.isRunning)
        #expect(manager.activeEntry?.entryDescription == "Refactoring architecture")
        #expect(manager.activeEntry?.projectId == pId)
        #expect(manager.activeEntry?.taskId == tId)
        #expect(manager.activeEntry?.tagIds == [tagId])
        #expect(manager.activeEntry?.id != pastEntry.id) // Distinct new entry
    }

    @Test("TimerManager auto-restores uncompleted active session on launch")
    func timerManagerAutoRestore() {
        let store = PersistenceStore(inMemory: true)

        let incompleteEntry = TimeEntry(
            entryDescription: "Interrupted session",
            startDate: Date().addingTimeInterval(-600),
            endDate: nil,
            accumulatedDuration: 120,
            isPaused: false
        )
        store.saveTimeEntry(incompleteEntry)

        // Initialize manager
        let manager = TimerManager(store: store)
        #expect(manager.activeEntry?.id == incompleteEntry.id)
        #expect(manager.isRunning)
        #expect(manager.currentDuration >= 720)
    }
}
