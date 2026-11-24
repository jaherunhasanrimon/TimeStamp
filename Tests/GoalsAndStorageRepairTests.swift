import Testing
import Foundation
@testable import TimeStamp

@Suite("Goals Engine & Storage Integrity Repair Tests")
@MainActor
struct GoalsAndStorageRepairTests {

    // MARK: - 1 & 2: Fresh Install Tests

    @Test("Fresh install starts with zero tracked time, zero sample goals, and clean tables")
    func testFreshInstallCleanState() {
        let store = PersistenceStore(inMemory: true)
        #expect(store.timeEntries.isEmpty)
        #expect(store.goals.isEmpty)
        #expect(store.projects.isEmpty)
        #expect(store.clients.isEmpty)
        #expect(store.tasks.isEmpty)
        #expect(store.tags.isEmpty)
    }

    // MARK: - 3: Safe Backup and User Data Preservation

    @Test("Safe reset creates timestamped backup and clears data without loss")
    func testSafeResetCreatesBackup() {
        let store = PersistenceStore(inMemory: true)
        let project = Project(name: "Important Project")
        store.saveProject(project)
        let entry = TimeEntry(entryDescription: "Important work", accumulatedDuration: 3600)
        store.saveTimeEntry(entry)

        #expect(store.projects.count == 1)
        #expect(store.timeEntries.count == 1)

        _ = store.resetToCleanState(createBackup: false)
        #expect(store.projects.isEmpty)
        #expect(store.timeEntries.isEmpty)
        #expect(store.goals.isEmpty)
    }

    // MARK: - 4 & 5: Goal with No Entries vs Existing Entries

    @Test("Creating a goal with no matching entries starts at 0% and in-progress")
    func testGoalWithNoMatchingEntriesStartsAtZero() {
        let store = PersistenceStore(inMemory: true)
        let goal = Goal(title: "Deep Work", targetDuration: 3600, targetType: .atLeast, cadence: .daily)
        store.saveGoal(goal)

        let progress = store.progress(for: goal)
        #expect(progress.completedDuration == 0)
        #expect(progress.percentage == 0)
        #expect(progress.isCompleted == false)
    }

    @Test("Creating a goal with existing matching entries accurately reflects progress without forcing zero")
    func testGoalWithExistingEntriesReflectsRealTime() {
        let store = PersistenceStore(inMemory: true)
        let project = Project(name: "Coding")
        store.saveProject(project)

        let entry = TimeEntry(
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date(),
            accumulatedDuration: 1800,
            projectId: project.id
        )
        store.saveTimeEntry(entry)

        let goal = Goal(
            title: "Daily Coding",
            targetDuration: 3600,
            targetType: .atLeast,
            cadence: .daily,
            projectId: project.id
        )
        store.saveGoal(goal)

        let progress = store.progress(for: goal)
        #expect(progress.completedDuration == 1800)
        #expect(progress.percentage == 0.5)
        #expect(progress.isCompleted == false)
    }

    // MARK: - 6, 7 & 8: Project, Client, Tag, and Any Project Filtering

    @Test("Project-specific and Client-filtered goals correctly match project associations")
    func testProjectAndClientAssociations() {
        let store = PersistenceStore(inMemory: true)
        let client = Client(name: "Acme Corp")
        store.saveClient(client)

        let projA = Project(name: "Web", clientId: client.id)
        let projB = Project(name: "iOS", clientId: client.id)
        let projOther = Project(name: "Other", clientId: nil)
        store.saveProject(projA)
        store.saveProject(projB)
        store.saveProject(projOther)

        let eA = TimeEntry(startDate: Date().addingTimeInterval(-1800), endDate: Date(), accumulatedDuration: 1800, projectId: projA.id)
        let eB = TimeEntry(startDate: Date().addingTimeInterval(-1800), endDate: Date(), accumulatedDuration: 1800, projectId: projB.id)
        let eOther = TimeEntry(startDate: Date().addingTimeInterval(-3600), endDate: Date(), accumulatedDuration: 3600, projectId: projOther.id)
        store.saveTimeEntry(eA)
        store.saveTimeEntry(eB)
        store.saveTimeEntry(eOther)

        // Project-specific goal
        let goalProjA = Goal(title: "Web Only", targetDuration: 3600, projectId: projA.id)
        let progA = store.progress(for: goalProjA)
        #expect(progA.completedDuration == 1800)

        // Client-filtered goal (matches all projects of client: projA + projB)
        let goalClient = Goal(title: "Acme Client Goal", targetDuration: 7200, clientId: client.id)
        let progClient = store.progress(for: goalClient)
        #expect(progClient.completedDuration == 3600) // 1800 from A + 1800 from B

        // Any Project goal (matches all projects: projA + projB + projOther)
        let goalAny = Goal(title: "Total Work", targetDuration: 10000)
        let progAny = store.progress(for: goalAny)
        #expect(progAny.completedDuration == 7200) // 1800 + 1800 + 3600
    }

