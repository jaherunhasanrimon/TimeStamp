import Testing
import Foundation
@testable import TimeStamp

@Suite("Calendar Timeline Navigation & Aggregation Tests")
@MainActor
struct CalendarTimelineTests {

    @Test("Week start computation resolves Monday 00:00 correctly from any day of the week")
    func testWeekStartComputation() throws {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday

        // Let's create a known Wednesday
        // 2026-11-25 is Wednesday
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 11
        comp.day = 25
        comp.hour = 14
        let wednesday = calendar.date(from: comp)!

        let weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: wednesday)
        let resolvedMonday = calendar.date(from: weekComponents)!

        let mondayDay = calendar.component(.day, from: resolvedMonday)
        let mondayWeekday = calendar.component(.weekday, from: resolvedMonday)

        #expect(mondayDay == 23) // 2026-11-23 is Monday
        #expect(mondayWeekday == 2) // In Gregorian calendar, 2 = Monday
    }

    @Test("Date navigation shifts day by +1/-1 and week by +7/-7")
    func testDateNavigationShifts() throws {
        let calendar = Calendar.current
        let baseDate = Date()

        // Day step: +1 / -1
        let nextDay = calendar.date(byAdding: .day, value: 1, to: baseDate)!
        let prevDay = calendar.date(byAdding: .day, value: -1, to: baseDate)!

        #expect(calendar.dateComponents([.day], from: baseDate, to: nextDay).day == 1)
        #expect(calendar.dateComponents([.day], from: baseDate, to: prevDay).day == -1)

        // Week step: +7 / -7
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: baseDate)!
        let prevWeek = calendar.date(byAdding: .day, value: -7, to: baseDate)!

        #expect(calendar.dateComponents([.day], from: baseDate, to: nextWeek).day == 7)
        #expect(calendar.dateComponents([.day], from: baseDate, to: prevWeek).day == -7)
    }

    @Test("Daily tracked totals correctly aggregate entries per day across week")
    func testDailyTrackedTotalsAcrossWeek() throws {
        let store = PersistenceStore(inMemory: true)
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday

        let now = Date()
        let weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        let weekStart = calendar.date(from: weekComponents)!

        // Monday entry: 2 hours (7200s)
        let monStart = calendar.date(byAdding: .hour, value: 9, to: weekStart)!
        let monEntry = TimeEntry(
            entryDescription: "Monday task",
            startDate: monStart,
            endDate: monStart.addingTimeInterval(7200),
            accumulatedDuration: 0
        )
        store.saveTimeEntry(monEntry)

        // Tuesday entry: 4 hours (14400s)
        let tueDay = calendar.date(byAdding: .day, value: 1, to: weekStart)!
        let tueStart = calendar.date(byAdding: .hour, value: 10, to: tueDay)!
        let tueEntry = TimeEntry(
            entryDescription: "Tuesday task",
            startDate: tueStart,
            endDate: tueStart.addingTimeInterval(14400),
            accumulatedDuration: 0
        )
        store.saveTimeEntry(tueEntry)

        // Compute daily totals
        let monDayEnd = calendar.date(byAdding: .day, value: 1, to: weekStart)!
        let monTotal = store.timeEntries
            .filter { $0.startDate >= weekStart && $0.startDate < monDayEnd && $0.endDate != nil }
            .reduce(0.0) { $0 + $1.effectiveDuration }

        let tueDayEnd = calendar.date(byAdding: .day, value: 2, to: weekStart)!
        let tueTotal = store.timeEntries
            .filter { $0.startDate >= tueDay && $0.startDate < tueDayEnd && $0.endDate != nil }
            .reduce(0.0) { $0 + $1.effectiveDuration }

        #expect(monTotal == 7200)
        #expect(tueTotal == 14400)
        #expect(DateHelper.formatHumanDuration(monTotal) == "2h")
        #expect(DateHelper.formatHumanDuration(tueTotal) == "4h")
    }

    @Test("Empty day or week produces zero layouts and zero duration without error")
    func testEmptyDayHandling() throws {
        let store = PersistenceStore(inMemory: true)
        let emptyDay = Date()

        let blocks = CalendarLayoutHelper.computeBlockLayouts(entries: store.timeEntries, for: emptyDay)
        #expect(blocks.isEmpty)

        let total = store.timeEntries.reduce(0.0) { $0 + $1.effectiveDuration }
        #expect(total == 0)
    }
}
