import Foundation
import Testing
@testable import TimeStamp

@Suite("Global System Hotkey Tests")
@MainActor
struct GlobalHotkeyTests {

    @Test("Verify GlobalHotkeyManager registration and unregistration lifecycle")
    func testHotkeyRegistrationLifecycle() {
        let manager = GlobalHotkeyManager.shared
        manager.unregister()
        #expect(manager.isRegistered == false)

        var triggerCount = 0
        manager.register {
            triggerCount += 1
        }

        #expect(manager.isRegistered == true)

        manager.unregister()
        #expect(manager.isRegistered == false)
    }

    @Test("Verify timer toggle logic transitions between idle and running states")
    func testTimerToggleLogic() {
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)

        let project = Project(name: "Global Hotkey Project")
        store.saveProject(project)
        let task = Task(name: "Carbon Hotkey Task", projectId: project.id)
        store.saveTask(task)

        timer.retainedProjectId = project.id
        timer.retainedTaskId = task.id

        // Helper simulation of the toggle logic
        func toggle() {
            if timer.isRunning || timer.isPaused {
                _ = timer.stop()
            } else {
                timer.start(
                    description: "",
                    projectId: timer.retainedProjectId,
                    taskId: timer.retainedTaskId
                )
            }
        }

        // 1. Initially idle
        #expect(timer.isRunning == false)
        #expect(timer.activeEntry == nil)

        // 2. First toggle: starts timer with retained project and task
        toggle()
        #expect(timer.isRunning == true)
        #expect(timer.activeEntry != nil)
        #expect(timer.activeEntry?.projectId == project.id)
        #expect(timer.activeEntry?.taskId == task.id)

        // 3. Second toggle: stops and persists timer session
        toggle()
        #expect(timer.isRunning == false)
        #expect(timer.activeEntry == nil)
        #expect(store.timeEntries.count == 1)
        #expect(store.timeEntries.first?.projectId == project.id)

        // 4. Third toggle: restarts another session
        toggle()
        #expect(timer.isRunning == true)
        #expect(timer.activeEntry != nil)

        // 5. Fourth toggle: stops second session
        toggle()
        #expect(timer.isRunning == false)
        #expect(store.timeEntries.count == 2)
    }

    @Test("Verify toggle stops and saves when timer is paused")
    func testToggleWhenPaused() {
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)

        timer.start(description: "Paused session test")
        timer.pause()
        #expect(timer.isPaused == true)

        // Toggle when paused should stop and save
        if timer.isRunning || timer.isPaused {
            _ = timer.stop()
        }

        #expect(timer.isRunning == false)
        #expect(timer.isPaused == false)
        #expect(timer.activeEntry == nil)
        #expect(store.timeEntries.count == 1)
        #expect(store.timeEntries.first?.entryDescription == "Paused session test")
    }
}
