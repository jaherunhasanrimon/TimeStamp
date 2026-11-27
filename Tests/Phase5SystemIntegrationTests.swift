import Testing
@testable import TimeStamp
import Foundation

@Suite("Phase 5: Idle Detection, Workday Reminders & Activity Recorder Tests")
@MainActor
struct Phase5SystemIntegrationTests {

    @Test("IdleDetectionManager accurately evaluates HID idle threshold and handles all 4 resolution paths")
    func idleDetectionResolutions() {
        let cal = Calendar.current
        let baseNow = cal.startOfDay(for: Date()).addingTimeInterval(10 * 3600) // 10:00 AM
        var fakeIdleSeconds: TimeInterval = 0

        let proj = Project(name: "Client Work", colorHex: "#36B37E")

        // Path A: below threshold does not trigger
        do {
            let store = PersistenceStore(inMemory: true)
            store.saveProject(proj)
            let timer = TimerManager(store: store)
            let idle = IdleDetectionManager(store: store, timerManager: timer, isInMemory: true) {
                fakeIdleSeconds
            }
            idle.idleThresholdMinutes = 10
            timer.start(description: "Coding", projectId: proj.id, isBillable: true)
            // Backdate: session started 1 hour before baseNow so the capping window is 1h ≫ any idle duration used below
            let sessionStart = baseNow.addingTimeInterval(-3600)
            timer.activeEntry?.startDate = sessionStart
            idle.notifyTimerStarted(at: sessionStart)

            fakeIdleSeconds = 300 // 5m < 10m
            idle.evaluateIdleState(now: baseNow)
            #expect(idle.isPromptPresented == false)

            // Above threshold triggers prompt
            fakeIdleSeconds = 900 // 15m >= 10m
            idle.evaluateIdleState(now: baseNow)
            #expect(idle.isPromptPresented == true)
            #expect(idle.affectedEntryDescription == "Coding")

            // Keep idle time preserves active timer
            idle.keepIdleTime()
            #expect(idle.isPromptPresented == false)
            #expect(timer.isRunning == true)
        }

        // Path B: discard idle time saves pre-idle work and stops timer
        do {
            let store = PersistenceStore(inMemory: true)
            let timer = TimerManager(store: store)
            let idle = IdleDetectionManager(store: store, timerManager: timer, isInMemory: true) { 600 }
            timer.start(description: "Design", projectId: proj.id, isBillable: true)
            if let active = timer.activeEntry {
                active.startDate = Date().addingTimeInterval(-1800) // 30m ago
            }
            idle.evaluateIdleState(now: Date())
            #expect(idle.isPromptPresented == true)
            idle.discardIdleTime(now: Date())
            #expect(idle.isPromptPresented == false)
            #expect(timer.isRunning == false)
            #expect(store.timeEntries.count == 1)
            let saved = store.timeEntries[0]
            #expect(saved.effectiveDuration >= 1190 && saved.effectiveDuration <= 1210)
        }

        // Path C: discard idle time and continue starts fresh matching timer
        do {
            let store = PersistenceStore(inMemory: true)
            let timer = TimerManager(store: store)
            let idle = IdleDetectionManager(store: store, timerManager: timer, isInMemory: true) { 600 }
            timer.start(description: "Refactor", projectId: proj.id, isBillable: true)
            timer.activeEntry?.startDate = Date().addingTimeInterval(-1200)
            idle.evaluateIdleState(now: Date())
            idle.discardIdleTimeAndContinue(now: Date())
            #expect(timer.isRunning == true)
            #expect(timer.activeEntry?.entryDescription == "Refactor")
            #expect(timer.activeEntry?.projectId == proj.id)
            #expect(timer.activeEntry?.isBillable == true)
            #expect(store.timeEntries.count == 2)
        }

        // Path D: add idle time as new separate non-billable entry and continue
        do {
            let store = PersistenceStore(inMemory: true)
            let timer = TimerManager(store: store)
            let idle = IdleDetectionManager(store: store, timerManager: timer, isInMemory: true) { 600 }
            timer.start(description: "API Build", projectId: proj.id, isBillable: true)
            timer.activeEntry?.startDate = Date().addingTimeInterval(-1200)
            idle.evaluateIdleState(now: Date())
            idle.addIdleTimeAsNewEntry(idleDescription: "Coffee Chat", now: Date())
            #expect(timer.isRunning == true)
            #expect(store.timeEntries.count == 3)
            let awayEntry = store.timeEntries.first { $0.entryDescription == "Coffee Chat" }
            #expect(awayEntry != nil)
            #expect(awayEntry?.isBillable == false)
        }
    }

