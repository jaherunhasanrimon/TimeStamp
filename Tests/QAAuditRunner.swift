import Foundation
import SwiftUI
import Testing
@testable import TimeStamp

@Suite("QA Audit Integration Tests")
@MainActor
struct QAAuditIntegrationTests {

    @Test("Fresh installation clean state and restart resistance")
    func testFreshInstallAndRestartIntegrity() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("TimeStamp_FreshInstall_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let freshStore = PersistenceStore(inMemory: false, storageDirectory: tempDir)
        #expect(freshStore.timeEntries.isEmpty)
        #expect(freshStore.goals.isEmpty)
        #expect(freshStore.projects.isEmpty)
        #expect(freshStore.clients.isEmpty)
        #expect(freshStore.tasks.isEmpty)
        #expect(freshStore.tags.isEmpty)

        // Simulated restart on empty store must NOT auto-seed sample goals
        let restartedEmptyStore = PersistenceStore(inMemory: false, storageDirectory: tempDir)
        #expect(restartedEmptyStore.goals.isEmpty)

        // Adding user goal and restarting must never resurrect obsolete sample goals
        let customGoal = Goal(title: "Research", targetDuration: 5400)
        restartedEmptyStore.saveGoal(customGoal)
        let restartedUserStore = PersistenceStore(inMemory: false, storageDirectory: tempDir)
        #expect(restartedUserStore.goals.count == 1)
        #expect(restartedUserStore.goals.first?.title == "Research")
        let sampleTitles = ["Daily Deep Work", "Academic & Tech Study", "Core Software Engineering", "Long-term Mastery Sprint"]
        #expect(!restartedUserStore.goals.contains { sampleTitles.contains($0.title) })
    }

    @Test("Live active timer does NOT double-count goal progress when elapsed > 0")
    func testLiveTimerGoalProgressNoDoubleCounting() {
        let store = PersistenceStore(inMemory: true)
        let timerMgr = TimerManager(store: store)
        let goal = Goal(title: "Focus Goal", targetDuration: 3600)
        store.saveGoal(goal)

        timerMgr.start(description: "Deep Work")
        if let active = timerMgr.activeEntry {
            active.startDate = Date().addingTimeInterval(-600)
        }
        timerMgr.updateTick()

        // Must be ~600s, NOT ~1200s!
        let prog = store.progress(
            for: goal,
            activeEntry: timerMgr.activeEntry,
            activeDuration: timerMgr.currentDuration
        )
        #expect(abs(prog.completedDuration - 600.0) < 2.0)

        // Stopping must preserve single ~600s total
        _ = timerMgr.stop()
        let postStopProg = store.progress(for: goal)
        #expect(abs(postStopProg.completedDuration - 600.0) < 2.0)
    }

    @Test("Disk backup creation, safe reset, and full backup restoration")
    func testDiskBackupAndRestore() throws {
        let backupDir = FileManager.default.temporaryDirectory.appendingPathComponent("TimeStamp_BackupTest_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: backupDir) }

        let diskStore = PersistenceStore(inMemory: false, storageDirectory: backupDir)
        diskStore.saveClient(Client(name: "Disk Client"))
        diskStore.saveProject(Project(name: "Disk Project"))
        diskStore.saveGoal(Goal(title: "Disk Goal", targetDuration: 3600))
        diskStore.saveTimeEntry(TimeEntry(entryDescription: "Disk Entry", accumulatedDuration: 1800))

        let backupURL = diskStore.backupStore()
        #expect(backupURL != nil)
        #expect(FileManager.default.fileExists(atPath: backupURL!.path))

        let resetBackupURL = diskStore.resetToCleanState(createBackup: true)
        #expect(resetBackupURL != nil)
        #expect(diskStore.timeEntries.isEmpty)
        #expect(diskStore.goals.isEmpty)
        #expect(diskStore.projects.isEmpty)
        #expect(diskStore.clients.isEmpty)

        if let resetBackupURL = resetBackupURL {
            let backupData = try Data(contentsOf: resetBackupURL)
            let storeURL = backupDir.appendingPathComponent("timestamp_store.json")
            try backupData.write(to: storeURL)

            let recoveredStore = PersistenceStore(inMemory: false, storageDirectory: backupDir)
            #expect(recoveredStore.timeEntries.count == 1)
            #expect(recoveredStore.goals.count == 1)
            #expect(recoveredStore.projects.count == 1)
            #expect(recoveredStore.clients.count == 1)
        }
    }
}
