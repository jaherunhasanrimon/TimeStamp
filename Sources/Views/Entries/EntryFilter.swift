import Foundation

public enum EntryFilter: Equatable, Hashable {
    case none
    case project(UUID)
    case client(UUID)
}
