import Testing
import Foundation
@testable import TimeStamp

@Suite("Reports Analytics & Data Export Tests")
@MainActor
struct ReportsAndExportTests {

    @Test("Date range filtering isolates entries within boundaries")
    func testDateRangeFiltering() throws {
        let store = PersistenceStore(inMemory: true)
        let calendar = Calendar.current
        let baseDate = Date()
        let start = calendar.startOfDay(for: baseDate)
        let end = calendar.date(byAdding: .day, value: 3, to: start)!

        // Entry 1: Within range (day 1)
        let entryInside = TimeEntry(
            entryDescription: "Inside range",
            startDate: calendar.date(byAdding: .day, value: 1, to: start)!,
            endDate: calendar.date(byAdding: .day, value: 1, to: start)!.addingTimeInterval(3600),
            accumulatedDuration: 0
        )
        store.saveTimeEntry(entryInside)

        // Entry 2: Outside range (day 5)
        let entryOutside = TimeEntry(
            entryDescription: "Outside range",
            startDate: calendar.date(byAdding: .day, value: 5, to: start)!,
            endDate: calendar.date(byAdding: .day, value: 5, to: start)!.addingTimeInterval(3600),
            accumulatedDuration: 0
        )
        store.saveTimeEntry(entryOutside)

        let filtered = store.timeEntries.filter {
            $0.startDate >= start && $0.startDate < end && $0.endDate != nil
        }

        #expect(filtered.count == 1)
        #expect(filtered.first?.entryDescription == "Inside range")
    }

    @Test("Project distribution calculates correct durations and percentages")
    func testProjectDistributionAggregation() throws {
        let store = PersistenceStore(inMemory: true)

        let projA = Project(name: "Client Alpha", colorHex: "#5C3BFE")
        let projB = Project(name: "Internal Tooling", colorHex: "#30D158")
        store.saveProject(projA)
        store.saveProject(projB)

        let entryA = TimeEntry(
            entryDescription: "Alpha feature",
            startDate: Date().addingTimeInterval(-7200),
            endDate: Date().addingTimeInterval(-3600), // 3600s = 1h
            accumulatedDuration: 0,
            projectId: projA.id
        )
        let entryB = TimeEntry(
            entryDescription: "Internal refactor",
            startDate: Date().addingTimeInterval(-10800),
            endDate: Date(), // 10800s = 3h
            accumulatedDuration: 0,
            projectId: projB.id
        )
        store.saveTimeEntry(entryA)
        store.saveTimeEntry(entryB)

        let entries = store.timeEntries.filter { $0.endDate != nil }
        let totalDuration = entries.reduce(0.0) { $0 + $1.effectiveDuration }
        #expect(totalDuration == 14400) // 4 hours

        let grouped = Dictionary(grouping: entries) { $0.projectId }
        let items: [BreakdownItem] = grouped.map { projId, list in
            let duration = list.reduce(0.0) { $0 + $1.effectiveDuration }
            let percent = (duration / totalDuration) * 100.0
            let project = projId.flatMap { store.project(for: $0) }
            return BreakdownItem(
                id: projId ?? UUID(),
                name: project?.name ?? "No Project",
                colorHex: project?.colorHex ?? "#8E8E93",
                duration: duration,
                percentage: percent
            )
        }.sorted { $0.duration > $1.duration }

        #expect(items.count == 2)
        #expect(items[0].name == "Internal Tooling")
        #expect(items[0].duration == 10800)
        #expect(items[0].percentage == 75.0)

        #expect(items[1].name == "Client Alpha")
        #expect(items[1].duration == 3600)
        #expect(items[1].percentage == 25.0)
    }

    @Test("Client distribution aggregates multiple projects under parent client")
    func testClientDistributionAggregation() throws {
        let store = PersistenceStore(inMemory: true)

        let client = Client(name: "Acme Corp")
        store.saveClient(client)

        let proj1 = Project(name: "Acme Web", colorHex: "#5C3BFE", clientId: client.id)
        let proj2 = Project(name: "Acme Mobile", colorHex: "#0A84FF", clientId: client.id)
        store.saveProject(proj1)
        store.saveProject(proj2)

        let entry1 = TimeEntry(
            entryDescription: "Web design",
            startDate: Date().addingTimeInterval(-7200),
            endDate: Date().addingTimeInterval(-3600), // 1h
            accumulatedDuration: 0,
            projectId: proj1.id
        )
        let entry2 = TimeEntry(
            entryDescription: "iOS build",
            startDate: Date().addingTimeInterval(-10800),
            endDate: Date().addingTimeInterval(-3600), // 2h
            accumulatedDuration: 0,
            projectId: proj2.id
        )
        store.saveTimeEntry(entry1)
        store.saveTimeEntry(entry2)

        var clientDurations: [UUID?: TimeInterval] = [:]
        for entry in store.timeEntries where entry.endDate != nil {
            let project = entry.projectId.flatMap { store.project(for: $0) }
            let cId = project?.clientId
            clientDurations[cId, default: 0] += entry.effectiveDuration
        }

        #expect(clientDurations[client.id] == 10800) // 3h total for Acme Corp
    }

    @Test("CSV export produces RFC 4180 escaped text with proper headers")
    func testCSVExportFormatting() throws {
        let store = PersistenceStore(inMemory: true)
        let project = Project(name: "Secret, \"Agent\" Project", colorHex: "#5C3BFE")
        store.saveProject(project)

        let task = Task(name: "Deploy \"Production\"", projectId: project.id)
        store.saveTask(task)

        let entry = TimeEntry(
            entryDescription: "Fix issue #42, \"urgent\" fix",
            startDate: Date(timeIntervalSince1970: 1700000000),
            endDate: Date(timeIntervalSince1970: 1700003600),
            accumulatedDuration: 0,
            projectId: project.id,
            taskId: task.id
        )
        store.saveTimeEntry(entry)

        let csv = ExportService.generateCSV(
            entries: store.timeEntries,
            projects: store.projects,
            clients: store.clients,
            tasks: store.tasks
        )

        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count >= 2)
        #expect(lines[0] == "Date,Start Time,End Time,Duration (Seconds),Duration (Formatted),Description,Project,Client,Task")

        let dataRow = lines[1]
        // Check RFC 4180 escaping for quotes
        #expect(dataRow.contains("\"Fix issue #42, \"\"urgent\"\" fix\""))
        #expect(dataRow.contains("\"Secret, \"\"Agent\"\" Project\""))
        #expect(dataRow.contains("\"Deploy \"\"Production\"\"\""))
    }

    @Test("JSON export produces valid deserializable JSON data")
    func testJSONExportFormatting() throws {
        let store = PersistenceStore(inMemory: true)
        let project = Project(name: "Backend API", colorHex: "#5C3BFE")
        store.saveProject(project)

        let entry = TimeEntry(
            entryDescription: "API endpoints",
            startDate: Date(timeIntervalSince1970: 1700000000),
            endDate: Date(timeIntervalSince1970: 1700003600),
            accumulatedDuration: 0,
            projectId: project.id
        )
        store.saveTimeEntry(entry)

        let jsonData = ExportService.generateJSON(
            entries: store.timeEntries,
            projects: store.projects,
            clients: store.clients,
            tasks: store.tasks
        )

        let decoder = JSONDecoder()
        let items = try decoder.decode([ExportItem].self, from: jsonData)

        #expect(items.count == 1)
        #expect(items[0].description == "API endpoints")
        #expect(items[0].project == "Backend API")
        #expect(items[0].durationSeconds == 3600)
    }
}
