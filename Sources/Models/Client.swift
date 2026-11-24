import Foundation
import Observation

@Observable
public final class Client: Identifiable, Codable, Equatable {
    public static func == (lhs: Client, rhs: Client) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.notes == rhs.notes &&
        lhs.hourlyRate == rhs.hourlyRate &&
        lhs.currency == rhs.currency &&
        lhs.createdAt == rhs.createdAt
    }

    public let id: UUID
    public var name: String
    public var notes: String?
    public var hourlyRate: Double?
    public var currency: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String = "",
        notes: String? = nil,
        hourlyRate: Double? = nil,
        currency: String = "$",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.hourlyRate = hourlyRate
        self.currency = currency
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case notes
        case hourlyRate
        case currency
        case createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.hourlyRate = try container.decodeIfPresent(Double.self, forKey: .hourlyRate)
        self.currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "$"
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(notes, forKey: .notes)
        try container.encode(hourlyRate, forKey: .hourlyRate)
        try container.encode(currency, forKey: .currency)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
