import Foundation
import Observation

public enum GoalCadence: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekdays = "Weekdays (Mon–Fri)"
    case weekly = "Weekly"

    public var id: String { rawValue }
}

public enum GoalTargetType: String, Codable, CaseIterable, Identifiable {
    case atLeast = "At least"
    case lessThan = "Less than"

    public var id: String { rawValue }
}

public enum GoalBillableFilter: String, Codable, CaseIterable, Identifiable {
    case all = "All Entries"
    case billableOnly = "Billable Only"
    case nonBillableOnly = "Non-Billable Only"

    public var id: String { rawValue }
}

@Observable
public final class Goal: Identifiable, Codable, Equatable {
    public static func == (lhs: Goal, rhs: Goal) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.targetDuration == rhs.targetDuration &&
        lhs.targetType == rhs.targetType &&
        lhs.cadence == rhs.cadence &&
        lhs.projectId == rhs.projectId &&
        lhs.clientId == rhs.clientId &&
        lhs.taskId == rhs.taskId &&
        lhs.tagIds == rhs.tagIds &&
        lhs.billableFilter == rhs.billableFilter &&
        lhs.iconName == rhs.iconName &&
        lhs.createdAt == rhs.createdAt &&
        lhs.updatedAt == rhs.updatedAt
    }

    public let id: UUID
    public var title: String
    public var targetDuration: TimeInterval // Target in seconds
    public var targetType: GoalTargetType
    public var cadence: GoalCadence
    public var projectId: UUID? // Optional project association
    public var clientId: UUID? // Optional client association (matches any project of client)
    public var taskId: UUID? // Optional task association
    public var tagIds: [UUID] // Optional tag filters
    public var billableFilter: GoalBillableFilter // All, Billable only, Non-billable only
    public var iconName: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        targetDuration: TimeInterval,
        targetType: GoalTargetType = .atLeast,
        cadence: GoalCadence = .daily,
        projectId: UUID? = nil,
        clientId: UUID? = nil,
        taskId: UUID? = nil,
        tagIds: [UUID] = [],
        billableFilter: GoalBillableFilter = .all,
        iconName: String = "target",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.targetDuration = targetDuration
        self.targetType = targetType
        self.cadence = cadence
        self.projectId = projectId
        self.clientId = clientId
        self.taskId = taskId
        self.tagIds = tagIds
        self.billableFilter = billableFilter
        self.iconName = iconName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case targetDuration
        case targetType
        case cadence
        case projectId
        case clientId
        case taskId
        case tagIds
        case billableFilter
        case iconName
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.targetDuration = try container.decode(TimeInterval.self, forKey: .targetDuration)
        self.targetType = try container.decodeIfPresent(GoalTargetType.self, forKey: .targetType) ?? .atLeast
        self.cadence = try container.decodeIfPresent(GoalCadence.self, forKey: .cadence) ?? .daily
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        self.clientId = try container.decodeIfPresent(UUID.self, forKey: .clientId)
        self.taskId = try container.decodeIfPresent(UUID.self, forKey: .taskId)
        self.tagIds = try container.decodeIfPresent([UUID].self, forKey: .tagIds) ?? []
        self.billableFilter = try container.decodeIfPresent(GoalBillableFilter.self, forKey: .billableFilter) ?? .all
        self.iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "target"
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(targetDuration, forKey: .targetDuration)
        try container.encode(targetType, forKey: .targetType)
        try container.encode(cadence, forKey: .cadence)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(taskId, forKey: .taskId)
        try container.encode(tagIds, forKey: .tagIds)
        try container.encode(billableFilter, forKey: .billableFilter)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
