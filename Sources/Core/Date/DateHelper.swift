import Foundation

public struct DayGroup: Identifiable {
    public let date: Date
    public let entries: [TimeEntry]

    public var id: Date { date }

    public var totalDuration: TimeInterval {
        entries.reduce(0) { $0 + $1.effectiveDuration }
    }
}

public enum DateHelper {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    public static func startOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    public static func formatRelativeDay(_ date: Date, relativeTo reference: Date = Date(), calendar: Calendar = .current) -> String {
        let startOfTarget = calendar.startOfDay(for: date)
        let startOfRef = calendar.startOfDay(for: reference)

        if startOfTarget == startOfRef {
            return "Today"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfRef), startOfTarget == yesterday {
            return "Yesterday"
        } else {
            return dayFormatter.string(from: date)
        }
    }

    public static func formatTimeRange(start: Date, end: Date?, calendar: Calendar = .current) -> String {
        let startStr = timeFormatter.string(from: start)
        if let end = end {
            let endStr = timeFormatter.string(from: end)
            return "\(startStr) – \(endStr)"
        } else {
            return "\(startStr) – Now"
        }
    }

    public static func formatHumanDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded(.down)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }

    public static func groupEntriesByDay(_ entries: [TimeEntry], calendar: Calendar = .current) -> [DayGroup] {
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.startDate)
        }

        return grouped.map { date, dayEntries in
            let sortedEntries = dayEntries.sorted { $0.startDate > $1.startDate }
            return DayGroup(date: date, entries: sortedEntries)
        }
        .sorted { $0.date > $1.date }
    }
}
