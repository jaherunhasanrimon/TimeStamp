import Foundation
import Observation

@Observable
public final class Task: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var isCompleted: Bool
    public var createdAt: Date
    public var projectId: UUID?

    public init(
        id: UUID = UUID(),
        name: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        projectId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.projectId = projectId
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isCompleted
        case createdAt
        case projectId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(projectId, forKey: .projectId)
    }
}