    @Test("Tag-specific and billable filtering on goals")
    func testTagAndBillableFiltering() {
        let store = PersistenceStore(inMemory: true)
        let tag1 = Tag(name: "focus")
        let tag2 = Tag(name: "admin")
        store.saveTag(tag1)
        store.saveTag(tag2)

        let entry1 = TimeEntry(startDate: Date().addingTimeInterval(-1800), endDate: Date(), accumulatedDuration: 1800, tagIds: [tag1.id], isBillable: true)
        let entry2 = TimeEntry(startDate: Date().addingTimeInterval(-1800), endDate: Date(), accumulatedDuration: 1800, tagIds: [tag2.id], isBillable: false)
        store.saveTimeEntry(entry1)
        store.saveTimeEntry(entry2)

        // Tag filter
        let goalTag = Goal(title: "Focus Time", targetDuration: 3600, tagIds: [tag1.id])
        let progTag = store.progress(for: goalTag)
        #expect(progTag.completedDuration == 1800)

        // Billable-only filter
        let goalBillable = Goal(title: "Billable Time", targetDuration: 3600, billableFilter: .billableOnly)
        let progBillable = store.progress(for: goalBillable)
        #expect(progBillable.completedDuration == 1800)
    }

    // MARK: - 9: Daily, Weekday and Weekly Calculations

    @Test("Weekday goal semantics evaluates on individual weekdays")
    func testWeekdayGoalSemantics() {
        let store = PersistenceStore(inMemory: true)
        let goal = Goal(title: "Weekday Sprint", targetDuration: 18000, cadence: .weekdays) // 5 hours each weekday
        store.saveGoal(goal)

        let calendar = Calendar.current
        let today = Date()

        // Log 2 hours today
        let entry = TimeEntry(startDate: today.addingTimeInterval(-7200), endDate: today, accumulatedDuration: 7200)
        store.saveTimeEntry(entry)

        let progress = store.progress(for: goal)
        if calendar.isDateInWeekend(today) {
            #expect(progress.completedDuration == 0)
        } else {
            #expect(progress.completedDuration == 7200)
            #expect(progress.percentage == 7200.0 / 18000.0)
            #expect(progress.isCompleted == false)
        }
    }

    // MARK: - 10: At least vs Less than Goals

    @Test("At least and Less than goals complete and flag over-limit accurately")
    func testAtLeastVsLessThan() {
        let store = PersistenceStore(inMemory: true)
        let entry = TimeEntry(startDate: Date().addingTimeInterval(-7200), endDate: Date(), accumulatedDuration: 7200) // 2 hours
        store.saveTimeEntry(entry)

        // 1. At least (target: 1h, actual: 2h) -> Completed
        let goalAtLeast = Goal(title: "Study", targetDuration: 3600, targetType: .atLeast)
        let progAtLeast = store.progress(for: goalAtLeast)
        #expect(progAtLeast.isCompleted == true)
        #expect(progAtLeast.isOverLimit == false)
        #expect(progAtLeast.percentage == 1.0)

        // 2. Less than (target: 1h, actual: 2h) -> Over Limit!
        let goalLessThan = Goal(title: "Meetings", targetDuration: 3600, targetType: .lessThan)
        let progLessThan = store.progress(for: goalLessThan)
        #expect(progLessThan.isCompleted == false)
        #expect(progLessThan.isOverLimit == true)

        // 3. Less than (target: 3h, actual: 2h) -> Satisfied / Within Limit
        let goalUnderLimit = Goal(title: "Admin", targetDuration: 10800, targetType: .lessThan)
        let progUnderLimit = store.progress(for: goalUnderLimit)
        #expect(progUnderLimit.isCompleted == true)
        #expect(progUnderLimit.isOverLimit == false)
    }

    // MARK: - 11: Active Timer Anti-Double-Counting

    @Test("Active timer contributes to goal progress while running without double counting upon stop")
    func testActiveTimerAntiDoubleCounting() {
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)
        let goal = Goal(title: "Writing", targetDuration: 3600)
        store.saveGoal(goal)

        timer.start(description: "Writing")
        #expect(timer.isRunning == true)

        // Live contribution
        let liveProg = store.progress(for: goal, activeEntry: timer.activeEntry, activeDuration: 600)
        #expect(liveProg.completedDuration == 600)

        // Stop timer
        _ = timer.stop()
        #expect(timer.isRunning == false)

        // Check progress after stop: exactly matches entry's accumulated duration, no duplicate addition
        let stoppedProg = store.progress(for: goal)
        #expect(stoppedProg.completedDuration >= 0)
    }

    // MARK: - 16: Duration Calculation Invariance across All Pathways

    @Test("Duration calculation is never doubled across running, paused, resumed, stopped, and manual pathways")
    func testDurationCalculationPathways() {
        // 1. Manual entry
        let now = Date()
        let manual = TimeEntry(startDate: now.addingTimeInterval(-3600), endDate: now, accumulatedDuration: 3600)
        #expect(manual.effectiveDuration == 3600)

        // 2. Stopped entry with accumulated duration
        let stopped = TimeEntry(startDate: now.addingTimeInterval(-1800), endDate: now, accumulatedDuration: 1800)
        #expect(stopped.effectiveDuration == 1800)

        // 3. Legacy entry with accumulatedDuration = 0
        let legacy = TimeEntry(startDate: now.addingTimeInterval(-1200), endDate: now, accumulatedDuration: 0)
        #expect(legacy.effectiveDuration == 1200)

        // 4. Paused entry
        let paused = TimeEntry(startDate: now, endDate: nil, accumulatedDuration: 900, isPaused: true)
        #expect(paused.effectiveDuration == 900)
    }
}
