import Testing
@testable import TimeStamp
import Foundation

@Suite("Phase 1: Core Tracking UX, Autocomplete, Grouping & Favorites Tests")
@MainActor
struct Phase1CoreTrackingTests {

    @Test("TimeCalculator.formatCompactDuration uses single-digit hours when < 10h")
    func formatCompactDuration() {
        #expect(TimeCalculator.formatCompactDuration(0) == "0:00:00")
        #expect(TimeCalculator.formatCompactDuration(65) == "0:01:05")
        #expect(TimeCalculator.formatCompactDuration(3661) == "1:01:01")
        #expect(TimeCalculator.formatCompactDuration(36000) == "10:00:00")
    }

    @Test("EntryGroupingHelper collapses same-day identical entries and separates differing attributes")
    func entryGroupingHelperGroupsSimilar() {
        let proj = Project(name: "Core", colorHex: "#E54583")
        let tagA = Tag(name: "deep-work", colorHex: "#30D158")
        let tagB = Tag(name: "review", colorHex: "#0A84FF")
        let now = Date()

        let e1 = TimeEntry(
            entryDescription: "Build parser",
            startDate: now.addingTimeInterval(-3600),
            endDate: now.addingTimeInterval(-1800),
            accumulatedDuration: 1800,
            projectId: proj.id,
            tagIds: [tagA.id, tagB.id],
            isBillable: true
        )
        // Identical attributes (tags reversed order) -> should group with e1
        let e2 = TimeEntry(
            entryDescription: "Build parser",
            startDate: now.addingTimeInterval(-7200),
            endDate: now.addingTimeInterval(-6000),
            accumulatedDuration: 1200,
            projectId: proj.id,
            tagIds: [tagB.id, tagA.id],
            isBillable: true
        )
        // Different billable flag -> separate group
        let e3 = TimeEntry(
            entryDescription: "Build parser",
            startDate: now.addingTimeInterval(-10800),
            endDate: now.addingTimeInterval(-10200),
            accumulatedDuration: 600,
            projectId: proj.id,
            tagIds: [tagA.id, tagB.id],
            isBillable: false
        )

        let groups = EntryGroupingHelper.groupSimilar([e1, e2, e3])
        #expect(groups.count == 2)
        #expect(groups[0].isGroup == true)
        #expect(groups[0].count == 2)
        #expect(groups[0].totalDuration == 3000)
        #expect(groups[1].isGroup == false)
        #expect(groups[1].totalDuration == 600)
    }

