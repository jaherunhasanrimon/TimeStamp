import Foundation
import Observation

@Observable
public final class TimeEntry: Identifiable, Codable {
    public let id: UUID
    public var entryDescription: String
    public var startDate: Date
    public var endDate: Date?
    public var accumulatedDuration: TimeInterval
    public var isPaused: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var projectId: UUID?
    public var taskId: UUID?
    public var tagIds: [UUID]

    public var isRunning: Bool {
        endDate == nil && !isPaused
    }

    public var effectiveDuration: TimeInterval {
        if let endDate = endDate {
            return accumulatedDuration + endDate.timeIntervalSince(startDate)
        } else if isPaused {
            return accumulatedDuration
        } else {
            return accumulatedDuration + max(0, Date().timeIntervalSince(startDate))
        }
    }

    public init(
        id: UUID = UUID(),
        entryDescription: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        accumulatedDuration: TimeInterval = 0,
        isPaused: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        projectId: UUID? = nil,
        taskId: UUID? = nil,
        tagIds: [UUID] = []
    ) {
        self.id = id
        self.entryDescription = entryDescription
        self.startDate = startDate
        self.endDate = endDate
        self.accumulatedDuration = accumulatedDuration
        self.isPaused = isPaused
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.projectId = projectId
        self.taskId = taskId
        self.tagIds = tagIds
    }

    enum CodingKeys: String, CodingKey {
        case id
        case entryDescription
        case startDate
        case endDate
        case accumulatedDuration
        case isPaused
        case createdAt
        case updatedAt
        case projectId
        case taskId
        case tagIds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.entryDescription = try container.decode(String.self, forKey: .entryDescription)
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        self.accumulatedDuration = try container.decode(TimeInterval.self, forKey: .accumulatedDuration)
        self.isPaused = try container.decode(Bool.self, forKey: .isPaused)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.taskId = try container.decodeIfPresent(UUID.self, forKey: .taskId)
        self.tagIds = try container.decodeIfPresent([UUID].self, forKey: .tagIds) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(entryDescription, forKey: .entryDescription)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(accumulatedDuration, forKey: .accumulatedDuration)
        try container.encode(isPaused, forKey: .isPaused)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(taskId, forKey: .taskId)
        try container.encode(tagIds, forKey: .tagIds)
    }
}
