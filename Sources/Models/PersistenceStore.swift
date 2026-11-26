import Foundation
import Observation

private struct AppStorageData: Codable {
    var clients: [Client] = []
    var projects: [Project] = []
    var tasks: [Task] = []
    var tags: [Tag] = []
    var timeEntries: [TimeEntry] = []
    var goals: [Goal] = []

    enum CodingKeys: String, CodingKey {
        case clients, projects, tasks, tags, timeEntries, goals
    }

    init(
        clients: [Client] = [],
        projects: [Project] = [],
        tasks: [Task] = [],
        tags: [Tag] = [],
        timeEntries: [TimeEntry] = [],
        goals: [Goal] = []
    ) {
        self.clients = clients
        self.projects = projects
        self.tasks = tasks
        self.tags = tags
        self.timeEntries = timeEntries
        self.goals = goals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clients = try container.decodeIfPresent([Client].self, forKey: .clients) ?? []
        self.projects = try container.decodeIfPresent([Project].self, forKey: .projects) ?? []
        self.tasks = try container.decodeIfPresent([Task].self, forKey: .tasks) ?? []
        self.tags = try container.decodeIfPresent([Tag].self, forKey: .tags) ?? []
        self.timeEntries = try container.decodeIfPresent([TimeEntry].self, forKey: .timeEntries) ?? []
        self.goals = try container.decodeIfPresent([Goal].self, forKey: .goals) ?? []
    }
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
    public private(set) var goals: [Goal] = []
    public private(set) var lastDeletedEntry: TimeEntry? = nil

    public let isInMemory: Bool
    private let fileURL: URL?

