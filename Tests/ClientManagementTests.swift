import Foundation
import Testing
@testable import TimeStamp

@Suite("Client Management and Entry Filtering Tests")
@MainActor
struct ClientManagementTests {

    @Test("Verify client creation, editing, and note persistence")
    func testClientCRUD() {
        let store = PersistenceStore(inMemory: true)
        let client = Client(name: "Acme Corporation", notes: "Primary enterprise client")
        store.saveClient(client)

        #expect(store.clients.count == 1)
        #expect(store.clients.first?.name == "Acme Corporation")
        #expect(store.clients.first?.notes == "Primary enterprise client")

        // Edit client
        client.name = "Acme Global Corp"
        client.notes = "Updated contact details"
        store.saveClient(client)

        #expect(store.clients.count == 1)
        #expect(store.clients.first?.name == "Acme Global Corp")
        #expect(store.clients.first?.notes == "Updated contact details")
    }

    @Test("Verify project association with client and unlinking upon client deletion")
    func testClientProjectLinkingAndSafeDeletion() {
        let store = PersistenceStore(inMemory: true)
        let client = Client(name: "Globex Inc")
        store.saveClient(client)

        let project1 = Project(name: "Globex ERP", clientId: client.id)
        let project2 = Project(name: "Globex Mobile", clientId: client.id)
        let unrelatedProject = Project(name: "Internal R&D", clientId: nil)
        store.saveProject(project1)
        store.saveProject(project2)
        store.saveProject(unrelatedProject)

        #expect(store.projects.filter { $0.clientId == client.id }.count == 2)

        let entry = TimeEntry(
            entryDescription: "ERP development",
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            projectId: project1.id
        )
        store.saveTimeEntry(entry)

        // Delete client
        store.deleteClient(id: client.id)

        #expect(store.clients.isEmpty)
        // Projects remain intact but clientId is reset to nil
        #expect(store.projects.count == 3)
        #expect(store.projects.first(where: { $0.name == "Globex ERP" })?.clientId == nil)
        #expect(store.projects.first(where: { $0.name == "Globex Mobile" })?.clientId == nil)
        // Time entry remains preserved with project intact
        #expect(store.timeEntries.count == 1)
        #expect(store.timeEntries.first?.projectId == project1.id)
    }

    @Test("Verify total tracked time computation for a client across all assigned projects")
    func testClientTotalTrackedTime() {
        let store = PersistenceStore(inMemory: true)
        let client = Client(name: "Initech")
        store.saveClient(client)

        let project1 = Project(name: "Project A", clientId: client.id)
        let project2 = Project(name: "Project B", clientId: client.id)
        let unrelatedProject = Project(name: "Unrelated", clientId: nil)
        store.saveProject(project1)
        store.saveProject(project2)
        store.saveProject(unrelatedProject)

        let now = Date()
        let entry1 = TimeEntry(
            entryDescription: "Work on A",
            startDate: now.addingTimeInterval(-7200), // 2h
            endDate: now,
            projectId: project1.id
        )
        let entry2 = TimeEntry(
            entryDescription: "Work on B",
            startDate: now.addingTimeInterval(-3600), // 1h
            endDate: now,
            projectId: project2.id
        )
        let entry3 = TimeEntry(
            entryDescription: "Work on Unrelated",
            startDate: now.addingTimeInterval(-5400), // 1.5h
            endDate: now,
            projectId: unrelatedProject.id
        )
        store.saveTimeEntry(entry1)
        store.saveTimeEntry(entry2)
        store.saveTimeEntry(entry3)

        let clientProjectIds = Set(store.projects.filter { $0.clientId == client.id }.map { $0.id })
        let totalClientDuration = store.timeEntries
            .filter { entry in
                guard let pId = entry.projectId else { return false }
                return clientProjectIds.contains(pId)
            }
            .reduce(0) { $0 + $1.effectiveDuration }

        #expect(totalClientDuration >= 10800) // 2h + 1h = 3h = 10800s
        let formatted = DateHelper.formatHumanDuration(totalClientDuration)
        #expect(formatted == "3h")
    }

    @Test("Verify time entries filtering by project and by client")
    func testEntryFiltering() {
        let store = PersistenceStore(inMemory: true)
        let client1 = Client(name: "Client 1")
        let client2 = Client(name: "Client 2")
        store.saveClient(client1)
        store.saveClient(client2)

        let proj1 = Project(name: "P1", clientId: client1.id)
        let proj2 = Project(name: "P2", clientId: client1.id)
        let proj3 = Project(name: "P3", clientId: client2.id)
        store.saveProject(proj1)
        store.saveProject(proj2)
        store.saveProject(proj3)

        let now = Date()
        store.saveTimeEntry(TimeEntry(entryDescription: "E1", startDate: now, endDate: now.addingTimeInterval(100), projectId: proj1.id))
        store.saveTimeEntry(TimeEntry(entryDescription: "E2", startDate: now, endDate: now.addingTimeInterval(200), projectId: proj2.id))
        store.saveTimeEntry(TimeEntry(entryDescription: "E3", startDate: now, endDate: now.addingTimeInterval(300), projectId: proj3.id))

        // 1. None filter: all entries
        let filterNone = EntryFilter.none
        #expect(filterEntries(store: store, filter: filterNone).count == 3)

        // 2. Project filter: only proj1
        let filterProj1 = EntryFilter.project(proj1.id)
        let p1Entries = filterEntries(store: store, filter: filterProj1)
        #expect(p1Entries.count == 1)
        #expect(p1Entries.first?.projectId == proj1.id)

        // 3. Client filter: proj1 + proj2 (both under client1)
        let filterClient1 = EntryFilter.client(client1.id)
        let c1Entries = filterEntries(store: store, filter: filterClient1)
        #expect(c1Entries.count == 2)
        #expect(Set(c1Entries.compactMap { $0.projectId }) == Set([proj1.id, proj2.id]))

        // 4. Client filter: client2
        let filterClient2 = EntryFilter.client(client2.id)
        let c2Entries = filterEntries(store: store, filter: filterClient2)
        #expect(c2Entries.count == 1)
        #expect(c2Entries.first?.projectId == proj3.id)
    }

    private func filterEntries(store: PersistenceStore, filter: EntryFilter) -> [TimeEntry] {
        switch filter {
        case .none:
            return store.timeEntries
        case .project(let pId):
            return store.timeEntries.filter { $0.projectId == pId }
        case .client(let cId):
            let clientProjectIds = Set(store.projects.filter { $0.clientId == cId }.map { $0.id })
            return store.timeEntries.filter { entry in
                guard let pId = entry.projectId else { return false }
                return clientProjectIds.contains(pId)
            }
        case .tag(let tId):
            return store.timeEntries.filter { $0.tagIds.contains(tId) }
        case .billableOnly:
            return store.timeEntries.filter { $0.isBillable }
        case .nonBillableOnly:
            return store.timeEntries.filter { !$0.isBillable }
        }
    }
}
