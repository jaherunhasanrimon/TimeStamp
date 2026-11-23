import Foundation
import Observation

private struct AppStorageData: Codable {
    var clients: [Client] = []
    var projects: [Project] = []
    var tasks: [Task] = []
    var tags: [Tag] = []
    var timeEntries: [TimeEntry] = []
}

@Observable
@MainActor
public final class PersistenceStore {
    public static let shared = PersistenceStore()

    public private(set) var clients: [Client] = []
    public private(set) var projects: [Project] = []
    public private(set) var tasks: [Task] = []
    public private(set) var tags: [Tag] = []
    public private(set) var timeEntries: [TimeEntry] = []

    public let isInMemory: Bool
    private let fileURL: URL?

    public init(inMemory: Bool = false) {
        self.isInMemory = inMemory
        if inMemory {
            self.fileURL = nil
        } else {
            let fileManager = FileManager.default
            let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDir = appSupportDir.appendingPathComponent("TimeStamp", isDirectory: true)
            if !fileManager.fileExists(atPath: appDir.path) {
                try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
            }
            self.fileURL = appDir.appendingPathComponent("timestamp_store.json")
            load()
        }
    }

    // MARK: - Persistence IO

    private func load() {
        guard !isInMemory, let fileURL = fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(AppStorageData.self, from: data)
            self.clients = decoded.clients
            self.projects = decoded.projects
            self.tasks = decoded.tasks
            self.tags = decoded.tags
            self.timeEntries = decoded.timeEntries
        } catch {
            print("[PersistenceStore] Failed to load data from \(fileURL): \(error)")
        }
    }

    public func save() {
        guard !isInMemory, let fileURL = fileURL else { return }
        do {
            let storageData = AppStorageData(
                clients: self.clients,
                projects: self.projects,
                tasks: self.tasks,
                tags: self.tags,
                timeEntries: self.timeEntries
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(storageData)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[PersistenceStore] Failed to save data: \(error)")
        }
    }

    // MARK: - Client CRUD

    public func saveClient(_ client: Client) {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
        } else {
            clients.append(client)
        }
        save()
    }

    public func deleteClient(id: UUID) {
        clients.removeAll { $0.id == id }
        // Unlink deleted client from any associated projects
        for project in projects where project.clientId == id {
            project.clientId = nil
        }
        save()
    }

    // MARK: - Project CRUD

    public func saveProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.append(project)
        }
        save()
    }

    public func deleteProject(id: UUID) {
        projects.removeAll { $0.id == id }
        // Cascade: delete child tasks
        tasks.removeAll { $0.projectId == id }
        // Unlink project from time entries
        for entry in timeEntries where entry.projectId == id {
            entry.projectId = nil
            entry.taskId = nil
        }
        save()
    }

    // MARK: - Task CRUD

    public func saveTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
        save()
    }

    public func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        // Unlink task from time entries
        for entry in timeEntries where entry.taskId == id {
            entry.taskId = nil
        }
        save()
    }

    // MARK: - Tag CRUD

    public func saveTag(_ tag: Tag) {
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[index] = tag
        } else {
            tags.append(tag)
        }
        save()
    }

    public func deleteTag(id: UUID) {
        tags.removeAll { $0.id == id }
        for entry in timeEntries {
            entry.tagIds.removeAll { $0 == id }
        }
        save()
    }

    // MARK: - TimeEntry CRUD

    public func saveTimeEntry(_ entry: TimeEntry) {
        if let index = timeEntries.firstIndex(where: { $0.id == entry.id }) {
            timeEntries[index] = entry
        } else {
            timeEntries.append(entry)
        }
        save()
    }

    public func deleteTimeEntry(id: UUID) {
        timeEntries.removeAll { $0.id == id }
        save()
    }

    // MARK: - Utilities

    public func project(for id: UUID) -> Project? {
        projects.first { $0.id == id }
    }

    public func task(for id: UUID) -> Task? {
        tasks.first { $0.id == id }
    }

    public func client(for id: UUID) -> Client? {
        clients.first { $0.id == id }
    }

    public func clearAll() {
        clients.removeAll()
        projects.removeAll()
        tasks.removeAll()
        tags.removeAll()
        timeEntries.removeAll()
        save()
    }
}