    public init(inMemory: Bool = false, storageDirectory: URL? = nil) {
        self.isInMemory = inMemory
        if inMemory {
            self.fileURL = nil
        } else {
            let fileManager = FileManager.default
            let appDir: URL
            if let customDir = storageDirectory {
                appDir = customDir
            } else {
                let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                appDir = appSupportDir.appendingPathComponent("TimeStamp", isDirectory: true)
            }
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
            self.goals = decoded.goals
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
                timeEntries: self.timeEntries,
                goals: self.goals
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
        // Unlink project from goals
        for goal in goals where goal.projectId == id || goal.projectIds.contains(id) {
            goal.projectIds.removeAll { $0 == id }
            if goal.projectId == id {
                goal.projectId = goal.projectIds.first
            }
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

    public func tag(for id: UUID) -> Tag? {
        tags.first { $0.id == id }
    }

    // MARK: - Goal CRUD

    public func saveGoal(_ goal: Goal) {
        goal.updatedAt = Date()
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        } else {
            goals.append(goal)
        }
        save()
    }

    public func deleteGoal(id: UUID) {
        goals.removeAll { $0.id == id }
        save()
    }

    public func goal(for id: UUID) -> Goal? {
        goals.first { $0.id == id }
    }

    // MARK: - Goal Progress Calculation

    /// Evaluates if a TimeEntry satisfies all criteria of a Goal
    public func entryMatchesGoal(
        entry: TimeEntry,
        projectId: UUID?,
        projectIds: [UUID] = [],
        clientId: UUID?,
        taskId: UUID?,
        tagIds: [UUID],
        billableFilter: GoalBillableFilter
    ) -> Bool {
        // 1. Project & Client association (Correction 2: entries belong to projects, not clients)
        let allowedProjectIds = projectIds.isEmpty ? (projectId.map { [$0] } ?? []) : projectIds
        if !allowedProjectIds.isEmpty {
            guard let entryProjectId = entry.projectId,
                  allowedProjectIds.contains(entryProjectId) else { return false }
        } else if let cId = clientId {
            guard let entryProjectId = entry.projectId,
                  let project = project(for: entryProjectId),
                  project.clientId == cId else { return false }
        }

        // 2. Task filter
        if let tId = taskId {
            guard entry.taskId == tId else { return false }
        }

        // 3. Tag filter
        if !tagIds.isEmpty {
            guard entry.tagIds.contains(where: { tagIds.contains($0) }) else { return false }
        }

        // 4. Billable filter
        switch billableFilter {
        case .all:
            break
        case .billableOnly:
            guard entry.isBillable else { return false }
        case .nonBillableOnly:
            guard !entry.isBillable else { return false }
        }

        return true
    }

    /// Calculates progress towards a goal within its cadence and target type
    public func progress(
        for goal: Goal,
        in calendar: Calendar = .current,
        now: Date = Date(),
        activeEntry: TimeEntry? = nil,
        activeDuration: TimeInterval = 0
    ) -> (completedDuration: TimeInterval, percentage: Double, isCompleted: Bool, isOverLimit: Bool) {
        // Calculate date boundaries (Correction 1: weekdays is evaluated on each individual weekday)
        let (intervalStart, intervalEnd, isWeekendSkip): (Date, Date, Bool) = {
            switch goal.cadence {
            case .daily:
                let start = calendar.startOfDay(for: now)
                let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
                return (start, end, false)

            case .weekdays:
                if calendar.isDateInWeekend(now) {
                    // On weekend days, weekday tracking pauses cleanly without accumulating towards weekday targets
                    return (now, now, true)
                } else {
                    let start = calendar.startOfDay(for: now)
                    let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
                    return (start, end, false)
                }

            case .weekly:
                var cal = calendar
                cal.firstWeekday = 2 // Monday start (ISO)
                let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
                let start = cal.date(from: components) ?? cal.startOfDay(for: now)
                let end = cal.date(byAdding: .day, value: 7, to: start) ?? now
                return (start, end, false)
            }
        }()

        if isWeekendSkip {
            return (0, 0, false, false)
        }

        // Respect goal active date window using day boundaries
        let evalDay = calendar.startOfDay(for: now)
        if evalDay < calendar.startOfDay(for: goal.startDate) {
            return (0, 0, false, false)
        }
        if let goalEnd = goal.endDate, evalDay > calendar.startOfDay(for: goalEnd) {
            return (0, 0, false, false)
        }

        // Sum completed entries in this date interval (exclude running/paused active entries)
        var completedTotal: TimeInterval = 0
        for entry in timeEntries {
            guard entry.endDate != nil else { continue }
            guard entry.startDate >= intervalStart && entry.startDate < intervalEnd else { continue }
            if entryMatchesGoal(
                entry: entry,
                projectId: goal.projectId,
                projectIds: goal.effectiveProjectIds,
                clientId: goal.clientId,
                taskId: goal.taskId,
                tagIds: goal.tagIds,
                billableFilter: goal.billableFilter
            ) {
                completedTotal += entry.effectiveDuration
            }
        }

        // Add contribution from currently running/paused active timer if matching & within period
        if let active = activeEntry,
           active.endDate == nil,
           active.startDate >= intervalStart && active.startDate < intervalEnd,
           entryMatchesGoal(
               entry: active,
               projectId: goal.projectId,
               projectIds: goal.effectiveProjectIds,
               clientId: goal.clientId,
               taskId: goal.taskId,
               tagIds: goal.tagIds,
               billableFilter: goal.billableFilter
           ) {
            completedTotal += activeDuration
        }

        let target = max(1.0, goal.targetDuration)
        switch goal.targetType {
        case .atLeast:
            let pct = min(1.0, completedTotal / target)
            let isDone = completedTotal >= target
            return (completedTotal, pct, isDone, false)

        case .lessThan:
            let pct = completedTotal / target
            let isOverLimit = completedTotal > target
            let isDone = !isOverLimit
            return (completedTotal, pct, isDone, isOverLimit)
        }
    }

    /// Previews progress for draft criteria before creating/saving a Goal
    public func progressPreview(
        targetDuration: TimeInterval,
        targetType: GoalTargetType,
        cadence: GoalCadence,
        projectId: UUID?,
        projectIds: [UUID] = [],
        clientId: UUID?,
        taskId: UUID?,
        tagIds: [UUID],
        billableFilter: GoalBillableFilter,
        startDate: Date = Date(),
        endDate: Date? = nil,
        in calendar: Calendar = .current,
        now: Date = Date()
    ) -> (matchingDuration: TimeInterval, percentage: Double, isCompleted: Bool, isOverLimit: Bool) {
        let tempGoal = Goal(
            title: "Preview",
            targetDuration: targetDuration,
            targetType: targetType,
            cadence: cadence,
            projectId: projectId,
            projectIds: projectIds,
            clientId: clientId,
            taskId: taskId,
            tagIds: tagIds,
            billableFilter: billableFilter,
            startDate: startDate,
            endDate: endDate
        )
        let p = progress(for: tempGoal, in: calendar, now: now)
        return (matchingDuration: p.completedDuration, percentage: p.percentage, isCompleted: p.isCompleted, isOverLimit: p.isOverLimit)
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
        if let existing = timeEntries.first(where: { $0.id == id }), existing.endDate != nil {
            self.lastDeletedEntry = existing
        }
        timeEntries.removeAll { $0.id == id }
        save()
    }

    /// Restores the most recently deleted completed time entry
    @discardableResult
    public func undoLastDelete() -> TimeEntry? {
        guard let deleted = lastDeletedEntry else { return nil }
        lastDeletedEntry = nil
        saveTimeEntry(deleted)
        return deleted
    }

    public func clearUndoBuffer() {
        lastDeletedEntry = nil
    }

    /// Creates a persisted duplicate of a completed entry
    @discardableResult
    public func duplicateTimeEntry(_ entry: TimeEntry) -> TimeEntry {
        let now = Date()
        let copy = TimeEntry(
            entryDescription: entry.entryDescription,
            startDate: entry.startDate,
            endDate: entry.endDate,
            accumulatedDuration: entry.effectiveDuration,
            isPaused: false,
            createdAt: now,
            updatedAt: now,
            projectId: entry.projectId,
            taskId: entry.taskId,
            tagIds: entry.tagIds,
            isBillable: entry.isBillable,
            isFavorite: false
        )
        saveTimeEntry(copy)
        return copy
    }

    /// Toggles favorite status for quick-start pinning
    public func toggleFavorite(id: UUID) {
        guard let entry = timeEntries.first(where: { $0.id == id }) else { return }
        entry.isFavorite.toggle()
        entry.updatedAt = Date()
        save()
    }

    /// Deduplicated favorite entries sorted by most recent usage
    public var favoriteEntries: [TimeEntry] {
        var seenKeys: Set<String> = []
        var result: [TimeEntry] = []
        let candidates = timeEntries
            .filter { $0.isFavorite && $0.endDate != nil }
            .sorted { $0.startDate > $1.startDate }
        for entry in candidates {
            let key = "\(entry.entryDescription)|\(entry.projectId?.uuidString ?? "")|\(entry.taskId?.uuidString ?? "")|\(entry.isBillable)"
            if seenKeys.insert(key).inserted {
                result.append(entry)
            }
        }
        return result
    }

    /// Recent unique completed entries for description autocomplete suggestions
    public func recentUniqueEntries(matching query: String, limit: Int = 6) -> [TimeEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return [] }
        var seen: Set<String> = []
        var matches: [TimeEntry] = []
        let candidates = timeEntries
            .filter { $0.endDate != nil && !$0.entryDescription.trimmingCharacters(in: .whitespaces).isEmpty }
            .sorted { $0.startDate > $1.startDate }
        for entry in candidates {
            let desc = entry.entryDescription.lowercased()
            let projName = entry.projectId.flatMap { project(for: $0)?.name.lowercased() } ?? ""
            guard desc.contains(trimmed) || projName.contains(trimmed) else { continue }
            let key = "\(entry.entryDescription)|\(entry.projectId?.uuidString ?? "")|\(entry.taskId?.uuidString ?? "")|\(entry.tagIds.map(\.uuidString).sorted().joined(separator: ","))|\(entry.isBillable)"
            if seen.insert(key).inserted {
                matches.append(entry)
                if matches.count >= limit { break }
            }
        }
        return matches
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

    // MARK: - Safe Backup & Reset

    @discardableResult
    public func backupStore() -> URL? {
        guard !isInMemory, let fileURL = fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let fileManager = FileManager.default
        let appDir = fileURL.deletingLastPathComponent()
        let backupsDir = appDir.appendingPathComponent("backups", isDirectory: true)
        if !fileManager.fileExists(atPath: backupsDir.path) {
            try? fileManager.createDirectory(at: backupsDir, withIntermediateDirectories: true)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let backupURL = backupsDir.appendingPathComponent("timestamp_store_backup_\(timestamp).json")
        do {
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.copyItem(at: fileURL, to: backupURL)
            print("[PersistenceStore] Successfully created backup at \(backupURL.path)")
            return backupURL
        } catch {
            print("[PersistenceStore] Failed to backup store: \(error)")
            return nil
        }
    }

    @discardableResult
    public func resetToCleanState(createBackup: Bool = true) -> URL? {
        var backupURL: URL? = nil
        if createBackup {
            backupURL = backupStore()
        }
        clients.removeAll()
        projects.removeAll()
        tasks.removeAll()
        tags.removeAll()
        timeEntries.removeAll()
        goals.removeAll()
        save()
        return backupURL
    }

    public func clearAll() {
        _ = resetToCleanState(createBackup: true)
    }
}
