import Foundation
import Testing
@testable import TimeStamp

@Suite("MenuBar Companion and Ticker Tests")
@MainActor
struct MenuBarCompanionTests {

    @Test("Verify menu bar status transitions from idle to running to paused to stopped")
    func testMenuBarStateTransitions() {
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)

        // 1. Initial Idle State
        #expect(timer.isRunning == false)
        #expect(timer.isPaused == false)
        #expect(timer.activeEntry == nil)

        // 2. Start Timer
        timer.start(description: "Menu bar feature testing")
        #expect(timer.isRunning == true)
        #expect(timer.isPaused == false)
        #expect(timer.activeEntry != nil)
        #expect(timer.activeEntry?.entryDescription == "Menu bar feature testing")
        #expect(timer.formattedDuration.count == 8) // "00:00:00"

        // 3. Pause Timer
        timer.pause()
        #expect(timer.isRunning == false)
        #expect(timer.isPaused == true)

        // 4. Resume Timer
        timer.resume()
        #expect(timer.isRunning == true)
        #expect(timer.isPaused == false)

        // 5. Stop Timer
        let completed = timer.stop()
        #expect(timer.isRunning == false)
        #expect(timer.isPaused == false)
        #expect(timer.activeEntry == nil)
        #expect(completed != nil)
        #expect(store.timeEntries.count == 1)
    }

    @Test("Verify zero-jitter fixed-width duration format")
    func testZeroJitterDurationFormatting() {
        // Durations at various points in time
        let durationZero: TimeInterval = 0
        let durationMinutes: TimeInterval = 145 // 2m 25s
        let durationHours: TimeInterval = 3725  // 1h 2m 5s

        let str0 = TimeCalculator.formatDuration(durationZero)
        let str1 = TimeCalculator.formatDuration(durationMinutes)
        let str2 = TimeCalculator.formatDuration(durationHours)

        #expect(str0 == "00:00:00")
        #expect(str1 == "00:02:25")
        #expect(str2 == "01:02:05")

        // Strictly 8 characters long to guarantee zero layout jitter in the status bar
        #expect(str0.count == 8)
        #expect(str1.count == 8)
        #expect(str2.count == 8)
    }

    @Test("Verify discard active session cleans up without saving")
    func testDiscardActiveSession() {
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)

        timer.start(description: "Accidental session")
        #expect(timer.isRunning == true)

        timer.discard()
        #expect(timer.isRunning == false)
        #expect(timer.activeEntry == nil)
        #expect(store.timeEntries.isEmpty)
    }

    @Test("Verify retained project and task persistence for quick-start")
    func testRetainedProjectAndTask() {
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)

        let project = Project(name: "Client Project")
        store.saveProject(project)
        let task = Task(name: "Feature Work", projectId: project.id)
        store.saveTask(task)

        // Start with project and task
        timer.start(description: "First session", projectId: project.id, taskId: task.id)
        _ = timer.stop()

        #expect(timer.retainedProjectId == project.id)
        #expect(timer.retainedTaskId == task.id)

        // Start second session without explicit project/task: retained IDs are available
        timer.start(
            description: "Second session",
            projectId: timer.retainedProjectId,
            taskId: timer.retainedTaskId
        )

        #expect(timer.activeEntry?.projectId == project.id)
        #expect(timer.activeEntry?.taskId == task.id)
        _ = timer.stop()
    }
}
