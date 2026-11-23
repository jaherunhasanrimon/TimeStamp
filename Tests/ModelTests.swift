import Testing
@testable import TimeStamp
import Foundation

@Suite("Domain Model & PersistenceStore Tests")
@MainActor
struct ModelTests {
    let store = PersistenceStore(inMemory: true)

    @Test("Verify in-memory PersistenceStore starts empty")
    func persistenceStoreInitialization() {
        #expect(store.isInMemory == true)
        #expect(store.clients.isEmpty)
        #expect(store.projects.isEmpty)
        #expect(store.timeEntries.isEmpty)
    }

    @Test("Verify Client and Project relationship linking and deletion")
    func clientProjectRelationship() {
        let client = Client(name: "Acme Corp", notes: "Test client")
        store.saveClient(client)
        #expect(store.clients.count == 1)

        let project = Project(name: "Design System", colorHex: "#5C3BFE", clientId: client.id)
        store.saveProject(project)
        #expect(store.projects.count == 1)
        #expect(store.projects.first?.clientId == client.id)

        // Deleting client should unlink the client from the project
        store.deleteClient(id: client.id)
        #expect(store.clients.isEmpty)
        #expect(store.projects.first?.clientId == nil)
    }

    @Test("Verify Project deletion cascades to tasks and unlinks time entries")
    func projectDeletionCascadesTasksAndUnlinksEntries() {
        let project = Project(name: "macOS App", colorHex: "#0A84FF")
        store.saveProject(project)

        let task = Task(name: "Scaffold App Shell", projectId: project.id)
        store.saveTask(task)
        #expect(store.tasks.count == 1)

        let entry = TimeEntry(
            entryDescription: "Working on shell",
            startDate: Date(),
            projectId: project.id,
            taskId: task.id
        )
        store.saveTimeEntry(entry)
        #expect(store.timeEntries.count == 1)

        // Delete project
        store.deleteProject(id: project.id)
        #expect(store.projects.isEmpty)
        // Child tasks must be deleted
        #expect(store.tasks.isEmpty)
        // Time entry should have project and task unlinked
        #expect(store.timeEntries.first?.projectId == nil)
        #expect(store.timeEntries.first?.taskId == nil)
    }

    @Test("Verify TimeEntry duration calculation for running vs completed entries")
    func timeEntryDurationCalculation() {
        let start = Date().addingTimeInterval(-120)
        let end = start.addingTimeInterval(60)

        let completedEntry = TimeEntry(
            entryDescription: "Completed work",
            startDate: start,
            endDate: end,
            accumulatedDuration: 0
        )
        #expect(completedEntry.isRunning == false)
        #expect(abs(completedEntry.effectiveDuration - 60) < 1.0)

        let runningEntry = TimeEntry(
            entryDescription: "In-progress work",
            startDate: start,
            endDate: nil,
            accumulatedDuration: 100,
            isPaused: false
        )
        #expect(runningEntry.isRunning == true)
        #expect(runningEntry.effectiveDuration >= 220)
    }

    @Test("Verify PreviewContainer seeds sample data")
    func previewContainerSampleData() {
        let sampleStore = PreviewContainer.sample
        #expect(!sampleStore.clients.isEmpty)
        #expect(!sampleStore.projects.isEmpty)
        #expect(!sampleStore.tasks.isEmpty)
        #expect(!sampleStore.tags.isEmpty)
        #expect(!sampleStore.timeEntries.isEmpty)
    }
}
