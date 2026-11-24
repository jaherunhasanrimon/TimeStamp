import Testing
import Foundation
@testable import TimeStamp

@MainActor
struct GoalEngineTests {
    @Test func goalCreationEditingAndDeletion() {
        let store = PersistenceStore(inMemory: true)
        #expect(store.goals.isEmpty)

        // 1. Create
        let goal = Goal(
            title: "SwiftUI Practice",
            targetDuration: 3600,
            cadence: .daily,
            iconName: "desktopcomputer"
        )
        store.saveGoal(goal)
        #expect(store.goals.count == 1)
        #expect(store.goals.first?.title == "SwiftUI Practice")
        #expect(store.goals.first?.targetDuration == 3600)
        #expect(store.goals.first?.cadence == .daily)

        // 2. Edit
        goal.title = "Advanced SwiftUI Practice"
        goal.targetDuration = 7200
        goal.cadence = .weekly
        store.saveGoal(goal)
        #expect(store.goals.count == 1)
        #expect(store.goals.first?.title == "Advanced SwiftUI Practice")
        #expect(store.goals.first?.targetDuration == 7200)
        #expect(store.goals.first?.cadence == .weekly)

        // 3. Delete
        store.deleteGoal(id: goal.id)
        #expect(store.goals.isEmpty)
    }

    @Test func dailyProgressCalculationWithCompletedEntries() {
        let store = PersistenceStore(inMemory: true)
        let calendar = Calendar.current
        let now = Date()

        let project = Project(name: "Client Alpha", colorHex: "#E54583")
        store.saveProject(project)

        let goal = Goal(
            title: "Daily Client Work",
            targetDuration: 3600, // 1 hour
            cadence: .daily,
            projectId: project.id
        )
        store.saveGoal(goal)

        // Initially 0
        var prog = store.progress(for: goal, in: calendar, now: now)
        #expect(prog.completedDuration == 0)
        #expect(prog.percentage == 0)
        #expect(prog.isCompleted == false)

        // Add 30-minute completed entry
        let entry1 = TimeEntry(
            entryDescription: "Task 1",
            startDate: calendar.date(byAdding: .hour, value: -2, to: now)!,
            endDate: calendar.date(byAdding: .minute, value: -90, to: now)!, // 30 min duration
            accumulatedDuration: 0,
            projectId: project.id
        )
        store.saveTimeEntry(entry1)

        prog = store.progress(for: goal, in: calendar, now: now)
        #expect(prog.completedDuration == 1800)
        #expect(prog.percentage == 0.5)
        #expect(prog.isCompleted == false)

        // Add another 30-minute entry -> 1 hour total
        let entry2 = TimeEntry(
            entryDescription: "Task 2",
            startDate: calendar.date(byAdding: .minute, value: -60, to: now)!,
            endDate: calendar.date(byAdding: .minute, value: -30, to: now)!,
            accumulatedDuration: 0,
            projectId: project.id
        )
        store.saveTimeEntry(entry2)

        prog = store.progress(for: goal, in: calendar, now: now)
        #expect(prog.completedDuration == 3600)
        #expect(prog.percentage == 1.0)
        #expect(prog.isCompleted == true)
    }

    @Test func weeklyProgressCalculationAcrossDates() {
        let store = PersistenceStore(inMemory: true)
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday start

        let now = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        let monday = calendar.date(from: components)!

        let goal = Goal(
            title: "Weekly Engineering Sprint",
            targetDuration: 18000, // 5 hours
            cadence: .weekly
        )
        store.saveGoal(goal)

        // Monday entry: 2 hours (7200s)
        let mondayEntry = TimeEntry(
            entryDescription: "Sprint planning",
            startDate: calendar.date(byAdding: .hour, value: 9, to: monday)!,
            endDate: calendar.date(byAdding: .hour, value: 11, to: monday)!,
            accumulatedDuration: 0
        )
        store.saveTimeEntry(mondayEntry)

        // Wednesday entry: 3 hours (10800s)
        let wednesday = calendar.date(byAdding: .day, value: 2, to: monday)!
        let wednesdayEntry = TimeEntry(
            entryDescription: "Core feature work",
            startDate: calendar.date(byAdding: .hour, value: 10, to: wednesday)!,
            endDate: calendar.date(byAdding: .hour, value: 13, to: wednesday)!,
            accumulatedDuration: 0
        )
        store.saveTimeEntry(wednesdayEntry)

        // Previous week entry (should NOT be counted)
        let prevWeek = calendar.date(byAdding: .day, value: -3, to: monday)!
        let oldEntry = TimeEntry(
            entryDescription: "Old work",
            startDate: prevWeek,
            endDate: calendar.date(byAdding: .hour, value: 2, to: prevWeek)!,
            accumulatedDuration: 0
        )
        store.saveTimeEntry(oldEntry)

        let prog = store.progress(for: goal, in: calendar, now: now)
        #expect(prog.completedDuration == 18000)
        #expect(prog.percentage == 1.0)
        #expect(prog.isCompleted == true)
    }

