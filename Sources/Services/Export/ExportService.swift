import Foundation
import AppKit
import UniformTypeIdentifiers

public struct ExportItem: Codable {
    public let date: String
    public let startTime: String
    public let endTime: String
    public let durationSeconds: Int
    public let durationFormatted: String
    public let description: String
    public let project: String
    public let client: String
    public let task: String
    public let tags: [String]?
    public let isBillable: Bool?
    public let billableRate: Double?
    public let billableAmount: Double?

    public init(
        date: String,
        startTime: String,
        endTime: String,
        durationSeconds: Int,
        durationFormatted: String,
        description: String,
        project: String,
        client: String,
        task: String,
        tags: [String]? = nil,
        isBillable: Bool? = nil,
        billableRate: Double? = nil,
        billableAmount: Double? = nil
    ) {
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.durationFormatted = durationFormatted
        self.description = description
        self.project = project
        self.client = client
        self.task = task
        self.tags = tags
        self.isBillable = isBillable
        self.billableRate = billableRate
        self.billableAmount = billableAmount
    }
}

public enum ExportService {

    /// Generates an RFC 4180 compliant CSV string for the supplied entries.
    /// Keeps the canonical 9-column header by default; when `includeExtendedColumns` is true,
    /// appends `Tags,Billable,Rate,Amount`.
    public static func generateCSV(
        entries: [TimeEntry],
        projects: [Project],
        clients: [Client],
        tasks: [Task],
        tags: [Tag] = [],
        defaultHourlyRate: Double = 0.0,
        includeExtendedColumns: Bool = false
    ) -> String {
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        let clientMap = Dictionary(uniqueKeysWithValues: clients.map { ($0.id, $0) })
        let taskMap = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        let tagMap = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0) })

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm:ss"

        var header = "Date,Start Time,End Time,Duration (Seconds),Duration (Formatted),Description,Project,Client,Task"
        if includeExtendedColumns {
            header += ",Tags,Billable,Rate,Amount"
        }
        var lines = [header]

        for entry in entries {
            let proj = entry.projectId.flatMap { projectMap[$0] }
            let client = proj?.clientId.flatMap { clientMap[$0] }
            let task = entry.taskId.flatMap { taskMap[$0] }

            let dateStr = dateFmt.string(from: entry.startDate)
            let startStr = timeFmt.string(from: entry.startDate)
            let endStr = entry.endDate.map { timeFmt.string(from: $0) } ?? "Running"
            let durationSec = Int(round(entry.effectiveDuration))
            let durationFmt = TimeCalculator.formatDuration(TimeInterval(durationSec))

            var cols = [
                escapeCSV(dateStr),
                escapeCSV(startStr),
                escapeCSV(endStr),
                "\(durationSec)",
                escapeCSV(durationFmt),
                escapeCSV(entry.entryDescription),
                escapeCSV(proj?.name ?? ""),
                escapeCSV(client?.name ?? ""),
                escapeCSV(task?.name ?? "")
            ]

            if includeExtendedColumns {
                let tagNames = entry.tagIds.compactMap { tagMap[$0]?.name }.joined(separator: "; ")
                let rate = entry.isBillable ? (proj?.hourlyRate ?? client?.hourlyRate ?? defaultHourlyRate) : 0.0
                let amount = entry.isBillable ? (entry.effectiveDuration / 3600.0) * rate : 0.0
                cols.append(escapeCSV(tagNames))
                cols.append(entry.isBillable ? "Yes" : "No")
                cols.append(String(format: "%.2f", rate))
                cols.append(String(format: "%.2f", amount))
            }

            lines.append(cols.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    /// Generates formatted JSON export data
    public static func generateJSON(
        entries: [TimeEntry],
        projects: [Project],
        clients: [Client],
        tasks: [Task],
        tags: [Tag] = [],
        defaultHourlyRate: Double = 0.0
    ) -> Data {
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        let clientMap = Dictionary(uniqueKeysWithValues: clients.map { ($0.id, $0) })
        let taskMap = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        let tagMap = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0) })

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm:ss"

        let items: [ExportItem] = entries.map { entry in
            let proj = entry.projectId.flatMap { projectMap[$0] }
            let client = proj?.clientId.flatMap { clientMap[$0] }
            let task = entry.taskId.flatMap { taskMap[$0] }

            let durationSec = Int(round(entry.effectiveDuration))
            let durationFmt = TimeCalculator.formatDuration(TimeInterval(durationSec))
            let tagNames = entry.tagIds.compactMap { tagMap[$0]?.name }
            let rate = entry.isBillable ? (proj?.hourlyRate ?? client?.hourlyRate ?? defaultHourlyRate) : 0.0
            let amount = entry.isBillable ? (entry.effectiveDuration / 3600.0) * rate : 0.0

            return ExportItem(
                date: dateFmt.string(from: entry.startDate),
                startTime: timeFmt.string(from: entry.startDate),
                endTime: entry.endDate.map { timeFmt.string(from: $0) } ?? "Running",
                durationSeconds: durationSec,
                durationFormatted: durationFmt,
                description: entry.entryDescription,
                project: proj?.name ?? "",
                client: client?.name ?? "",
                task: task?.name ?? "",
                tags: tagNames,
                isBillable: entry.isBillable,
                billableRate: rate,
                billableAmount: amount
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(items)) ?? Data("[]".utf8)
    }

    /// Renders a clean native multi-page vector PDF summary and entry breakdown report.
    public static func generatePDF(
        title: String,
        periodLabel: String,
        entries: [TimeEntry],
        projects: [Project],
        clients: [Client],
        tasks: [Task],
        defaultHourlyRate: Double = 0.0
    ) -> Data {
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        let clientMap = Dictionary(uniqueKeysWithValues: clients.map { ($0.id, $0) })
        let taskMap = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let margin: CGFloat = 44
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            return Data()
        }
        var mediaBox = pageRect
        guard let cgContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        let totalSeconds = entries.reduce(0.0) { $0 + $1.effectiveDuration }
        let billableSeconds = entries.filter(\.isBillable).reduce(0.0) { $0 + $1.effectiveDuration }
        let totalAmount = entries.filter(\.isBillable).reduce(0.0) { sum, entry in
            let proj = entry.projectId.flatMap { projectMap[$0] }
            let client = proj?.clientId.flatMap { clientMap[$0] }
            let rate = proj?.hourlyRate ?? client?.hourlyRate ?? defaultHourlyRate
            return sum + (entry.effectiveDuration / 3600.0) * rate
        }

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 20),
            .foregroundColor: NSColor.black
        ]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.darkGray
        ]
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 10),
            .foregroundColor: NSColor.darkGray
        ]
        let rowAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.black
        ]
        let monoAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium),
            .foregroundColor: NSColor.black
        ]

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd HH:mm"

        var currentY: CGFloat = pageRect.height - margin
        var pageStarted = false

        func beginNewPage() {
            if pageStarted {
                cgContext.endPDFPage()
            }
            cgContext.beginPDFPage(nil)
            pageStarted = true
            let gfx = NSGraphicsContext(cgContext: cgContext, flipped: false)
            NSGraphicsContext.current = gfx
            currentY = pageRect.height - margin
        }

        beginNewPage()

        // Report Header
        (title as NSString).draw(at: NSPoint(x: margin, y: currentY - 22), withAttributes: titleAttrs)
        currentY -= 30
        ("Period: \(periodLabel)   •   Entries: \(entries.count)" as NSString).draw(at: NSPoint(x: margin, y: currentY - 14), withAttributes: subtitleAttrs)
        currentY -= 24

        let summaryLine = "Total: \(TimeCalculator.formatCompactDuration(totalSeconds))   |   Billable: \(TimeCalculator.formatCompactDuration(billableSeconds))   |   Estimated Amount: $\(String(format: "%.2f", totalAmount))"
        (summaryLine as NSString).draw(at: NSPoint(x: margin, y: currentY - 14), withAttributes: headerAttrs)
        currentY -= 24

        cgContext.setStrokeColor(NSColor.lightGray.cgColor)
        cgContext.setLineWidth(0.75)
        cgContext.move(to: CGPoint(x: margin, y: currentY))
        cgContext.addLine(to: CGPoint(x: pageRect.width - margin, y: currentY))
        cgContext.strokePath()
        currentY -= 18

        // Table Header
        ("START TIME" as NSString).draw(at: NSPoint(x: margin, y: currentY - 12), withAttributes: headerAttrs)
        ("DESCRIPTION" as NSString).draw(at: NSPoint(x: margin + 96, y: currentY - 12), withAttributes: headerAttrs)
        ("PROJECT" as NSString).draw(at: NSPoint(x: margin + 305, y: currentY - 12), withAttributes: headerAttrs)
        ("BILL" as NSString).draw(at: NSPoint(x: margin + 425, y: currentY - 12), withAttributes: headerAttrs)
        ("DURATION" as NSString).draw(at: NSPoint(x: margin + 465, y: currentY - 12), withAttributes: headerAttrs)
        currentY -= 20

        let sortedEntries = entries.sorted { $0.startDate > $1.startDate }
        for entry in sortedEntries {
            if currentY < margin + 24 {
                beginNewPage()
                ("TIME ENTRIES (CONT.)" as NSString).draw(at: NSPoint(x: margin, y: currentY - 14), withAttributes: headerAttrs)
                currentY -= 26
            }

            let proj = entry.projectId.flatMap { projectMap[$0] }
            let task = entry.taskId.flatMap { taskMap[$0] }
            let desc = entry.entryDescription.isEmpty ? "(No description)" : entry.entryDescription
            let projLabel = [proj?.name, task?.name].compactMap { $0 }.joined(separator: " · ")

            let clippedDesc = String(desc.prefix(34))
            let clippedProj = String((projLabel.isEmpty ? "No Project" : projLabel).prefix(20))

            (dateFmt.string(from: entry.startDate) as NSString).draw(at: NSPoint(x: margin, y: currentY - 12), withAttributes: monoAttrs)
            (clippedDesc as NSString).draw(at: NSPoint(x: margin + 96, y: currentY - 12), withAttributes: rowAttrs)
            (clippedProj as NSString).draw(at: NSPoint(x: margin + 305, y: currentY - 12), withAttributes: subtitleAttrs)
            ((entry.isBillable ? "$" : "–") as NSString).draw(at: NSPoint(x: margin + 432, y: currentY - 12), withAttributes: monoAttrs)
            (TimeCalculator.formatCompactDuration(entry.effectiveDuration) as NSString).draw(at: NSPoint(x: margin + 465, y: currentY - 12), withAttributes: monoAttrs)

            currentY -= 18
        }

        if pageStarted {
            cgContext.endPDFPage()
        }
        cgContext.closePDF()
        NSGraphicsContext.current = nil
        return pdfData as Data
    }

    /// Presents native macOS NSSavePanel
    @MainActor
    public static func presentSavePanel(data: Data, defaultFilename: String, fileExtension: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultFilename
        panel.canCreateDirectories = true

        switch fileExtension.lowercased() {
        case "csv":
            panel.allowedContentTypes = [UTType.commaSeparatedText]
        case "pdf":
            panel.allowedContentTypes = [UTType.pdf]
        default:
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
