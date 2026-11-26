import Foundation

/// Represents either a single entry row or a collapsible Toggl-style group of identical same-day entries
public struct GroupedEntryItem: Identifiable {
    public let id: String
    public let entries: [TimeEntry]
    public var representative: TimeEntry { entries[0] }
    public var isGroup: Bool { entries.count > 1 }
    public var count: Int { entries.count }
    public var totalDuration: TimeInterval {
        entries.reduce(0.0) { $0 + $1.effectiveDuration }
    }
}

public enum EntryGroupingHelper {
    /// Groups same-day entries sharing description, project, task, sorted tags, and billable flag
    public static func groupSimilar(_ entries: [TimeEntry]) -> [GroupedEntryItem] {
        var buckets: [String: [TimeEntry]] = [:]
        var orderedKeys: [String] = []

        for entry in entries.sorted(by: { $0.startDate > $1.startDate }) {
            let tagsKey = entry.tagIds.map(\.uuidString).sorted().joined(separator: ",")
            let key = "\(entry.entryDescription)|\(entry.projectId?.uuidString ?? "nil")|\(entry.taskId?.uuidString ?? "nil")|\(tagsKey)|\(entry.isBillable)"
            if buckets[key] == nil {
                orderedKeys.append(key)
                buckets[key] = [entry]
            } else {
                buckets[key]?.append(entry)
            }
        }

        return orderedKeys.compactMap { key in
            guard let groupEntries = buckets[key], !groupEntries.isEmpty else { return nil }
            let id = "\(key)|\(groupEntries.first!.id.uuidString)"
            return GroupedEntryItem(id: id, entries: groupEntries)
        }
    }
}
