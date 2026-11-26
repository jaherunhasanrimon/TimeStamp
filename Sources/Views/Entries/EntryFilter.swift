import Foundation

public enum EntryFilter: Equatable, Hashable {
    case none
    case project(UUID)
    case client(UUID)
    case tag(UUID)
    case billableOnly
    case nonBillableOnly
}
