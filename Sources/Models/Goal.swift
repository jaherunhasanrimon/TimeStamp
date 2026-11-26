import Foundation
import Observation

public enum GoalCadence: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekdays = "Weekdays (Mon–Fri)"
    case weekly = "Weekly"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .daily: return "every day"
        case .weekdays: return "every weekday"
        case .weekly: return "every week"
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch raw {
        case "daily", "every day":
            self = .daily
        case "weekdays", "weekdays (mon–fri)", "weekdays (mon-fri)", "every weekday", "each weekday (mon–fri)":
            self = .weekdays
        case "weekly", "every week":
            self = .weekly
        default:
            if let exact = GoalCadence.allCases.first(where: { $0.rawValue.lowercased() == raw }) {
                self = exact
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot initialize GoalCadence from invalid String value \(raw)"
                )
            }
        }
    }
}

public enum GoalTargetType: String, Codable, CaseIterable, Identifiable {
    case atLeast = "At least"
    case lessThan = "Less than"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .atLeast: return "at least"
        case .lessThan: return "less than"
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch raw {
        case "at least":
            self = .atLeast
        case "less than":
            self = .lessThan
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot initialize GoalTargetType from invalid String value \(raw)"
            )
        }
    }
}

public enum GoalBillableFilter: String, Codable, CaseIterable, Identifiable {
    case all = "All Entries"
    case billableOnly = "Billable Only"
    case nonBillableOnly = "Non-Billable Only"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .all: return "All entries"
        case .billableOnly: return "Billable only"
        case .nonBillableOnly: return "Non-billable only"
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch raw {
        case "all entries", "all":
            self = .all
        case "billable only", "billable":
            self = .billableOnly
        case "non-billable only", "non-billable", "nonbillable":
            self = .nonBillableOnly
        default:
            self = .all
        }
    }
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
        lhs.projectIds == rhs.projectIds &&
        lhs.clientId == rhs.clientId &&
        lhs.taskId == rhs.taskId &&
        lhs.tagIds == rhs.tagIds &&
        lhs.billableFilter == rhs.billableFilter &&
        lhs.iconName == rhs.iconName &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate
    }

    public let id: UUID
    public var title: String
    public var targetDuration: TimeInterval // Target in seconds
    public var targetType: GoalTargetType
    public var cadence: GoalCadence
    public var projectId: UUID? // Primary / legacy single-project association
    public var projectIds: [UUID] // Multi-project association (Toggl Track parity)
    public var clientId: UUID? // Optional client association (matches any project of client)
    public var taskId: UUID? // Optional task association
    public var tagIds: [UUID] // Optional tag filters
    public var billableFilter: GoalBillableFilter // All, Billable only, Non-billable only
    public var iconName: String
    public var startDate: Date
    public var endDate: Date?
    public var createdAt: Date
    public var updatedAt: Date

    /// Normalized list of tracked project IDs combining `projectIds` and legacy `projectId`.
    public var effectiveProjectIds: [UUID] {
        if !projectIds.isEmpty {
            return projectIds
        }
        return projectId.map { [$0] } ?? []
    }

    public init(
        id: UUID = UUID(),
        title: String,
        targetDuration: TimeInterval = 3600,
        targetType: GoalTargetType = .atLeast,
        cadence: GoalCadence = .daily,
        projectId: UUID? = nil,
        projectIds: [UUID] = [],
        clientId: UUID? = nil,
        taskId: UUID? = nil,
        tagIds: [UUID] = [],
        billableFilter: GoalBillableFilter = .all,
        iconName: String = "target",
        startDate: Date = Date(),
        endDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.targetDuration = targetDuration
        self.targetType = targetType
        self.cadence = cadence

        if !projectIds.isEmpty {
            self.projectIds = projectIds
            self.projectId = projectId ?? projectIds.first
        } else if let pid = projectId {
            self.projectIds = [pid]
            self.projectId = pid
        } else {
            self.projectIds = []
            self.projectId = nil
        }

        self.clientId = clientId
        self.taskId = taskId
        self.tagIds = tagIds
        self.billableFilter = billableFilter
        self.iconName = iconName
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, targetDuration, targetType, cadence
        case projectId, projectIds, clientId, taskId, tagIds, billableFilter, iconName
        case startDate, endDate, createdAt, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        targetDuration = try container.decode(TimeInterval.self, forKey: .targetDuration)
        targetType = try container.decode(GoalTargetType.self, forKey: .targetType)
        cadence = try container.decode(GoalCadence.self, forKey: .cadence)
        let decodedSingle = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        let decodedMulti = try container.decodeIfPresent([UUID].self, forKey: .projectIds) ?? []
        if !decodedMulti.isEmpty {
            projectIds = decodedMulti
            projectId = decodedSingle ?? decodedMulti.first
        } else if let pid = decodedSingle {
            projectIds = [pid]
            projectId = pid
        } else {
            projectIds = []
            projectId = nil
        }
        clientId = try container.decodeIfPresent(UUID.self, forKey: .clientId)
        taskId = try container.decodeIfPresent(UUID.self, forKey: .taskId)
        tagIds = try container.decodeIfPresent([UUID].self, forKey: .tagIds) ?? []
        billableFilter = try container.decodeIfPresent(GoalBillableFilter.self, forKey: .billableFilter) ?? .all
        iconName = try container.decode(String.self, forKey: .iconName)
        let decodedCreatedAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        createdAt = decodedCreatedAt
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? decodedCreatedAt
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(targetDuration, forKey: .targetDuration)
        try container.encode(targetType, forKey: .targetType)
        try container.encode(cadence, forKey: .cadence)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(projectIds, forKey: .projectIds)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(taskId, forKey: .taskId)
        try container.encode(tagIds, forKey: .tagIds)
        try container.encode(billableFilter, forKey: .billableFilter)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
