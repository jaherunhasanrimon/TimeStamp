import Testing
@testable import TimeStamp
import Foundation

@Suite("Phase 4: Goals Multi-Project & Date Bounds + Pomodoro Parity Tests")
@MainActor
struct Phase4GoalsPomodoroTests {

    @Test("Multi-project goals aggregate matching entries across selected projects and support unlimited goals")
    func multiProjectAndUnlimitedGoals() {
        let store = PersistenceStore(inMemory: true)
        let cal = Calendar.current
        let now = Date()

        let projA = Project(name: "Python DS", colorHex: "#E54583")
        let projB = Project(name: "MATHS", colorHex: "#36B37E")
        let projC = Project(name: "Other", colorHex: "#5C3BFE")
        store.saveProject(projA)
        store.saveProject(projB)
        store.saveProject(projC)

        // Create 6 goals (no artificial 4-goal paywall!)
        for idx in 1...5 {
            store.saveGoal(Goal(title: "Free Goal \(idx)", targetDuration: 1800))
        }
        let multiGoal = Goal(
            title: "Python + MATHS",
            targetDuration: 9000, // 2.5 hrs
            cadence: .daily,
            projectIds: [projA.id, projB.id]
        )
        store.saveGoal(multiGoal)
        #expect(store.goals.count == 6)

        let eA = TimeEntry(
            entryDescription: "Pandas",
            startDate: cal.date(byAdding: .hour, value: -3, to: now)!,
            endDate: cal.date(byAdding: .hour, value: -1, to: now)!, // 2h
            accumulatedDuration: 7200,
            projectId: projA.id
        )
        let eB = TimeEntry(
            entryDescription: "Linear Algebra",
            startDate: cal.date(byAdding: .minute, value: -50, to: now)!,
            endDate: cal.date(byAdding: .minute, value: -20, to: now)!, // 0.5h
            accumulatedDuration: 1800,
            projectId: projB.id
        )
        let eC = TimeEntry(
            entryDescription: "Unrelated",
            startDate: cal.date(byAdding: .minute, value: -15, to: now)!,
            endDate: now,
            accumulatedDuration: 900,
            projectId: projC.id
        )
        store.saveTimeEntry(eA)
        store.saveTimeEntry(eB)
        store.saveTimeEntry(eC)

        let prog = store.progress(for: multiGoal, in: cal, now: now)
        #expect(abs(prog.completedDuration - 9000) < 0.01)
        #expect(prog.isCompleted == true)
        #expect(prog.percentage == 1.0)
    }

    @Test("Goal UNTIL endDate stops tracking progress after expiration day and legacy Codable decodes cleanly")
    func goalEndDateAndCodable() throws {
        let store = PersistenceStore(inMemory: true)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let proj = Project(name: "Sprint", colorHex: "#30D158")
        store.saveProject(proj)

        let entryToday = TimeEntry(
            entryDescription: "Work",
            startDate: today.addingTimeInterval(3600),
            endDate: today.addingTimeInterval(7200),
            accumulatedDuration: 3600,
            projectId: proj.id
        )
        store.saveTimeEntry(entryToday)

        let expiredGoal = Goal(
            title: "Ended Yesterday",
            targetDuration: 3600,
            projectIds: [proj.id],
            startDate: cal.date(byAdding: .day, value: -7, to: today)!,
            endDate: yesterday
        )
        store.saveGoal(expiredGoal)

        let progAfterEnd = store.progress(for: expiredGoal, in: cal, now: today.addingTimeInterval(8000))
        #expect(progAfterEnd.completedDuration == 0)
        #expect(progAfterEnd.isCompleted == false)

        // Legacy Goal without projectIds/startDate/endDate decodes backward-compatibly
        let legacyId = UUID()
        let legacyProjId = UUID()
        let legacyJSON = """
        {
            "id": "\(legacyId.uuidString)",
            "title": "Legacy Goal",
            "targetDuration": 3600,
            "targetType": "at least",
            "cadence": "every day",
            "projectId": "\(legacyProjId.uuidString)",
            "iconName": "target",
            "createdAt": "2026-10-01T10:00:00Z",
            "updatedAt": "2026-10-01T10:00:00Z"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Goal.self, from: legacyJSON)
        #expect(decoded.projectId == legacyProjId)
        #expect(decoded.effectiveProjectIds == [legacyProjId])
        #expect(decoded.endDate == nil)

        // Production v1.x canonical raw values also decode seamlessly
        let prodJSON = """
        {
            "id": "\(UUID().uuidString)",
            "title": "Research",
            "targetDuration": 3600,
            "targetType": "At least",
            "cadence": "Daily",
            "billableFilter": "All Entries",
            "iconName": "target",
            "createdAt": "2026-10-01T10:00:00Z",
            "updatedAt": "2026-10-01T10:00:00Z"
        }
        """.data(using: .utf8)!
        let prodDecoded = try decoder.decode(Goal.self, from: prodJSON)
        #expect(prodDecoded.targetType == .atLeast)
        #expect(prodDecoded.cadence == .daily)
        #expect(prodDecoded.billableFilter == .all)
    }

    @Test("Pomodoro Focus intent integrates with TimerManager, supports count-up display & auto-start")
    func pomodoroFocusIntentCountUpAndAutoStart() {
        let store = PersistenceStore(inMemory: true)
        let proj = Project(name: "Deep Focus", colorHex: "#E54583")
        store.saveProject(proj)
        let timer = TimerManager(store: store)
        let pomo = PomodoroManager(timerManager: timer)

        pomo.updateFocusIntent(
            description: "Write paper",
            projectId: proj.id,
            taskId: nil,
            tagIds: [],
            isBillable: true
        )
        pomo.countUpMode = true
        pomo.workDuration = 120

        #expect(pomo.formattedDisplayTime == "00:00")

        pomo.start()
        #expect(pomo.isRunning == true)
        #expect(timer.activeEntry?.entryDescription == "Write paper")
        #expect(timer.activeEntry?.projectId == proj.id)
        #expect(timer.activeEntry?.isBillable == true)

        pomo.autoStartBreaks = true
        pomo.skip()
        #expect(pomo.sessionType == .shortBreak)
        #expect(pomo.isRunning == false) // skip resets cleanly; timer stopped
        #expect(timer.activeEntry == nil)
    }
}
