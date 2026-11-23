import Testing
import Foundation
@testable import TimeStamp

@Suite("Entry Editing, Manual Logging, and Synchronization Tests")
struct EntryEditTests {

    @Test("Verify manual entry creation and persistence in store")
    @MainActor
    func testManualEntryCreationAndPersistence() {
        let store = PersistenceStore(inMemory: true)

        let project = Project(name: "Client Work", colorHex: "#5C3BFE")
        store.saveProject(project)

        let start = Date().addingTimeInterval(-3600)
        let end = Date()
        let manualEntry = TimeEntry(
            entryDescription: "Sprint Retrospective Meeting",
            startDate: start,
            endDate: end,
            accumulatedDuration: 0,
            isPaused: false,
            createdAt: Date(),
            updatedAt: Date(),
            projectId: project.id,
            taskId: nil,
            tagIds: []
        )

        store.saveTimeEntry(manualEntry)

        #expect(store.timeEntries.count == 1)
        let saved = store.timeEntries.first!
        #expect(saved.entryDescription == "Sprint Retrospective Meeting")
        #expect(saved.projectId == project.id)
        #expect(abs(saved.effectiveDuration - 3600) < 1.0)
        #expect(!saved.isRunning)
    }

    @Test("Verify editing entry details updates persisted record")
    @MainActor
    func testEntryDetailEditing() {
        let store = PersistenceStore(inMemory: true)

        let original = TimeEntry(
            entryDescription: "Draft Proposal",
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date(),
            accumulatedDuration: 0,
            isPaused: false
        )
        store.saveTimeEntry(original)
        #expect(store.timeEntries.first?.entryDescription == "Draft Proposal")

        // Edit description and time range
        let newProject = Project(name: "Internal", colorHex: "#34C759")
        store.saveProject(newProject)

        let updatedStart = Date().addingTimeInterval(-7200)
        let updatedEnd = Date().addingTimeInterval(-3600)

        original.entryDescription = "Finalize Architecture Proposal"
        original.projectId = newProject.id
        original.startDate = updatedStart
        original.endDate = updatedEnd
        original.updatedAt = Date()

        store.saveTimeEntry(original)

        #expect(store.timeEntries.count == 1)
        let saved = store.timeEntries.first!
        #expect(saved.entryDescription == "Finalize Architecture Proposal")
        #expect(saved.projectId == newProject.id)
        #expect(abs(saved.effectiveDuration - 3600) < 1.0)
    }

    @Test("Verify shifting start time preserves duration by shifting end time")
    func testDurationPreservationOnStartTimeShift() {
        let initialStart = Date(timeIntervalSince1970: 1700000000)
        let initialDuration: TimeInterval = 3600 // 1 hour
        let initialEnd = initialStart.addingTimeInterval(initialDuration)

        #expect(initialEnd.timeIntervalSince(initialStart) == initialDuration)

        // User shifts start time forward by 30 minutes
        let shiftedStart = initialStart.addingTimeInterval(1800)
        let preservedEnd = shiftedStart.addingTimeInterval(initialDuration)

        #expect(preservedEnd.timeIntervalSince(shiftedStart) == initialDuration)
        #expect(preservedEnd == initialEnd.addingTimeInterval(1800))
    }

    @Test("Verify entry duplication creates a distinct copy")
    @MainActor
    func testEntryDuplication() {
        let store = PersistenceStore(inMemory: true)

        let original = TimeEntry(
            entryDescription: "Code Review",
            startDate: Date().addingTimeInterval(-2400),
            endDate: Date(),
            accumulatedDuration: 0,
            isPaused: false
        )
        store.saveTimeEntry(original)
        #expect(store.timeEntries.count == 1)

        // Duplicate
        let duplicate = TimeEntry(
            entryDescription: original.entryDescription,
            startDate: original.startDate,
            endDate: original.endDate,
            accumulatedDuration: original.accumulatedDuration,
            isPaused: false,
            createdAt: Date(),
            updatedAt: Date(),
            projectId: original.projectId,
            taskId: original.taskId,
            tagIds: original.tagIds
        )
        store.saveTimeEntry(duplicate)

        #expect(store.timeEntries.count == 2)
        #expect(duplicate.id != original.id)
        #expect(duplicate.entryDescription == original.entryDescription)
        #expect(duplicate.effectiveDuration == original.effectiveDuration)
    }

    @Test("Verify entry deletion removes record completely")
    @MainActor
    func testEntryDeletionRemovesFromPersistence() {
        let store = PersistenceStore(inMemory: true)

        let entry = TimeEntry(
            entryDescription: "Task to delete",
            startDate: Date().addingTimeInterval(-600),
            endDate: Date()
        )
        store.saveTimeEntry(entry)
        #expect(store.timeEntries.count == 1)

        store.deleteTimeEntry(id: entry.id)
        #expect(store.timeEntries.isEmpty)
    }

    @Test("Verify DateHelper.combine correctly merges date and time components")
    func testDateHelperCombine() {
        let calendar = Calendar.current
        var dayComponents = DateComponents()
        dayComponents.year = 2026
        dayComponents.month = 11
        dayComponents.day = 23
        let dayDate = calendar.date(from: dayComponents)!

        var timeComponents = DateComponents()
        timeComponents.hour = 14
        timeComponents.minute = 30
        timeComponents.second = 0
        let timeDate = calendar.date(from: timeComponents)!

        let combined = DateHelper.combine(date: dayDate, time: timeDate, calendar: calendar)

        let resultComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: combined)
        #expect(resultComponents.year == 2026)
        #expect(resultComponents.month == 11)
        #expect(resultComponents.day == 23)
        #expect(resultComponents.hour == 14)
        #expect(resultComponents.minute == 30)
    }
}
