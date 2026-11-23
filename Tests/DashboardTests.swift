import Testing
import Foundation
@testable import TimeStamp

@Suite("Dashboard Metrics & Productivity Tests")
@MainActor
struct DashboardTests {

    @Test("Today's duration calculation isolates today's entries")
    func testTodayDurationCalculation() throws {
        let store = PersistenceStore(inMemory: true)
        let calendar = Calendar.current
        let today = Date()
        let todayStart = calendar.startOfDay(for: today)

        // Entry 1: Today, 3600s
        let entryToday = TimeEntry(
            entryDescription: "Today coding",
            startDate: todayStart.addingTimeInterval(3600),
            endDate: todayStart.addingTimeInterval(7200),
            accumulatedDuration: 0
        )
        store.saveTimeEntry(entryToday)

        // Entry 2: Yesterday, 7200s
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        let entryYesterday = TimeEntry(
            entryDescription: "Yesterday coding",
            startDate: yesterdayStart.addingTimeInterval(3600),
            endDate: yesterdayStart.addingTimeInterval(10800),
            accumulatedDuration: 0
        )
        store.saveTimeEntry(entryYesterday)

        let todayEntries = store.timeEntries.filter { $0.startDate >= todayStart && $0.endDate != nil }
        let totalTodayDuration = todayEntries.reduce(0.0) { $0 + $1.effectiveDuration }

        #expect(todayEntries.count == 1)
        #expect(totalTodayDuration == 3600)
    }

    @Test("Daily progress ratio and percentage against customizable targets")
    func testDailyProgressCalculations() throws {
        let trackedDuration: TimeInterval = 4 * 3600 // 4 hours

        // Target: 8.0 hours
        let targetHours8 = 8.0
        let targetSeconds8 = targetHours8 * 3600.0
        let ratio8 = min(1.0, trackedDuration / targetSeconds8)
        let percent8 = Int(round((trackedDuration / targetSeconds8) * 100))

        #expect(ratio8 == 0.5)
        #expect(percent8 == 50)

        // Target: 4.0 hours
        let targetHours4 = 4.0
        let targetSeconds4 = targetHours4 * 3600.0
        let ratio4 = min(1.0, trackedDuration / targetSeconds4)
        let percent4 = Int(round((trackedDuration / targetSeconds4) * 100))

        #expect(ratio4 == 1.0)
        #expect(percent4 == 100)
    }

    @Test("Overtime calculation when tracked duration exceeds target")
    func testOvertimeCalculation() throws {
        let trackedDuration: TimeInterval = 9.5 * 3600 // 9h 30m
        let targetHours = 8.0
        let targetSeconds = targetHours * 3600.0

        let isGoalReached = trackedDuration >= targetSeconds
        let overtimeSeconds = max(0, trackedDuration - targetSeconds)

        #expect(isGoalReached == true)
        #expect(overtimeSeconds == 1.5 * 3600)
        #expect(DateHelper.formatHumanDuration(overtimeSeconds) == "1h 30m")
    }

    @Test("Weekly activity grouping maps entries across Monday through Sunday")
    func testWeeklyActivityGrouping() throws {
        let store = PersistenceStore(inMemory: true)
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday

        let now = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        let weekStart = calendar.date(from: components)!

        // Monday entry: 2 hours
        let monDate = weekStart.addingTimeInterval(3600)
        let monEntry = TimeEntry(
            entryDescription: "Monday standup",
            startDate: monDate,
            endDate: monDate.addingTimeInterval(7200),
            accumulatedDuration: 0
        )
        store.saveTimeEntry(monEntry)

        // Tuesday entry: 3 hours
        let tueDate = calendar.date(byAdding: .day, value: 1, to: weekStart)!.addingTimeInterval(3600)
        let tueEntry = TimeEntry(
            entryDescription: "Tuesday feature work",
            startDate: tueDate,
            endDate: tueDate.addingTimeInterval(10800),
            accumulatedDuration: 0
        )
        store.saveTimeEntry(tueEntry)

        // Verify week entries
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        let weekEntries = store.timeEntries.filter { $0.startDate >= weekStart && $0.startDate < weekEnd }
        let totalDuration = weekEntries.reduce(0.0) { $0 + $1.effectiveDuration }

        #expect(weekEntries.count == 2)
        #expect(totalDuration == 18000) // 5 hours total
    }

    @Test("Recent activity returns at most 5 entries sorted descending")
    func testRecentActivityOrdering() throws {
        let store = PersistenceStore(inMemory: true)
        let baseDate = Date()

        for i in 1...7 {
            let entry = TimeEntry(
                entryDescription: "Entry \(i)",
                startDate: baseDate.addingTimeInterval(TimeInterval(i * 100)),
                endDate: baseDate.addingTimeInterval(TimeInterval(i * 100 + 50)),
                accumulatedDuration: 50
            )
            store.saveTimeEntry(entry)
        }

        let recent = Array(
            store.timeEntries
                .filter { $0.endDate != nil }
                .sorted { $0.startDate > $1.startDate }
                .prefix(5)
        )

        #expect(recent.count == 5)
        #expect(recent.first?.entryDescription == "Entry 7")
        #expect(recent.last?.entryDescription == "Entry 3")
    }
}
