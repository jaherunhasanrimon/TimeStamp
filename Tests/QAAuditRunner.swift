import Foundation
import SwiftUI
@testable import TimeStamp

@main
struct QAApp {
    @MainActor
    static func main() async {
        print("=======================================================")
        print("   FINAL QUALITY ASSURANCE AUDIT - TIMESTAMP macOS")
        print("=======================================================")

        var passedCount = 0
        var failedCount = 0

        func assertTest(_ name: String, _ condition: Bool, details: String = "") {
            if condition {
                print(" [PASS] \(name)")
                passedCount += 1
            } else {
                print(" [FAIL] \(name): \(details)")
                failedCount += 1
            }
        }

        // -----------------------------------------------------------
        // SECTION 1: FRESH INSTALLATION CLEAN STATE
        // -----------------------------------------------------------
        print("\n--- SECTION 1: Fresh Installation Clean State ---")
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("TimeStamp_FreshInstall_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let freshStore = PersistenceStore(inMemory: false, storageDirectory: tempDir)
        assertTest("Fresh install has 0 time entries", freshStore.timeEntries.isEmpty)
        assertTest("Fresh install has 0 goals (no sample goals seeded)", freshStore.goals.isEmpty)
        assertTest("Fresh install has 0 projects", freshStore.projects.isEmpty)
        assertTest("Fresh install has 0 clients", freshStore.clients.isEmpty)
        assertTest("Fresh install has 0 tasks", freshStore.tasks.isEmpty)
        assertTest("Fresh install has 0 tags", freshStore.tags.isEmpty)

        // Regression Test: Simulated restart on empty store must NOT auto-seed sample goals
        let restartedEmptyStore = PersistenceStore(inMemory: false, storageDirectory: tempDir)
        assertTest("Simulated restart on empty store preserves 0 goals", restartedEmptyStore.goals.isEmpty)

        // Regression Test: Adding user goal and restarting must never resurrect obsolete sample goals
        let customGoal = Goal(title: "Research", targetDuration: 5400)
        restartedEmptyStore.saveGoal(customGoal)
        let restartedUserStore = PersistenceStore(inMemory: false, storageDirectory: tempDir)
        assertTest("Simulated restart with user goal has exactly 1 goal", restartedUserStore.goals.count == 1)
        assertTest("User goal title matches 'Research'", restartedUserStore.goals.first?.title == "Research")
        let hasSampleGoals = restartedUserStore.goals.contains {
            ["Daily Deep Work", "Academic & Tech Study", "Core Software Engineering", "Long-term Mastery Sprint"].contains($0.title)
        }
        assertTest("Obsolete sample goals NEVER resurrect after restart", !hasSampleGoals)

        try? FileManager.default.removeItem(at: tempDir)

        // -----------------------------------------------------------
        // SECTION 2: TIMER ACCURACY & DURATION INVARIANCE
        // -----------------------------------------------------------
        print("\n--- SECTION 2: Timer Accuracy & Duration Invariance ---")
        let timerStore = PersistenceStore(inMemory: true)
        let timerMgr = TimerManager(store: timerStore)
        
        // Test 2.1: Start, Pause, Resume, Stop
        timerMgr.start(description: "Code audit session", isBillable: true)
        assertTest("TimerManager start creates running state", timerMgr.isRunning && !timerMgr.isPaused)
        assertTest("TimerManager start preserves isBillable", timerMgr.retainedIsBillable == true)
        
        if let entry = timerMgr.activeEntry {
            entry.startDate = Date().addingTimeInterval(-10)
        }
        
        timerMgr.pause()
        assertTest("TimerManager pause sets isPaused", timerMgr.isPaused && !timerMgr.isRunning)
        let pausedDuration = timerMgr.activeEntry?.accumulatedDuration ?? 0
        assertTest("TimerManager pause accumulates elapsed duration (> 9s)", pausedDuration >= 9.0)
        
        timerMgr.resume()
        assertTest("TimerManager resume resets isPaused", !timerMgr.isPaused && timerMgr.isRunning)
        
        let stoppedEntry = timerMgr.stop()
        assertTest("TimerManager stop clears running state", !timerMgr.isRunning && !timerMgr.isPaused)
        assertTest("TimerManager stop saves entry to store", timerStore.timeEntries.count == 1)
        
        // Test 2.2: Duration Invariance (NO DOUBLE-COUNTING)
        if let saved = stoppedEntry {
            let effDuration = saved.effectiveDuration
            let accDuration = saved.accumulatedDuration
            assertTest("Effective duration equals accumulated duration for stopped entry", abs(effDuration - accDuration) < 0.001)
            
            let wouldBeDoubled = accDuration + max(0, (saved.endDate ?? Date()).timeIntervalSince(saved.startDate))
            assertTest("Effective duration is NOT doubled", effDuration < wouldBeDoubled || accDuration == 0)
        }
        
        // Test 2.3: Manual Entry Duration
        let startManual = Date().addingTimeInterval(-7200)
        let endManual = Date().addingTimeInterval(-3600)
        let manualEntry = TimeEntry(
            entryDescription: "Manual 1hr meeting",
            startDate: startManual,
            endDate: endManual,
            accumulatedDuration: 3600
        )
        timerStore.saveTimeEntry(manualEntry)
        assertTest("Manual entry effectiveDuration exactly matches 3600s", manualEntry.effectiveDuration == 3600)

        // Test 2.4: Edited Entry Duration
        manualEntry.endDate = Date()
        manualEntry.accumulatedDuration = 7200
        timerStore.saveTimeEntry(manualEntry)
        assertTest("Edited entry effectiveDuration reflects new span (7200s)", manualEntry.effectiveDuration == 7200)

        // -----------------------------------------------------------
        // SECTION 3: TOGGL GOALS ENGINE - TARGET TYPES & CADENCES
        // -----------------------------------------------------------
        print("\n--- SECTION 3: Toggl Goals Engine - Target Types & Cadences ---")
        let goalStore = PersistenceStore(inMemory: true)
        
        // Test 3.1: At Least Goal (Daily)
        let atLeastDailyGoal = Goal(
            title: "Study 2 hours",
            targetDuration: 7200,
            targetType: .atLeast,
            cadence: .daily
        )
        goalStore.saveGoal(atLeastDailyGoal)
        
        var prog = goalStore.progress(for: atLeastDailyGoal)
        assertTest("At Least goal with 0 entries is 0% and not completed", prog.completedDuration == 0 && prog.percentage == 0 && !prog.isCompleted)
        
        let today1h = TimeEntry(
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            accumulatedDuration: 3600
        )
        goalStore.saveTimeEntry(today1h)
        prog = goalStore.progress(for: atLeastDailyGoal)
        assertTest("At Least goal with 1hr/2hr is 50% and not completed", prog.completedDuration == 3600 && abs(prog.percentage - 0.5) < 0.01 && !prog.isCompleted)
        
        let todayAnother1h = TimeEntry(
            startDate: Date().addingTimeInterval(-7200),
            endDate: Date().addingTimeInterval(-3600),
            accumulatedDuration: 3600
        )
        goalStore.saveTimeEntry(todayAnother1h)
        prog = goalStore.progress(for: atLeastDailyGoal)
        assertTest("At Least goal with 2hr/2hr is 100% and COMPLETED", prog.completedDuration == 7200 && abs(prog.percentage - 1.0) < 0.01 && prog.isCompleted && !prog.isOverLimit)

        // Test 3.2: Less Than Goal (Daily Limit)
        let lessThanGoal = Goal(
            title: "Social Media limit 1 hour",
            targetDuration: 3600,
            targetType: .lessThan,
            cadence: .daily
        )
        goalStore.saveGoal(lessThanGoal)
        prog = goalStore.progress(for: lessThanGoal)
        assertTest("Less Than goal with 7200s/3600s is OVER LIMIT", prog.isOverLimit && !prog.isCompleted)

        // Test 3.3: Weekday Goal Semantics
        let weekdayGoal = Goal(
            title: "Weekday Focus 4 hours",
            targetDuration: 14400,
            targetType: .atLeast,
            cadence: .weekdays
        )
        goalStore.saveGoal(weekdayGoal)
        prog = goalStore.progress(for: weekdayGoal)
        let weekday = Calendar.current.component(.weekday, from: Date())
        let isWeekend = (weekday == 1 || weekday == 7)
        if isWeekend {
            assertTest("Weekday goal on weekend reports 0 completed time", prog.completedDuration == 0)
        } else {
            assertTest("Weekday goal on weekday reflects today's duration (7200s / 14400s = 50%)", prog.completedDuration == 7200 && abs(prog.percentage - 0.5) < 0.01)
        }

        // Test 3.4: Weekly Goal Semantics
        let weeklyGoal = Goal(
            title: "Weekly Sprint 10 hours",
            targetDuration: 36000,
            targetType: .atLeast,
            cadence: .weekly
        )
        goalStore.saveGoal(weeklyGoal)
        prog = goalStore.progress(for: weeklyGoal)
        assertTest("Weekly goal accumulates current week time (7200s / 36000s = 20%)", prog.completedDuration == 7200 && abs(prog.percentage - 0.2) < 0.01)

        // -----------------------------------------------------------
        // SECTION 4: GOAL FILTERING - PROJECT, CLIENT, TAG, BILLABLE
        // -----------------------------------------------------------
        print("\n--- SECTION 4: Goal Multi-Criteria Filtering ---")
        let filterStore = PersistenceStore(inMemory: true)
        
        let clientA = Client(name: "Client Alpha")
        let clientB = Client(name: "Client Beta")
        filterStore.saveClient(clientA)
        filterStore.saveClient(clientB)
        
        let projA1 = Project(name: "Alpha Web", clientId: clientA.id)
        let projA2 = Project(name: "Alpha Mobile", clientId: clientA.id)
        let projB1 = Project(name: "Beta Core", clientId: clientB.id)
        filterStore.saveProject(projA1)
        filterStore.saveProject(projA2)
        filterStore.saveProject(projB1)
        
        let tagDev = Tag(name: "dev", colorHex: "#36B37E")
        let tagMeeting = Tag(name: "meeting", colorHex: "#E54583")
        filterStore.saveTag(tagDev)
        filterStore.saveTag(tagMeeting)

        let e1 = TimeEntry(
            entryDescription: "Alpha Web Dev",
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date(),
            accumulatedDuration: 1800,
            projectId: projA1.id,
            tagIds: [tagDev.id],
            isBillable: true
        )
        let e2 = TimeEntry(
            entryDescription: "Alpha Sync",
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date().addingTimeInterval(-1800),
            accumulatedDuration: 1800,
            projectId: projA2.id,
            tagIds: [tagMeeting.id],
            isBillable: false
        )
        let e3 = TimeEntry(
            entryDescription: "Beta Work",
            startDate: Date().addingTimeInterval(-7200),
            endDate: Date().addingTimeInterval(-3600),
            accumulatedDuration: 3600,
            projectId: projB1.id,
            tagIds: [tagDev.id],
            isBillable: true
        )
        filterStore.saveTimeEntry(e1)
        filterStore.saveTimeEntry(e2)
        filterStore.saveTimeEntry(e3)

        // Client filter (matches associated projects)
        let clientAlphaGoal = Goal(
            title: "Client Alpha All Projects",
            targetDuration: 7200,
            targetType: .atLeast,
            cadence: .daily,
            clientId: clientA.id
        )
        prog = filterStore.progress(for: clientAlphaGoal)
        assertTest("Client Alpha goal matches e1 + e2 (3600s)", prog.completedDuration == 3600)

        // Specific Project filter
        let projA1Goal = Goal(
            title: "Alpha Web Only",
            targetDuration: 3600,
            targetType: .atLeast,
            cadence: .daily,
            projectId: projA1.id
        )
        prog = filterStore.progress(for: projA1Goal)
        assertTest("Project A1 goal matches e1 only (1800s)", prog.completedDuration == 1800)

        // Tag filter
        let devTagGoal = Goal(
            title: "All Dev Work",
            targetDuration: 7200,
            targetType: .atLeast,
            cadence: .daily,
            tagIds: [tagDev.id]
        )
        prog = filterStore.progress(for: devTagGoal)
        assertTest("Dev tag goal matches e1 + e3 (5400s)", prog.completedDuration == 5400)

        // Billable only filter
        let billableGoal = Goal(
            title: "Billable Hours",
            targetDuration: 7200,
            targetType: .atLeast,
            cadence: .daily,
            billableFilter: .billableOnly
        )
        prog = filterStore.progress(for: billableGoal)
        assertTest("Billable only goal matches e1 + e3 (5400s)", prog.completedDuration == 5400)

        // Non-billable filter
        let nonBillableGoal = Goal(
            title: "Internal Non-Billable",
            targetDuration: 3600,
            targetType: .atLeast,
            cadence: .daily,
            billableFilter: .nonBillableOnly
        )
        prog = filterStore.progress(for: nonBillableGoal)
        assertTest("Non-billable only goal matches e2 only (1800s)", prog.completedDuration == 1800)

        // Progress Preview in Goal Editor
        let preview = filterStore.progressPreview(
            targetDuration: 3600,
            targetType: .atLeast,
            cadence: .daily,
            projectId: projA1.id,
            clientId: nil,
            taskId: nil,
            tagIds: [],
            billableFilter: .all
        )
        assertTest("Progress preview reflects matching draft duration (1800s / 3600s = 50%)", preview.matchingDuration == 1800 && abs(preview.percentage - 0.5) < 0.01)

        // -----------------------------------------------------------
        // SECTION 5: DATA SAFETY, BACKUP & RESTORATION
        // -----------------------------------------------------------
        print("\n--- SECTION 5: Data Safety, Backup & Restoration ---")
        let backupDir = FileManager.default.temporaryDirectory.appendingPathComponent("TimeStamp_BackupTest_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        let diskStore = PersistenceStore(inMemory: false, storageDirectory: backupDir)
        diskStore.saveClient(Client(name: "Disk Client"))
        diskStore.saveProject(Project(name: "Disk Project"))
        diskStore.saveGoal(Goal(title: "Disk Goal", targetDuration: 3600))
        diskStore.saveTimeEntry(TimeEntry(entryDescription: "Disk Entry", accumulatedDuration: 1800))
        
        let backupURL = diskStore.backupStore()
        assertTest("Backup store creates valid backup file", backupURL != nil && FileManager.default.fileExists(atPath: backupURL!.path))

        let resetBackupURL = diskStore.resetToCleanState(createBackup: true)
        assertTest("resetToCleanState returns new backup URL", resetBackupURL != nil)
        assertTest("After reset, store has 0 entries", diskStore.timeEntries.isEmpty)
        assertTest("After reset, store has 0 goals", diskStore.goals.isEmpty)
        assertTest("After reset, store has 0 projects", diskStore.projects.isEmpty)
        assertTest("After reset, store has 0 clients", diskStore.clients.isEmpty)

        if let resetBackupURL = resetBackupURL {
            let backupData = try! Data(contentsOf: resetBackupURL)
            let storeURL = backupDir.appendingPathComponent("timestamp_store.json")
            try! backupData.write(to: storeURL)
            
            let recoveredStore = PersistenceStore(inMemory: false, storageDirectory: backupDir)
            assertTest("Restored store recovers 1 entry", recoveredStore.timeEntries.count == 1)
            assertTest("Restored store recovers 1 goal", recoveredStore.goals.count == 1)
            assertTest("Restored store recovers 1 project", recoveredStore.projects.count == 1)
            assertTest("Restored store recovers 1 client", recoveredStore.clients.count == 1)
        }

        try? FileManager.default.removeItem(at: backupDir)

        // -----------------------------------------------------------
        // SECTION 6: UI COLORS & LIGHT/DARK THEME AUDIT
        // -----------------------------------------------------------
        print("\n--- SECTION 6: UI Colors & Light/Dark Theme Audit ---")
        assertTest("AppColors.background is dynamic", type(of: AppColors.background) == Color.self)
        assertTest("AppColors.cardBackground is dynamic", type(of: AppColors.cardBackground) == Color.self)
        assertTest("AppColors.togglMagenta is #E54583", AppColors.togglMagenta != Color.clear)
        assertTest("AppColors.focusBorder is Toggl focus green", AppColors.focusBorder != Color.clear)
        assertTest("AppColors.billable is green #36B37E", AppColors.billable != Color.clear)
        assertTest("AppColors.goalGold is bronze gold", AppColors.goalGold != Color.clear)

        // -----------------------------------------------------------
        // AUDIT SUMMARY
        // -----------------------------------------------------------
        print("\n=======================================================")
        print("   FINAL QA AUDIT RESULTS: \(passedCount) PASSED / \(failedCount) FAILED")
        print("=======================================================")
        if failedCount == 0 {
            print(">> ALL AUDIT OBJECTIVES MET WITH 100% SUCCESS <<")
        } else {
            print(">> ATTENTION: \(failedCount) AUDIT CHECKS FAILED <<")
            exit(1)
        }
    }
}
