import Foundation
import Observation

@Observable
public final class Project: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var colorHex: String
    public var isArchived: Bool
    public var createdAt: Date
    public var clientId: UUID?

    public init(
        id: UUID = UUID(),
        name: String = "",
        colorHex: String = "#5C3BFE",
        isArchived: Bool = false,
        createdAt: Date = Date(),
        clientId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.clientId = clientId
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case colorHex
        case isArchived
        case createdAt
        case clientId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.colorHex = try container.decode(String.self, forKey: .colorHex)
        self.isArchived = try container.decode(Bool.self, forKey: .isArchived)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.clientId = try container.decodeIfPresent(UUID.self, forKey: .clientId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(clientId, forKey: .clientId)
    }
}