    @Test("Favorites toggle, deduplicated listing, and backward-compatible Codable default")
    func favoritesAndCodableCompatibility() throws {
        let store = PersistenceStore(inMemory: true)
        let proj = Project(name: "Client X", colorHex: "#E54583")
        store.saveProject(proj)

        let t1 = TimeEntry(
            entryDescription: "Daily standup",
            startDate: Date().addingTimeInterval(-1000),
            endDate: Date().addingTimeInterval(-400),
            accumulatedDuration: 600,
            projectId: proj.id,
            isFavorite: false
        )
        let t2 = TimeEntry(
            entryDescription: "Daily standup",
            startDate: Date().addingTimeInterval(-5000),
            endDate: Date().addingTimeInterval(-4400),
            accumulatedDuration: 600,
            projectId: proj.id,
            isFavorite: true
        )
        store.saveTimeEntry(t1)
        store.saveTimeEntry(t2)

        store.toggleFavorite(id: t1.id)
        #expect(t1.isFavorite == true)
        // Duplicate attribute entries collapse in favoriteEntries
        #expect(store.favoriteEntries.count == 1)

        // Legacy JSON missing isFavorite decodes safely as false
        let legacyJSON = """
        {
            "id": "\(UUID().uuidString)",
            "entryDescription": "Legacy",
            "startDate": "2026-10-01T10:00:00Z",
            "accumulatedDuration": 120,
            "isPaused": false,
            "createdAt": "2026-10-01T10:00:00Z",
            "updatedAt": "2026-10-01T10:00:00Z",
            "tagIds": [],
            "isBillable": true
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TimeEntry.self, from: legacyJSON)
        #expect(decoded.isFavorite == false)
        #expect(decoded.isBillable == true)
    }

    @Test("Duplicate entry creates distinct non-favorite persisted copy and delete/undo restores cleanly")
    func duplicateAndUndoDelete() {
        let store = PersistenceStore(inMemory: true)
        let original = TimeEntry(
            entryDescription: "Write RFC",
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            accumulatedDuration: 3600,
            isBillable: true,
            isFavorite: true
        )
        store.saveTimeEntry(original)

        let copy = store.duplicateTimeEntry(original)
        #expect(copy.id != original.id)
        #expect(copy.entryDescription == original.entryDescription)
        #expect(copy.isBillable == true)
        #expect(copy.isFavorite == false)
        #expect(store.timeEntries.count == 2)

        store.deleteTimeEntry(id: copy.id)
        #expect(store.timeEntries.count == 1)
        #expect(store.lastDeletedEntry?.id == copy.id)

        let restored = store.undoLastDelete()
        #expect(restored?.id == copy.id)
        #expect(store.timeEntries.count == 2)
        #expect(store.lastDeletedEntry == nil)
    }

    @Test("recentUniqueEntries returns deduplicated most recent matches by description or project name")
    func recentUniqueEntriesAutocomplete() {
        let store = PersistenceStore(inMemory: true)
        let proj = Project(name: "Deep Learning", colorHex: "#5E5CE6")
        store.saveProject(proj)

        let older = TimeEntry(
            entryDescription: "Train CNN",
            startDate: Date().addingTimeInterval(-7200),
            endDate: Date().addingTimeInterval(-6000),
            accumulatedDuration: 1200,
            projectId: proj.id
        )
        let newerSame = TimeEntry(
            entryDescription: "Train CNN",
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date().addingTimeInterval(-900),
            accumulatedDuration: 900,
            projectId: proj.id
        )
        let projectMatchOnly = TimeEntry(
            entryDescription: "GPU Profiling",
            startDate: Date().addingTimeInterval(-3000),
            endDate: Date().addingTimeInterval(-2400),
            accumulatedDuration: 600,
            projectId: proj.id
        )
        store.saveTimeEntry(older)
        store.saveTimeEntry(newerSame)
        store.saveTimeEntry(projectMatchOnly)

        let trainMatches = store.recentUniqueEntries(matching: "train")
        #expect(trainMatches.count == 1)
        #expect(trainMatches.first?.id == newerSame.id)

        let deepMatches = store.recentUniqueEntries(matching: "deep")
        #expect(deepMatches.count == 2)
    }

    @Test("Default project applies cleanly when idle and skips archived projects")
    func applyDefaultProjectBehavior() {
        let store = PersistenceStore(inMemory: true)
        let activeProj = Project(name: "Main App", colorHex: "#30D158", isBillableDefault: true)
        let archivedProj = Project(name: "Old App", colorHex: "#8E8E93", isArchived: true)
        store.saveProject(activeProj)
        store.saveProject(archivedProj)

        let timer = TimerManager(store: store)
        timer.applyDefaultProjectIfIdle(defaultProjectIdString: archivedProj.id.uuidString)
        #expect(timer.retainedProjectId == nil)

        timer.applyDefaultProjectIfIdle(defaultProjectIdString: activeProj.id.uuidString)
        #expect(timer.retainedProjectId == activeProj.id)
        #expect(timer.retainedIsBillable == true)
    }

    @Test("Running active entry keeps endDate nil and reflects metadata edits live")
    func runningEntryMetadataPreservation() {
        let store = PersistenceStore(inMemory: true)
        let proj = Project(name: "TimeStamp", colorHex: "#E54583")
        store.saveProject(proj)
        let timer = TimerManager(store: store)

        timer.start(description: "Initial", isBillable: false)
        guard let active = timer.activeEntry else {
            Issue.record("Expected active entry")
            return
        }
        #expect(active.endDate == nil)

        // Simulate live metadata edit (Cmd+E flow) without stopping timer
        active.entryDescription = "Updated while running"
        active.projectId = proj.id
        active.isBillable = true
        store.saveTimeEntry(active)
        timer.updateTick()

        #expect(timer.activeEntry?.endDate == nil)
        #expect(timer.activeEntry?.isRunning == true)
        #expect(timer.activeEntry?.entryDescription == "Updated while running")
        #expect(timer.activeEntry?.projectId == proj.id)
    }
}
