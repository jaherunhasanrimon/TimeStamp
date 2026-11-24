import Testing
import Foundation
@testable import TimeStamp

@MainActor
struct PomodoroEngineTests {
    @Test func initialStateAndDefaultDurations() {
        let store = PersistenceStore(inMemory: true)
        let timerManager = TimerManager(store: store)
        let pomodoro = PomodoroManager(timerManager: timerManager)

        #expect(pomodoro.workDuration == 25 * 60)
        #expect(pomodoro.shortBreakDuration == 5 * 60)
        #expect(pomodoro.longBreakDuration == 15 * 60)
        #expect(pomodoro.targetIntervalCount == 4)
        #expect(pomodoro.sessionType == .work)
        #expect(pomodoro.isRunning == false)
        #expect(pomodoro.isPaused == false)
        #expect(pomodoro.completedWorkSessions == 0)
        #expect(pomodoro.formattedRemainingTime == "25:00")
    }

    @Test func startPauseResumeControls() {
        let store = PersistenceStore(inMemory: true)
        let timerManager = TimerManager(store: store)
        let pomodoro = PomodoroManager(timerManager: timerManager)

        // Start
        pomodoro.start(description: "Writing Swift")
        #expect(pomodoro.isRunning == true)
        #expect(pomodoro.isPaused == false)
        #expect(timerManager.isRunning == true)
        #expect(timerManager.activeEntry?.entryDescription == "Writing Swift")

        // Pause
        pomodoro.pause()
        #expect(pomodoro.isPaused == true)
        #expect(timerManager.isPaused == true)

        // Resume
        pomodoro.resume()
        #expect(pomodoro.isPaused == false)
        #expect(timerManager.isRunning == true)
        #expect(timerManager.isPaused == false)

        // Reset
        pomodoro.reset()
        #expect(pomodoro.isRunning == false)
        #expect(pomodoro.isPaused == false)
        #expect(pomodoro.formattedRemainingTime == "25:00")
    }

    @Test func workSessionCompletionTransitionsToShortBreakAndStopsTimer() {
        let store = PersistenceStore(inMemory: true)
        let timerManager = TimerManager(store: store)
        let pomodoro = PomodoroManager(timerManager: timerManager)

        // Set fast 2-second work duration for test
        pomodoro.workDuration = 2
        pomodoro.shortBreakDuration = 1
        pomodoro.reset()

        pomodoro.start(description: "Deep Work Sprint")
        #expect(timerManager.isRunning == true)

        // Skip to trigger completion transition
        pomodoro.skip()

        // 1. Session count increments
        #expect(pomodoro.completedWorkSessions == 1)

        // 2. TimerManager stopped and saved entry
        #expect(timerManager.isRunning == false)
        #expect(store.timeEntries.count == 1)
        #expect(store.timeEntries.first?.entryDescription == "Deep Work Sprint")

        // 3. Transitions to short break
        #expect(pomodoro.sessionType == .shortBreak)
        #expect(pomodoro.remainingSeconds == 1)

        // 4. Break is NOT tracked as productive work
        #expect(timerManager.isRunning == false)
    }

    @Test func fourSessionCycleTransitionsToLongBreak() {
        let store = PersistenceStore(inMemory: true)
        let timerManager = TimerManager(store: store)
        let pomodoro = PomodoroManager(timerManager: timerManager)

        pomodoro.workDuration = 1
        pomodoro.shortBreakDuration = 1
        pomodoro.longBreakDuration = 5
        pomodoro.targetIntervalCount = 4
        pomodoro.resetCycle()

        // Session 1: Work -> Short Break
        pomodoro.start()
        pomodoro.skip()
        #expect(pomodoro.completedWorkSessions == 1)
        #expect(pomodoro.sessionType == .shortBreak)

        // Session 2: Break -> Work -> Short Break
        pomodoro.skip() // skip break to work
        pomodoro.start()
        pomodoro.skip() // complete work session 2
        #expect(pomodoro.completedWorkSessions == 2)
        #expect(pomodoro.sessionType == .shortBreak)

        // Session 3: Break -> Work -> Short Break
        pomodoro.skip()
        pomodoro.start()
        pomodoro.skip()
        #expect(pomodoro.completedWorkSessions == 3)
        #expect(pomodoro.sessionType == .shortBreak)

        // Session 4: Break -> Work -> LONG BREAK (4th interval!)
        pomodoro.skip()
        pomodoro.start()
        pomodoro.skip()
        #expect(pomodoro.completedWorkSessions == 4)
        #expect(pomodoro.sessionType == .longBreak)
        #expect(pomodoro.remainingSeconds == 5)
    }

    @Test func breakPeriodsAreNeverLoggedAsProductiveWork() {
        let store = PersistenceStore(inMemory: true)
        let timerManager = TimerManager(store: store)
        let pomodoro = PomodoroManager(timerManager: timerManager)

        // Complete work session to enter break
        pomodoro.workDuration = 1
        pomodoro.start(description: "Focus Task")
        pomodoro.skip() // work ended

        let initialEntryCount = store.timeEntries.count

        // Start break
        pomodoro.start()
        #expect(pomodoro.sessionType == .shortBreak)
        #expect(pomodoro.isRunning == true)

        // TimerManager MUST NOT be running during break!
        #expect(timerManager.isRunning == false)
        #expect(timerManager.activeEntry == nil)

        // When break finishes, no new time entry was created
        pomodoro.skip()
        #expect(store.timeEntries.count == initialEntryCount)
    }

    @Test func customDurationsConfiguration() {
        let store = PersistenceStore(inMemory: true)
        let timerManager = TimerManager(store: store)
        let pomodoro = PomodoroManager(timerManager: timerManager)

        pomodoro.workDuration = 50 * 60
        pomodoro.shortBreakDuration = 10 * 60
        pomodoro.longBreakDuration = 30 * 60
        pomodoro.targetIntervalCount = 6

        #expect(pomodoro.workDuration == 3000)
        #expect(pomodoro.shortBreakDuration == 600)
        #expect(pomodoro.longBreakDuration == 1800)
        #expect(pomodoro.targetIntervalCount == 6)
        #expect(pomodoro.formattedRemainingTime == "50:00")
    }

    @Test func notificationManagerSmokeTest() {
        let nm = NotificationManager.shared
        // Safe dispatch without crashing
        nm.sendNotification(
            title: "Test Alert",
            body: "Notification dispatch verification"
        )
        #expect(type(of: nm) == NotificationManager.self)
    }
}
