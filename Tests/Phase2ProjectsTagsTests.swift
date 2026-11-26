import Testing
@testable import TimeStamp
import Foundation

@Suite("Phase 2: Projects, Clients, Tasks & Tags Parity Tests")
@MainActor
struct Phase2ProjectsTagsTests {

    @Test("Project estimatedHours encodes/decodes cleanly and supports legacy JSON without estimatedHours")
    func projectEstimatedHoursAndLegacyDecode() throws {
        let proj = Project(
            name: "Website Redesign",
            colorHex: "#E54583",
            hourlyRate: 95.0,
            isBillableDefault: true,
            estimatedHours: 40.0
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(proj)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let roundtrip = try decoder.decode(Project.self, from: data)
        #expect(roundtrip.estimatedHours == 40.0)
        #expect(roundtrip.hourlyRate == 95.0)
        #expect(roundtrip.isBillableDefault == true)

        let legacyJSON = """
        {
            "id": "\(UUID().uuidString)",
            "name": "Legacy Project",
            "colorHex": "#5C3BFE",
            "isArchived": false,
            "isBillableDefault": false,
            "createdAt": "2026-10-01T10:00:00Z"
        }
        """.data(using: .utf8)!
        let decodedLegacy = try decoder.decode(Project.self, from: legacyJSON)
        #expect(decodedLegacy.estimatedHours == nil)
        #expect(decodedLegacy.hourlyRate == nil)
    }

    @Test("Client currency & rate persist cleanly and inherit into unassigned-rate projects")
    func clientRateCurrencyAndInheritance() {
        let store = PersistenceStore(inMemory: true)
        let client = Client(name: "Euro Studio", notes: "EU contract", hourlyRate: 110.0, currency: "€")
        store.saveClient(client)

        let inheritedProject = Project(name: "Branding", clientId: client.id)
        let overrideProject = Project(name: "Consulting", hourlyRate: 150.0, clientId: client.id)
        store.saveProject(inheritedProject)
        store.saveProject(overrideProject)

        #expect(store.client(for: client.id)?.currency == "€")
        #expect(store.client(for: client.id)?.hourlyRate == 110.0)

        let inheritedRate = inheritedProject.hourlyRate ?? store.client(for: inheritedProject.clientId!)?.hourlyRate
        let overrideRate = overrideProject.hourlyRate ?? store.client(for: overrideProject.clientId!)?.hourlyRate
        #expect(inheritedRate == 110.0)
        #expect(overrideRate == 150.0)
    }

    @Test("Renaming and deleting tags updates store and preserves entry integrity")
    func tagRenameAndCleanup() {
        let store = PersistenceStore(inMemory: true)
        let tag = Tag(name: "frontend", colorHex: "#36B37E")
        store.saveTag(tag)

        let entry = TimeEntry(
            entryDescription: "Fix layout",
            startDate: Date().addingTimeInterval(-1200),
            endDate: Date(),
            accumulatedDuration: 1200,
            tagIds: [tag.id]
        )
        store.saveTimeEntry(entry)

        tag.name = "ui-polish"
        tag.colorHex = "#E54583"
        store.saveTag(tag)

        #expect(store.tag(for: tag.id)?.name == "ui-polish")
        #expect(entry.tagIds.contains(tag.id))

        store.deleteTag(id: tag.id)
        #expect(store.tags.isEmpty)
        #expect(!entry.tagIds.contains(tag.id))
    }

    @Test("SidebarDestination includes Tags with expected symbol image")
    func sidebarTagsDestinationPresent() {
        #expect(SidebarDestination.allCases.contains(.tags))
        #expect(SidebarDestination.tags.systemImage == "tag")
    }
}
