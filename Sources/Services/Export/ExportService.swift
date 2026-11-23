import AppKit
import Foundation
import UniformTypeIdentifiers

public struct ExportItem: Codable {
    public let id: String
    public let description: String
    public let date: String
    public let startTime: String
    public let endTime: String?
    public let durationSeconds: Double
    public let durationFormatted: String
    public let project: String?
    public let client: String?
    public let task: String?

    public init(
        id: String,
        description: String,
        date: String,
        startTime: String,
        endTime: String?,
        durationSeconds: Double,
        durationFormatted: String,
        project: String?,
        client: String?,
        task: String?
    ) {
        self.id = id
        self.description = description
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.durationFormatted = durationFormatted
        self.project = project
        self.client = client
        self.task = task
    }
}

public enum ExportService {

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    /// Generates RFC 4180 compliant CSV text
    public static func generateCSV(
        entries: [TimeEntry],
        projects: [Project],
        clients: [Client],
        tasks: [Task]
    ) -> String {
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        let clientMap = Dictionary(uniqueKeysWithValues: clients.map { ($0.id, $0) })
        let taskMap = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })

        var rows: [String] = []
        rows.append("Date,Start Time,End Time,Duration (Seconds),Duration (Formatted),Description,Project,Client,Task")

        let sorted = entries.sorted { $0.startDate < $1.startDate }

        for entry in sorted {
            let dateStr = dateFormatter.string(from: entry.startDate)
            let startStr = timeFormatter.string(from: entry.startDate)
            let endStr = entry.endDate.map { timeFormatter.string(from: $0) } ?? ""
            let durationSec = Int(entry.effectiveDuration)
            let durationFmt = DateHelper.formatHumanDuration(entry.effectiveDuration)

            let desc = escapeCSV(entry.entryDescription)

            var projName = ""
            var clientName = ""
            if let pId = entry.projectId, let proj = projectMap[pId] {
                projName = escapeCSV(proj.name)
                if let cId = proj.clientId, let client = clientMap[cId] {
                    clientName = escapeCSV(client.name)
                }
            }

            var taskName = ""
            if let tId = entry.taskId, let task = taskMap[tId] {
                taskName = escapeCSV(task.name)
            }

            let row = "\(dateStr),\(startStr),\(endStr),\(durationSec),\"\(durationFmt)\",\(desc),\(projName),\(clientName),\(taskName)"
            rows.append(row)
        }

        return rows.joined(separator: "\n")
    }

    /// Generates structured pretty-printed JSON data
    public static func generateJSON(
        entries: [TimeEntry],
        projects: [Project],
        clients: [Client],
        tasks: [Task]
    ) -> Data {
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        let clientMap = Dictionary(uniqueKeysWithValues: clients.map { ($0.id, $0) })
        let taskMap = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })

        let sorted = entries.sorted { $0.startDate < $1.startDate }

        let items: [ExportItem] = sorted.map { entry in
            let dateStr = dateFormatter.string(from: entry.startDate)
            let startStr = timeFormatter.string(from: entry.startDate)
            let endStr = entry.endDate.map { timeFormatter.string(from: $0) }
            let durationSec = entry.effectiveDuration
            let durationFmt = DateHelper.formatHumanDuration(entry.effectiveDuration)

            var projName: String? = nil
            var clientName: String? = nil
            if let pId = entry.projectId, let proj = projectMap[pId] {
                projName = proj.name
                if let cId = proj.clientId, let client = clientMap[cId] {
                    clientName = client.name
                }
            }

            let taskName = entry.taskId.flatMap { taskMap[$0]?.name }

            return ExportItem(
                id: entry.id.uuidString,
                description: entry.entryDescription,
                date: dateStr,
                startTime: startStr,
                endTime: endStr,
                durationSeconds: durationSec,
                durationFormatted: durationFmt,
                project: projName,
                client: clientName,
                task: taskName
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(items)) ?? Data("[]".utf8)
    }

    /// Presents native macOS NSSavePanel
    @MainActor
    public static func presentSavePanel(data: Data, defaultFilename: String, fileExtension: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultFilename
        panel.canCreateDirectories = true

        if fileExtension.lowercased() == "csv" {
            panel.allowedContentTypes = [UTType.commaSeparatedText]
        } else {
            panel.allowedContentTypes = [UTType.json]
        }

        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url, options: .atomic)
        }
    }

    private static func escapeCSV(_ text: String) -> String {
        let escaped = text.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
