import Testing
@testable import TimeStamp
import Foundation

@Suite("DateHelper & Daily Grouping Tests")
struct DateHelperTests {

    @Test("formatRelativeDay returns Today, Yesterday, and formatted date")
    func relativeDayFormatting() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        #expect(DateHelper.formatRelativeDay(today, relativeTo: today, calendar: calendar) == "Today")
        #expect(DateHelper.formatRelativeDay(yesterday, relativeTo: today, calendar: calendar) == "Yesterday")

        let olderStr = DateHelper.formatRelativeDay(threeDaysAgo, relativeTo: today, calendar: calendar)
        #expect(olderStr != "Today" && olderStr != "Yesterday")
        #expect(olderStr.contains(","))
    }

    @Test("formatHumanDuration produces compact human-readable duration strings")
    func humanDurationFormatting() {
        #expect(DateHelper.formatHumanDuration(0) == "0m")
        #expect(DateHelper.formatHumanDuration(45 * 60) == "45m")
        #expect(DateHelper.formatHumanDuration(3600) == "1h")
        #expect(DateHelper.formatHumanDuration(3600 + 15 * 60) == "1h 15m")
        #expect(DateHelper.formatHumanDuration(15300) == "4h 15m")
    }

    @Test("formatTimeRange formats system locale start and end times")
    func timeRangeFormatting() {
        let start = Date(timeIntervalSince1970: 1700000000)
        let end = Date(timeIntervalSince1970: 1700003600)

        let rangeWithEnd = DateHelper.formatTimeRange(start: start, end: end)
        #expect(rangeWithEnd.contains("–"))

        let rangeRunning = DateHelper.formatTimeRange(start: start, end: nil)
        #expect(rangeRunning.contains("Now"))
    }

    @Test("groupEntriesByDay sorts days and entries descending")
    func groupEntriesByDay() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let e1 = TimeEntry(entryDescription: "Today Morning", startDate: today.addingTimeInterval(-3600))
        let e2 = TimeEntry(entryDescription: "Today Afternoon", startDate: today)
        let e3 = TimeEntry(entryDescription: "Yesterday Task", startDate: yesterday)

        let groups = DateHelper.groupEntriesByDay([e1, e2, e3], calendar: calendar)

        #expect(groups.count == 2)
        #expect(groups[0].date == calendar.startOfDay(for: today))
        #expect(groups[1].date == calendar.startOfDay(for: yesterday))
        #expect(groups[0].entries.count == 2)
        #expect(groups[0].entries[0].entryDescription == "Today Afternoon")
        #expect(groups[0].entries[1].entryDescription == "Today Morning")
        #expect(groups[1].entries.count == 1)
    }
}
