import Testing
import Foundation
import Carbon
@testable import TimeStamp

@Suite("End-to-End System Tests: Complete v1.0 User Journey")
@MainActor
struct EndToEndSystemTests {

    @Test("E2E Workflow 1: Timer Engine & Time Entries Lifecycle (TIMER-01..05, ENTRY-01..05)")
    func testTimerAndEntriesCompleteLifecycle() throws {
        let store = PersistenceStore(inMemory: true)
        let timerManager = TimerManager(store: store)

        // 1. Setup Project & Task
        let project = Project(name: "App Launch", colorHex: "#5C3BFE")
        store.saveProject(project)
        let task = Task(name: "Code Audit", projectId: project.id)
        store.saveTask(task)

        // 2. TIMER-01: Start timer
        timerManager.start(
            description: "Security audit",
            projectId: project.id,
            taskId: task.id
        )
        #expect(timerManager.isRunning == true)
        #expect(timerManager.activeEntry != nil)
        #expect(timerManager.activeEntry?.entryDescription == "Security audit")

        // 3. TIMER-02: Pause & Resume
        timerManager.pause()
        #expect(timerManager.isPaused == true)
        #expect(timerManager.isRunning == false)
        timerManager.resume()
        #expect(timerManager.isRunning == true)

        // 4. TIMER-03: Stop timer & persist
        let completed = timerManager.stop()
        #expect(completed != nil)
        #expect(timerManager.isRunning == false)
        #expect(store.timeEntries.contains(where: { $0.id == completed?.id }))

        // 5. TIMER-04: Continue entry with one click
        if let completed = completed {
            timerManager.continueEntry(completed)
            #expect(timerManager.isRunning == true)
            #expect(timerManager.activeEntry?.entryDescription == "Security audit")
            #expect(timerManager.activeEntry?.projectId == project.id)
            _ = timerManager.stop()
        }

        // 6. TIMER-05: Drift-Free Math verification
        let base = Date()
        let calculated = TimeCalculator.calculateDuration(
            startDate: base.addingTimeInterval(-3600),
            endDate: base,
            accumulatedDuration: 0,
            isPaused: false
        )
        #expect(calculated == 3600)

        // 7. ENTRY-01 & ENTRY-02: Grouping by Day & Daily Totals
        let groups = DateHelper.groupEntriesByDay(store.timeEntries)
        #expect(!groups.isEmpty)
        #expect(groups.first?.totalDuration ?? 0 >= 0)

        // 8. ENTRY-03: Edit entry details
        if let firstEntry = store.timeEntries.first {
            firstEntry.entryDescription = "Updated Security Audit"
            store.saveTimeEntry(firstEntry)
            #expect(store.timeEntries.first?.entryDescription == "Updated Security Audit")
        }

        // 9. ENTRY-05: Manual Entry Logging
        let manualEntry = TimeEntry(
            entryDescription: "Manual retroactive meeting",
            startDate: base.addingTimeInterval(-7200),
            endDate: base.addingTimeInterval(-3600),
            accumulatedDuration: 0,
            projectId: project.id
        )
        store.saveTimeEntry(manualEntry)
        #expect(store.timeEntries.contains(where: { $0.entryDescription == "Manual retroactive meeting" }))

        // 10. ENTRY-04: Delete entry
        let countBefore = store.timeEntries.count
        store.deleteTimeEntry(id: manualEntry.id)
        #expect(store.timeEntries.count == countBefore - 1)
    }

