import Testing
import Foundation
@testable import TimeStamp

@Suite("Calendar Layout & Overlap Clustering Tests")
@MainActor
struct CalendarLayoutTests {

    @Test("Minute offset calculation maps hour and minute to total minutes from midnight")
    func testMinuteOffsetCalculation() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // 08:30:00 -> 8 * 60 + 30 = 510 minutes
        let targetDate = calendar.date(byAdding: .minute, value: 510, to: today)!

        let entry = TimeEntry(
            entryDescription: "Morning Planning",
            startDate: targetDate,
            endDate: calendar.date(byAdding: .minute, value: 60, to: targetDate),
            accumulatedDuration: 0
        )

        let blocks = CalendarLayoutHelper.computeBlockLayouts(entries: [entry], for: today, calendar: calendar)

        #expect(blocks.count == 1)
        #expect(blocks[0].startMinutes == 510.0)
        #expect(blocks[0].durationMinutes == 60.0)
    }

    @Test("Duration scaling correctly calculates duration in minutes")
    func testDurationScaling() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .hour, value: 14, to: today)! // 14:00 (840 min)
        let end = calendar.date(byAdding: .minute, value: 90, to: start)! // 15:30 (930 min)

        let entry = TimeEntry(
            entryDescription: "Design sprint",
            startDate: start,
            endDate: end,
            accumulatedDuration: 0
        )

        let blocks = CalendarLayoutHelper.computeBlockLayouts(entries: [entry], for: today, calendar: calendar)

        #expect(blocks.count == 1)
        #expect(blocks[0].durationMinutes == 90.0)
    }

    @Test("Non-overlapping entries are assigned single sub-column")
    func testNonOverlappingEntries() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Entry 1: 09:00 - 10:00
        let start1 = calendar.date(byAdding: .hour, value: 9, to: today)!
        let end1 = calendar.date(byAdding: .hour, value: 10, to: today)!
        let entry1 = TimeEntry(
            entryDescription: "Entry 1",
            startDate: start1,
            endDate: end1,
            accumulatedDuration: 0
        )

        // Entry 2: 11:00 - 12:00
        let start2 = calendar.date(byAdding: .hour, value: 11, to: today)!
        let end2 = calendar.date(byAdding: .hour, value: 12, to: today)!
        let entry2 = TimeEntry(
            entryDescription: "Entry 2",
            startDate: start2,
            endDate: end2,
            accumulatedDuration: 0
        )

        let blocks = CalendarLayoutHelper.computeBlockLayouts(entries: [entry1, entry2], for: today, calendar: calendar)

        #expect(blocks.count == 2)
        #expect(blocks[0].subColumnIndex == 0)
        #expect(blocks[0].totalSubColumns == 1)
        #expect(blocks[1].subColumnIndex == 0)
        #expect(blocks[1].totalSubColumns == 1)
    }

    @Test("Overlapping entries are partitioned into distinct side-by-side sub-columns")
    func testOverlappingEntriesClustering() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Entry A: 10:00 - 11:30 (600 to 690)
        let startA = calendar.date(byAdding: .minute, value: 600, to: today)!
        let endA = calendar.date(byAdding: .minute, value: 690, to: today)!
        let entryA = TimeEntry(
            entryDescription: "Meeting A",
            startDate: startA,
            endDate: endA,
            accumulatedDuration: 0
        )

        // Entry B: 10:30 - 12:00 (630 to 720) - overlaps with A
        let startB = calendar.date(byAdding: .minute, value: 630, to: today)!
        let endB = calendar.date(byAdding: .minute, value: 720, to: today)!
        let entryB = TimeEntry(
            entryDescription: "Meeting B",
            startDate: startB,
            endDate: endB,
            accumulatedDuration: 0
        )

        let blocks = CalendarLayoutHelper.computeBlockLayouts(entries: [entryA, entryB], for: today, calendar: calendar)

        #expect(blocks.count == 2)
        #expect(blocks[0].totalSubColumns == 2)
        #expect(blocks[1].totalSubColumns == 2)
        #expect(blocks[0].subColumnIndex != blocks[1].subColumnIndex)
    }

    @Test("Boundary clamping keeps entries strictly within 00:00 to 24:00 (0.0 to 1440.0)")
    func testBoundaryClamping() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Entry starting yesterday at 23:00 and ending today at 02:00
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: today)!
        let start = calendar.date(byAdding: .hour, value: 23, to: yesterdayStart)!
        let end = calendar.date(byAdding: .hour, value: 2, to: today)!

        let entry = TimeEntry(
            entryDescription: "Late night work",
            startDate: start,
            endDate: end,
            accumulatedDuration: 0
        )

        let blocks = CalendarLayoutHelper.computeBlockLayouts(entries: [entry], for: today, calendar: calendar)

        #expect(blocks.count == 1)
        #expect(blocks[0].startMinutes == 0.0) // Clamped to midnight start of today
        #expect(blocks[0].durationMinutes == 120.0) // 2 hours into today
    }
}
