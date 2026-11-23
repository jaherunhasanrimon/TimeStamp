import Foundation
import Testing
@testable import TimeStamp

@Suite("Project and Task Management Tests")
@MainActor
struct ProjectManagementTests {

    @Test("Verify project creation, modification, and persistence")
    func testProjectCRUD() {
        let store = PersistenceStore(inMemory: true)
        let project = Project(name: "Client Redesign", colorHex: "#FF9F0A")
        store.saveProject(project)

        #expect(store.projects.count == 1)
        #expect(store.projects.first?.name == "Client Redesign")
        #expect(store.projects.first?.colorHex == "#FF9F0A")
        #expect(store.projects.first?.isArchived == false)

        // Modify project
        project.name = "Client Redesign v2"
        project.colorHex = "#0A84FF"
        store.saveProject(project)

        #expect(store.projects.count == 1)
        #expect(store.projects.first?.name == "Client Redesign v2")
        #expect(store.projects.first?.colorHex == "#0A84FF")
    }

    @Test("Verify project archiving and unarchiving toggles isArchived")
    func testProjectArchiving() {
        let store = PersistenceStore(inMemory: true)
        let project = Project(name: "Old Internal Tool", colorHex: "#30D158", isArchived: false)
        store.saveProject(project)

        #expect(store.projects.first?.isArchived == false)

        // Archive project
        project.isArchived = true
        store.saveProject(project)
        #expect(store.projects.first?.isArchived == true)

        // Unarchive project
        project.isArchived = false
        store.saveProject(project)
        #expect(store.projects.first?.isArchived == false)
    }

    @Test("Verify project deletion cascades to child tasks and unlinks time entries")
    func testProjectCascadeAndUnlinking() {
        let store = PersistenceStore(inMemory: true)
        let project = Project(name: "Website Launch")
        store.saveProject(project)

        let task1 = Task(name: "Landing page design", projectId: project.id)
        let task2 = Task(name: "Copywriting", projectId: project.id)
        store.saveTask(task1)
        store.saveTask(task2)

        let entry = TimeEntry(
            entryDescription: "Working on landing hero",
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            projectId: project.id,
            taskId: task1.id
        )
        store.saveTimeEntry(entry)

        #expect(store.projects.count == 1)
        #expect(store.tasks.count == 2)
        #expect(store.timeEntries.count == 1)
        #expect(store.timeEntries.first?.projectId == project.id)
        #expect(store.timeEntries.first?.taskId == task1.id)

        // Delete project
        store.deleteProject(id: project.id)

        #expect(store.projects.isEmpty)
        #expect(store.tasks.isEmpty) // Child tasks cascaded
        #expect(store.timeEntries.count == 1) // Entry preserved
        #expect(store.timeEntries.first?.projectId == nil) // Unlinked
        #expect(store.timeEntries.first?.taskId == nil) // Unlinked
    }

    @Test("Verify task creation, completion toggle, and unlinking on deletion")
    func testTaskCompletionAndDeletion() {
        let store = PersistenceStore(inMemory: true)
        let project = Project(name: "App Feature")
        store.saveProject(project)

        let task = Task(name: "Build settings UI", isCompleted: false, projectId: project.id)
        store.saveTask(task)

        #expect(store.tasks.count == 1)
        #expect(store.tasks.first?.isCompleted == false)

        // Mark completed
        task.isCompleted = true
        store.saveTask(task)
        #expect(store.tasks.first?.isCompleted == true)

        // Associate time entry with task
        let entry = TimeEntry(
            entryDescription: "Settings layout",
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date(),
            projectId: project.id,
            taskId: task.id
        )
        store.saveTimeEntry(entry)

        // Delete task
        store.deleteTask(id: task.id)
        #expect(store.tasks.isEmpty)
        #expect(store.projects.count == 1)
        #expect(store.timeEntries.first?.projectId == project.id) // Project still associated
        #expect(store.timeEntries.first?.taskId == nil) // Task unlinked
    }

    @Test("Verify timer start on completed task auto-reopens task")
    @MainActor
    func testTimerAutoReopenCompletedTask() {
        let store = PersistenceStore(inMemory: true)
        let timerManager = TimerManager(store: store)

        let project = Project(name: "Project AutoReopen")
        store.saveProject(project)

        let task = Task(name: "Finished bug fix", isCompleted: true, projectId: project.id)
        store.saveTask(task)
        #expect(task.isCompleted == true)

        // Simulate start tracking from task row
        if task.isCompleted {
            task.isCompleted = false
            store.saveTask(task)
        }
        timerManager.start(description: task.name, projectId: project.id, taskId: task.id)

        #expect(task.isCompleted == false)
        #expect(store.tasks.first?.isCompleted == false)
        #expect(timerManager.activeEntry?.projectId == project.id)
        #expect(timerManager.activeEntry?.taskId == task.id)
    }

    @Test("Verify metric calculations for project and task tracked hours")
    func testTrackedDurationAggregation() {
        let store = PersistenceStore(inMemory: true)
        let project = Project(name: "Analytics Project")
        store.saveProject(project)

        let task1 = Task(name: "Task A", projectId: project.id)
        let task2 = Task(name: "Task B", projectId: project.id)
        store.saveTask(task1)
        store.saveTask(task2)

        let now = Date()
        let entry1 = TimeEntry(
            entryDescription: "Session 1",
            startDate: now.addingTimeInterval(-3600),
            endDate: now,
            projectId: project.id,
            taskId: task1.id
        )
        let entry2 = TimeEntry(
            entryDescription: "Session 2",
            startDate: now.addingTimeInterval(-1800),
            endDate: now,
            projectId: project.id,
            taskId: task2.id
        )
        store.saveTimeEntry(entry1)
        store.saveTimeEntry(entry2)

        let projectDuration = store.timeEntries
            .filter { $0.projectId == project.id }
            .reduce(0) { $0 + $1.effectiveDuration }
        #expect(projectDuration >= 5400) // 1h + 30m = 5400s

        let task1Duration = store.timeEntries
            .filter { $0.taskId == task1.id }
            .reduce(0) { $0 + $1.effectiveDuration }
        #expect(task1Duration >= 3600)

        let formatted = DateHelper.formatHumanDuration(projectDuration)
        #expect(formatted == "1h 30m")
    }
}
