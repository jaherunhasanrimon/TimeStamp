import Testing
import Foundation
@testable import TimeStamp

@Suite("Priority 3: Billable Tracking & Tags Engine Tests")
@MainActor
struct BillableAndTagsTests {

    // MARK: - Part A: Billable Tracking Tests

    @Test("Billable flag is passed to TimerManager.start and saved in TimeEntry")
    func testBillableFlagPassedAndPersisted() {
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)

        timer.start(description: "Client Meeting", isBillable: true)
        #expect(timer.activeEntry != nil)
        #expect(timer.activeEntry?.isBillable == true)
        #expect(timer.retainedIsBillable == true)

        let stopped = timer.stop()
        #expect(stopped != nil)
        #expect(stopped?.isBillable == true)

        let saved = store.timeEntries.first(where: { $0.id == stopped?.id })
        #expect(saved != nil)
        #expect(saved?.isBillable == true)
    }

    @Test("Billable status survives rehydration and restoreActiveSession")
    func testBillableRestoresOnRestart() {
        let store = PersistenceStore(inMemory: true)
        let runningEntry = TimeEntry(
            entryDescription: "Consulting",
            startDate: Date().addingTimeInterval(-1800),
            endDate: nil,
            accumulatedDuration: 0,
            isPaused: false,
            isBillable: true
        )
        store.saveTimeEntry(runningEntry)

        let timer = TimerManager(store: store)
        timer.restoreActiveSession()

        #expect(timer.activeEntry != nil)
        #expect(timer.activeEntry?.isBillable == true)
        #expect(timer.retainedIsBillable == true)
    }

    @Test("Billable amounts calculate correctly with Project, Client, and Default rates")
    func testHourlyRateCalculations() {
        let store = PersistenceStore(inMemory: true)

        // Client with $100/hr
        let client = Client(name: "Acme Corp", hourlyRate: 100.0)
        store.saveClient(client)

        // Project 1 inherits client rate ($100/hr) because project rate is nil
        let proj1 = Project(name: "Website", colorHex: "#E54583", hourlyRate: nil, clientId: client.id)
        store.saveProject(proj1)

        // Project 2 has custom project rate override of $150/hr
        let proj2 = Project(name: "Mobile App", colorHex: "#36B37E", hourlyRate: 150.0, clientId: client.id)
        store.saveProject(proj2)

        // Project 3 has no client and no hourlyRate -> should fallback to $50/hr default
        let proj3 = Project(name: "Internal R&D", colorHex: "#06B6D4", hourlyRate: nil, clientId: nil)
        store.saveProject(proj3)

        // 2 hours on Project 1 (Rate: $100 -> $200)
        let entry1 = TimeEntry(
            startDate: Date().addingTimeInterval(-7200),
            endDate: Date(),
            projectId: proj1.id,
            isBillable: true
        )
        entry1.accumulatedDuration = 7200
        store.saveTimeEntry(entry1)

        // 1 hour on Project 2 (Rate: $150 -> $150)
        let entry2 = TimeEntry(
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            projectId: proj2.id,
            isBillable: true
        )
        entry2.accumulatedDuration = 3600
        store.saveTimeEntry(entry2)

        // 1 hour on Project 3 (Default Rate: $50 -> $50)
        let entry3 = TimeEntry(
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            projectId: proj3.id,
            isBillable: true
        )
        entry3.accumulatedDuration = 3600
        store.saveTimeEntry(entry3)

        // Non-billable entry (should contribute $0)
        let entryNonBillable = TimeEntry(
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            projectId: proj2.id,
            isBillable: false
        )
        entryNonBillable.accumulatedDuration = 3600
        store.saveTimeEntry(entryNonBillable)

        // Helper rate calculator matching ReportsView
        func calculateAmount(for entry: TimeEntry) -> Double {
            guard entry.isBillable else { return 0.0 }
            var rate: Double = 50.0
            if let pId = entry.projectId, let p = store.project(for: pId) {
                if let pRate = p.hourlyRate {
                    rate = pRate
                } else if let cId = p.clientId, let c = store.client(for: cId), let cRate = c.hourlyRate {
                    rate = cRate
                }
            }
            return (entry.effectiveDuration / 3600.0) * rate
        }

        #expect(calculateAmount(for: entry1) == 200.0)
        #expect(calculateAmount(for: entry2) == 150.0)
        #expect(calculateAmount(for: entry3) == 50.0)
        #expect(calculateAmount(for: entryNonBillable) == 0.0)

        let totalRevenue = [entry1, entry2, entry3, entryNonBillable].reduce(0.0) { $0 + calculateAmount(for: $1) }
        #expect(totalRevenue == 400.0)
    }

    // MARK: - Part B: Tag Management Tests

    @Test("Tag creation, unique case-insensitive validation and deletion")
    func testTagLifecycle() {
        let store = PersistenceStore(inMemory: true)

        let tag1 = Tag(name: "design", colorHex: "#E54583")
        store.saveTag(tag1)
        #expect(store.tags.count == 1)
        #expect(store.tag(for: tag1.id)?.name == "design")

        // Duplicate check logic
        let duplicateName = "Design"
        let isDuplicate = store.tags.contains { $0.name.caseInsensitiveCompare(duplicateName) == .orderedSame }
        #expect(isDuplicate == true)

        let tag2 = Tag(name: "dev", colorHex: "#36B37E")
        store.saveTag(tag2)
        #expect(store.tags.count == 2)

        store.deleteTag(id: tag1.id)
        #expect(store.tags.count == 1)
        #expect(store.tag(for: tag1.id) == nil)
        #expect(store.tag(for: tag2.id)?.name == "dev")
    }

    @Test("Multiple tag attachment to active timer and persistence on stop")
    func testMultiTagAttachmentAndPersistence() {
        let store = PersistenceStore(inMemory: true)
        let tag1 = Tag(name: "frontend")
        let tag2 = Tag(name: "urgent")
        store.saveTag(tag1)
        store.saveTag(tag2)

        let timer = TimerManager(store: store)
        timer.start(
            description: "Fixing layout",
            tagIds: [tag1.id, tag2.id],
            isBillable: true
        )

        #expect(timer.activeEntry?.tagIds.count == 2)
        #expect(timer.activeEntry?.tagIds.contains(tag1.id) == true)
        #expect(timer.activeEntry?.tagIds.contains(tag2.id) == true)
        #expect(timer.retainedTagIds.count == 2)

        let stopped = timer.stop()
        #expect(stopped?.tagIds.count == 2)
        #expect(stopped?.isBillable == true)

        // Continue entry verifies tags are inherited
        timer.continueEntry(stopped!)
        #expect(timer.activeEntry?.tagIds == [tag1.id, tag2.id])
        #expect(timer.activeEntry?.isBillable == true)
    }

    @Test("Deleting a tag purges its reference from historical entries without data corruption")
    func testTagCascadeDeletionSafety() {
        let store = PersistenceStore(inMemory: true)
        let tag = Tag(name: "temporary")
        store.saveTag(tag)

        let entry = TimeEntry(
            entryDescription: "Task with temp tag",
            startDate: Date().addingTimeInterval(-1000),
            endDate: Date(),
            tagIds: [tag.id],
            isBillable: false
        )
        store.saveTimeEntry(entry)

        #expect(entry.tagIds.contains(tag.id) == true)

        // Delete tag from store
        store.deleteTag(id: tag.id)

        #expect(store.tags.isEmpty)
        let refreshedEntry = store.timeEntries.first(where: { $0.id == entry.id })
        #expect(refreshedEntry != nil)
        #expect(refreshedEntry?.tagIds.isEmpty == true)
    }

    @Test("Filtering entries by Tag correctly filters the list")
    func testTagFiltering() {
        let store = PersistenceStore(inMemory: true)
        let tagA = Tag(name: "marketing")
        let tagB = Tag(name: "engineering")
        store.saveTag(tagA)
        store.saveTag(tagB)

        let entryA = TimeEntry(entryDescription: "Ad Campaign", tagIds: [tagA.id])
        let entryB = TimeEntry(entryDescription: "API Server", tagIds: [tagB.id])
        let entryBoth = TimeEntry(entryDescription: "Product Launch", tagIds: [tagA.id, tagB.id])
        let entryNone = TimeEntry(entryDescription: "Coffee break", tagIds: [])

        store.saveTimeEntry(entryA)
        store.saveTimeEntry(entryB)
        store.saveTimeEntry(entryBoth)
        store.saveTimeEntry(entryNone)

        func filterEntries(_ filter: EntryFilter) -> [TimeEntry] {
            switch filter {
            case .none:
                return store.timeEntries
            case .project(let id):
                return store.timeEntries.filter { $0.projectId == id }
            case .client(let id):
                let cProjectIds = Set(store.projects.filter { $0.clientId == id }.map { $0.id })
                return store.timeEntries.filter { $0.projectId.map { cProjectIds.contains($0) } ?? false }
            case .tag(let id):
                return store.timeEntries.filter { $0.tagIds.contains(id) }
            case .billableOnly:
                return store.timeEntries.filter { $0.isBillable }
            case .nonBillableOnly:
                return store.timeEntries.filter { !$0.isBillable }
            }
        }

        let filterA = EntryFilter.tag(tagA.id)
        let filteredA = filterEntries(filterA)
        #expect(filteredA.count == 2)
        #expect(filteredA.contains(where: { $0.id == entryA.id }))
        #expect(filteredA.contains(where: { $0.id == entryBoth.id }))

        let filterB = EntryFilter.tag(tagB.id)
        let filteredB = filterEntries(filterB)
        #expect(filteredB.count == 2)
        #expect(filteredB.contains(where: { $0.id == entryB.id }))
        #expect(filteredB.contains(where: { $0.id == entryBoth.id }))
    }

    // MARK: - Part C: Regression Tests

    @Test("Goals engine and Pomodoro engine operate normally alongside Billable and Tags")
    func testGoalsAndPomodoroRegression() {
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)
        let pomodoro = PomodoroManager(timerManager: timer)

        // 1. Pomodoro start
        pomodoro.start(description: "Sprint")
        #expect(pomodoro.isRunning == true)
        #expect(pomodoro.sessionType == .work)

        // 2. Goal creation
        let goal = Goal(title: "Dev Sprint", targetDuration: 3600, cadence: .daily)
        store.saveGoal(goal)
        #expect(store.goals.count == 1)

        // 3. Billable & Tagged timer session
        let tag = Tag(name: "deep-work")
        store.saveTag(tag)

        timer.start(description: "Dev Sprint", tagIds: [tag.id], isBillable: true)
        #expect(timer.isRunning == true)
        #expect(timer.activeEntry?.isBillable == true)
        #expect(timer.activeEntry?.tagIds == [tag.id])

        // Verify goal progress tracks the active session (allowing sub-second elapsed from prior stopped Pomodoro entry)
        let progress = store.progress(for: goal, activeEntry: timer.activeEntry, activeDuration: 600)
        #expect(abs(progress.completedDuration - 600) < 1.0)
        #expect(progress.isCompleted == false)

        _ = timer.stop()
        pomodoro.reset()
    }
}