    @Test func liveProgressWithRunningActiveTimer() {
        let store = PersistenceStore(inMemory: true)
        let calendar = Calendar.current
        let now = Date()

        let project = Project(name: "Design System", colorHex: "#BF5AF2")
        store.saveProject(project)

        let goal = Goal(
            title: "Design System Sprint",
            targetDuration: 3600, // 1 hour
            cadence: .daily,
            projectId: project.id
        )
        store.saveGoal(goal)

        // Completed 30 min (1800s)
        let completed = TimeEntry(
            entryDescription: "Figma tokens",
            startDate: calendar.date(byAdding: .hour, value: -1, to: now)!,
            endDate: calendar.date(byAdding: .minute, value: -30, to: now)!,
            accumulatedDuration: 0,
            projectId: project.id
        )
        store.saveTimeEntry(completed)

        // Running active timer with 10 min (600s)
        let active = TimeEntry(
            entryDescription: "SwiftUI components",
            startDate: now,
            projectId: project.id
        )

        let prog = store.progress(
            for: goal,
            in: calendar,
            now: now,
            activeEntry: active,
            activeDuration: 600
        )

        #expect(prog.completedDuration == 2400) // 1800 + 600
        #expect(abs(prog.percentage - (2400.0 / 3600.0)) < 0.001)
        #expect(prog.isCompleted == false)
    }

    @Test func goalWithNoProjectTracksAllLoggedTime() {
        let store = PersistenceStore(inMemory: true)
        let now = Date()

        let p1 = Project(name: "Project A", colorHex: "#FF9F0A")
        let p2 = Project(name: "Project B", colorHex: "#0A84FF")
        store.saveProject(p1)
        store.saveProject(p2)

        let generalGoal = Goal(
            title: "Daily Total Work",
            targetDuration: 7200, // 2 hours
            cadence: .daily,
            projectId: nil // Tracks all projects
        )
        store.saveGoal(generalGoal)

        // 1 hr on Project A
        let entry1 = TimeEntry(
            entryDescription: "Work on A",
            startDate: now,
            endDate: now.addingTimeInterval(3600),
            accumulatedDuration: 0,
            projectId: p1.id
        )
        // 1 hr on Project B
        let entry2 = TimeEntry(
            entryDescription: "Work on B",
            startDate: now,
            endDate: now.addingTimeInterval(3600),
            accumulatedDuration: 0,
            projectId: p2.id
        )
        store.saveTimeEntry(entry1)
        store.saveTimeEntry(entry2)

        let prog = store.progress(for: generalGoal, now: now)
        #expect(prog.completedDuration == 7200)
        #expect(prog.percentage == 1.0)
        #expect(prog.isCompleted == true)
    }

    @Test func keepGoingInteractionAndDuplicatePrevention() {
        let store = PersistenceStore(inMemory: true)
        let timerManager = TimerManager(store: store)

        let project = Project(name: "Focus Track", colorHex: "#30D158")
        store.saveProject(project)

        let goal = Goal(
            title: "Focus Session",
            targetDuration: 3600,
            projectId: project.id
        )
        store.saveGoal(goal)

        #expect(timerManager.activeEntry == nil)

        // 1. Initial KEEP GOING starts timer
        timerManager.start(description: goal.title, projectId: goal.projectId)
        #expect(timerManager.isRunning == true)
        #expect(timerManager.activeEntry?.entryDescription == "Focus Session")
        #expect(timerManager.activeEntry?.projectId == project.id)

        let activeId = timerManager.activeEntry?.id

        // 2. Repeated trigger should NOT create duplicate timer
        if timerManager.activeEntry?.projectId == goal.projectId {
            if timerManager.isPaused {
                timerManager.resume()
            }
            // do not start another
        }
        #expect(timerManager.activeEntry?.id == activeId)

        // 3. Pause then resume via Keep Going logic
        timerManager.pause()
        #expect(timerManager.isPaused == true)

        if timerManager.activeEntry?.projectId == goal.projectId {
            if timerManager.isPaused {
                timerManager.resume()
            }
        }
        #expect(timerManager.isRunning == true)
        #expect(timerManager.isPaused == false)
        #expect(timerManager.activeEntry?.id == activeId)

        // Stop timer
        let stopped = timerManager.stop()
        #expect(stopped != nil)
        #expect(timerManager.activeEntry == nil)
    }

    @Test func projectDeletionUnlinksGoalGracefully() {
        let store = PersistenceStore(inMemory: true)
        let project = Project(name: "Temporary Project", colorHex: "#64D2FF")
        store.saveProject(project)

        let goal = Goal(
            title: "Project Milestone",
            targetDuration: 3600,
            projectId: project.id
        )
        store.saveGoal(goal)
        #expect(store.goals.first?.projectId == project.id)

        // Delete project
        store.deleteProject(id: project.id)

        // Goal is preserved, but projectId is safely unlinked to nil
        #expect(store.goals.count == 1)
        #expect(store.goals.first?.projectId == nil)
    }

    @Test func goalCodableSerialization() throws {
        let original = Goal(
            title: "Deep Work Sprint",
            targetDuration: 5400,
            cadence: .weekly,
            projectId: UUID(),
            iconName: "star.fill"
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Goal.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.title == original.title)
        #expect(decoded.targetDuration == original.targetDuration)
        #expect(decoded.cadence == original.cadence)
        #expect(decoded.projectId == original.projectId)
        #expect(decoded.iconName == original.iconName)
        #expect(decoded == original)
    }
}
