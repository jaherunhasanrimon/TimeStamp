import Foundation

@MainActor
public enum PreviewContainer {
    public static var sample: PersistenceStore {
        let store = PersistenceStore(inMemory: true)

        let acme = Client(name: "Acme Corp", notes: "Enterprise client")
        let globex = Client(name: "Globex Corporation", notes: "SaaS platform")
        store.saveClient(acme)
        store.saveClient(globex)

        let p1 = Project(name: "Brand Identity", colorHex: "#5C3BFE", clientId: acme.id)
        let p2 = Project(name: "macOS App Development", colorHex: "#0A84FF", clientId: acme.id)
        let p3 = Project(name: "Design System Tokens", colorHex: "#30D158", clientId: globex.id)
        let p4 = Project(name: "Internal Roadmap", colorHex: "#FF9F0A")
        store.saveProject(p1)
        store.saveProject(p2)
        store.saveProject(p3)
        store.saveProject(p4)

        let t1 = Task(name: "High-Fidelity Wireframes", isCompleted: true, projectId: p1.id)
        let t2 = Task(name: "Implement Persistence Store", isCompleted: true, projectId: p2.id)
        let t3 = Task(name: "Navigation Split View Shell", isCompleted: false, projectId: p2.id)
        store.saveTask(t1)
        store.saveTask(t2)
        store.saveTask(t3)

        let tag1 = Tag(name: "Deep Work", colorHex: "#7B61FF")
        let tag2 = Tag(name: "Meeting", colorHex: "#FF375F")
        store.saveTag(tag1)
        store.saveTag(tag2)

        let now = Date()
        let e1 = TimeEntry(
            entryDescription: "Architecting domain models and local storage",
            startDate: now.addingTimeInterval(-7200),
            endDate: now.addingTimeInterval(-3600),
            accumulatedDuration: 3600,
            isPaused: false,
            projectId: p2.id,
            taskId: t2.id,
            tagIds: [tag1.id]
        )
        let e2 = TimeEntry(
            entryDescription: "Weekly design alignment",
            startDate: now.addingTimeInterval(-3000),
            endDate: now.addingTimeInterval(-1200),
            accumulatedDuration: 1800,
            isPaused: false,
            projectId: p1.id,
            taskId: t1.id,
            tagIds: [tag2.id]
        )
        store.saveTimeEntry(e1)
        store.saveTimeEntry(e2)

        return store
    }
}
