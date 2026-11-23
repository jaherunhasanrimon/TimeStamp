import Foundation

public enum SidebarDestination: String, CaseIterable, Identifiable, Hashable {
    case timer = "Timer & Entries"
    case calendar = "Calendar"
    case dashboard = "Dashboard"
    case reports = "Reports"
    case projects = "Projects"
    case clients = "Clients"
    case settings = "Settings"

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .timer:
            return "stopwatch"
        case .calendar:
            return "calendar"
        case .dashboard:
            return "square.grid.2x2"
        case .reports:
            return "chart.bar.xaxis"
        case .projects:
            return "folder"
        case .clients:
            return "person.2"
        case .settings:
            return "gearshape"
        }
    }
}