    @Test("ReminderManager honors weekday schedule, idle-only guard, and single-trigger-per-day lock")
    func reminderScheduleAndGuards() {
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)
        let reminder = ReminderManager(timerManager: timer, isInMemory: true)
        reminder.isEnabled = true
        reminder.reminderHour = 9
        reminder.reminderMinute = 30
        reminder.enabledWeekdays = [2, 3, 4, 5, 6] // Mon..Fri
        reminder.onlyWhenTimerIdle = true

        let cal = DateHelper.isoCalendar
        // Wednesday 2026-11-25 09:30 -> should trigger when idle
        let wedMorning = cal.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: 9, minute: 30))!
        #expect(reminder.shouldTriggerReminder(at: wedMorning, isTimerRunning: false, calendar: cal) == true)
        // Does NOT trigger while timer is already running
        #expect(reminder.shouldTriggerReminder(at: wedMorning, isTimerRunning: true, calendar: cal) == false)

        // Fires once per day
        #expect(reminder.evaluateAndNotifyIfNeeded(at: wedMorning, calendar: cal) == true)
        #expect(reminder.shouldTriggerReminder(at: wedMorning, isTimerRunning: false, calendar: cal) == false)

        // Saturday 2026-11-28 09:30 -> weekend excluded
        let satMorning = cal.date(from: DateComponents(year: 2026, month: 11, day: 28, hour: 9, minute: 30))!
        #expect(reminder.shouldTriggerReminder(at: satMorning, isTimerRunning: false, calendar: cal) == false)
    }

    // MARK: - D-IDLE-01 Regression: stale HID readings must never trigger immediately on timer start

    @Test("D-IDLE-01: stale pre-timer HID idle reading is capped by session start, so no immediate idle sheet")
    func idleDetectionStaleHIDReadingOnTimerStart() {
        // Simulate a Mac that has been idle for 20 minutes system-wide before the user
        // launches the app and starts a timer. The HID provider returns 1200s (20m),
        // but the timer was only started 5 seconds ago — effectiveIdleSeconds must be
        // ≤ 5, which is below any sane threshold, so no prompt should appear.
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)

        let timerStartedAt = Date()
        // Mock: system says Mac was idle 20 minutes (1200s) before timer started
        let idle = IdleDetectionManager(store: store, timerManager: timer, isInMemory: true) { 1200 }
        idle.idleThresholdMinutes = 5

        // Notify that the session started now
        idle.notifyTimerStarted(at: timerStartedAt)
        timer.start(description: "Fresh work")

        // Evaluate 5 seconds after session start: effective idle must be ≤ 5s, way below 5m threshold
        let evalNow = timerStartedAt.addingTimeInterval(5)
        idle.evaluateIdleState(now: evalNow)
        #expect(idle.isPromptPresented == false,
                "A stale 20-minute system idle must not trigger an idle sheet 5 seconds after timer start")
    }

    @Test("D-IDLE-01: idle detection fires correctly after genuine inactivity post-timer-start")
    func idleDetectionFiresAfterRealIdlePostTimerStart() {
        // The timer started 20 minutes ago. The user has been idle for 10 minutes.
        // effectiveIdleSeconds = min(600, 1200) = 600 ≥ 300 (5m threshold) → prompt shown.
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)

        let timerStartedAt = Date().addingTimeInterval(-1200) // 20 minutes ago
        let idle = IdleDetectionManager(store: store, timerManager: timer, isInMemory: true) { 600 } // 10m idle
        idle.idleThresholdMinutes = 5

        idle.notifyTimerStarted(at: timerStartedAt)
        timer.start(description: "Long session")
        // Backdate the active entry so the session appears to have started 20 min ago
        timer.activeEntry?.startDate = timerStartedAt

        let evalNow = Date() // "now" is 20m after session start
        idle.evaluateIdleState(now: evalNow)
        #expect(idle.isPromptPresented == true,
                "10 minutes of genuine idle after a 20-minute session should trigger the idle sheet")
        #expect(idle.detectedIdleSeconds >= 290 && idle.detectedIdleSeconds <= 610,
                "Detected idle duration should be approximately 10 minutes")
    }

    @Test("D-IDLE-01: notifyTimerStarted dismisses any lingering stale prompt")
    func idleDetectionNotifyTimerStartedDismissesStalePrompt() {
        let store = PersistenceStore(inMemory: true)
        let timer = TimerManager(store: store)
        // 20-minute idle reading
        let idle = IdleDetectionManager(store: store, timerManager: timer, isInMemory: true) { 1200 }
        idle.idleThresholdMinutes = 5

        // Start a session that is old enough for the idle to exceed threshold
        let pastStart = Date().addingTimeInterval(-1800)
        idle.notifyTimerStarted(at: pastStart)
        timer.start(description: "Old session")
        timer.activeEntry?.startDate = pastStart

        idle.evaluateIdleState(now: Date())
        #expect(idle.isPromptPresented == true, "Precondition: prompt should be showing")

        // Now user starts a brand-new session → prompt must be dismissed automatically
        idle.notifyTimerStarted(at: Date())
        #expect(idle.isPromptPresented == false,
                "notifyTimerStarted must automatically dismiss any lingering idle prompt")
    }

    @Test("ActivityTrackerManager is opt-in, filters <10s & exclusions, matches rules, and purges cleanly")
    func activityRecorderPrivacyAndAutotracker() {
        let store = PersistenceStore(inMemory: true)
        let proj = Project(name: "iOS & macOS Dev", colorHex: "#0A84FF")
        store.saveProject(proj)
        let timer = TimerManager(store: store)
        let activity = ActivityTrackerManager(timerManager: timer, isInMemory: true)

        // Privacy default: off by default
        #expect(activity.isEnabled == false)

        activity.isEnabled = true
        let rule = AutotrackerRule(keyword: "xcode", projectId: proj.id, isBillable: true)
        activity.addRule(rule)
        #expect(activity.matchingRule(appName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode")?.id == rule.id)

        let t0 = Date(timeIntervalSince1970: 1700000000)
        // 5-second glance in Safari (< 10s threshold) -> NOT recorded when switching
        activity.recordFocusSample(appName: "Safari", bundleIdentifier: "com.apple.Safari", at: t0)
        activity.recordFocusSample(appName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", at: t0.addingTimeInterval(5))
        #expect(activity.spans.isEmpty)

        // Excluded app (1Password) -> NOT recorded even after 60s
        activity.recordFocusSample(appName: "1Password", bundleIdentifier: "com.1password.1password", at: t0.addingTimeInterval(45))
        // Xcode span was 40s -> recorded!
        #expect(activity.spans.count == 1)
        #expect(activity.spans[0].appName == "Xcode")
        #expect(activity.spans[0].duration == 40)

        activity.recordFocusSample(appName: "Terminal", bundleIdentifier: "com.apple.Terminal", at: t0.addingTimeInterval(120))
        // Excluded 1Password never created a span
        #expect(activity.spans.count == 1)

        // 1-click purge
        activity.deleteAllActivityData()
        #expect(activity.spans.isEmpty)
    }
}