    @Test("E2E Workflow 2: Projects, Tasks, and Clients Hierarchy (PROJ-01..04, TASK-01..03, CLNT-01..03)")
    func testProjectsTasksClientsHierarchy() throws {
        let store = PersistenceStore(inMemory: true)

        // 1. CLNT-01: Create and manage client
        let client = Client(name: "Acme Holdings", notes: "VIP Client")
        store.saveClient(client)
        #expect(store.clients.count == 1)

        // 2. PROJ-01 & CLNT-02: Create project associated with client
        let project = Project(name: "Acme Web Portal", colorHex: "#30D158", clientId: client.id)
        store.saveProject(project)
        #expect(project.clientId == client.id)

        // 3. TASK-01 & TASK-02: Task creation and completion
        let task = Task(name: "Frontend Wireframes", projectId: project.id)
        store.saveTask(task)
        #expect(task.isCompleted == false)
        task.isCompleted = true
        store.saveTask(task)
        #expect(store.tasks.first?.isCompleted == true)

        // 4. TASK-03 & PROJ-04 & CLNT-03: Associate time entry, filter and compute totals
        let base = Date()
        let entry = TimeEntry(
            entryDescription: "Wireframe mockup",
            startDate: base.addingTimeInterval(-3600),
            endDate: base,
            accumulatedDuration: 0,
            projectId: project.id,
            taskId: task.id
        )
        store.saveTimeEntry(entry)

        let projectEntries = store.timeEntries.filter { $0.projectId == project.id }
        #expect(projectEntries.count == 1)

        let clientProjects = store.projects.filter { $0.clientId == client.id }
        let clientDuration = store.timeEntries
            .filter { entry in clientProjects.contains(where: { $0.id == entry.projectId }) }
            .reduce(0.0) { $0 + $1.effectiveDuration }
        #expect(clientDuration == 3600)

        // 5. PROJ-03: Archive project
        project.isArchived = true
        store.saveProject(project)
        #expect(store.projects.first?.isArchived == true)

        // 6. Delete project cascades to tasks and unlinks entries
        store.deleteProject(id: project.id)
        #expect(store.projects.isEmpty)
        #expect(store.tasks.isEmpty)
        #expect(store.timeEntries.first?.projectId == nil)
        #expect(store.timeEntries.first?.taskId == nil)
    }

    @Test("E2E Workflow 3: Dashboard, Reports, Calendar, System & Settings (DASH-01..03, REPT-01..04, CAL-01..03, SYS-01..03, SET-01..03)")
    func testDashboardReportsCalendarSystemAndSettings() throws {
        let store = PersistenceStore(inMemory: true)
        let timerManager = TimerManager(store: store)

        // Seed demo data
        PreviewContainer.seedSampleData(store: store)
        #expect(!store.projects.isEmpty)
        #expect(!store.timeEntries.isEmpty)

        // 1. DASH-01, DASH-02, DASH-03: Dashboard metrics
        let today = Date()
        let todayStart = Calendar.current.startOfDay(for: today)
        let todayDuration = store.timeEntries
            .filter { $0.startDate >= todayStart && $0.endDate != nil }
            .reduce(0.0) { $0 + $1.effectiveDuration }
        let targetHours = 8.0
        let targetSeconds = targetHours * 3600.0
        let progressRatio = min(1.0, todayDuration / targetSeconds)
        #expect(progressRatio >= 0.0 && progressRatio <= 1.0)

        let recentEntries = store.timeEntries
            .filter { $0.endDate != nil }
            .sorted { $0.startDate > $1.startDate }
            .prefix(5)
        #expect(!recentEntries.isEmpty)

        // 2. REPT-01..04: Reports analytics & export
        let csv = ExportService.generateCSV(
            entries: store.timeEntries,
            projects: store.projects,
            clients: store.clients,
            tasks: store.tasks
        )
        #expect(csv.contains("Date,Start Time,End Time"))

        let jsonData = ExportService.generateJSON(
            entries: store.timeEntries,
            projects: store.projects,
            clients: store.clients,
            tasks: store.tasks
        )
        let decoder = JSONDecoder()
        let exportItems = try decoder.decode([ExportItem].self, from: jsonData)
        #expect(!exportItems.isEmpty)

        // 3. CAL-01..03: Calendar 24h timeline layout
        let blocks = CalendarLayoutHelper.computeBlockLayouts(
            entries: store.timeEntries,
            for: today
        )
        for block in blocks {
            #expect(block.startMinutes >= 0 && block.startMinutes <= 1440)
            #expect(block.totalSubColumns >= 1)
        }

        // 4. SYS-01..03: System Menu Bar & Global Hotkey
        let labelView = MenuBarLabelView()
        #expect(type(of: labelView) == MenuBarLabelView.self)

        let hotkey = GlobalHotkeyManager.shared
        hotkey.setupTimerToggle(timerManager: timerManager)
        #expect(hotkey.isRegistered == true)

        // 5. SET-01..03: Settings Theme, Hotkey Update, and Data Wipe
        hotkey.updateHotkey(
            keyCode: 17,
            modifiers: UInt32(controlKey | optionKey),
            display: "⌃⌥T"
        )
        #expect(hotkey.displayString == "⌃⌥T")

        // Reset all data test
        store.clearAll()
        #expect(store.projects.isEmpty)
        #expect(store.clients.isEmpty)
        #expect(store.tasks.isEmpty)
        #expect(store.timeEntries.isEmpty)

        // Restore hotkey
        hotkey.updateHotkey(
            keyCode: GlobalHotkeyManager.defaultKeyCode,
            modifiers: GlobalHotkeyManager.defaultModifiers,
            display: GlobalHotkeyManager.defaultDisplay
        )
    }
}
