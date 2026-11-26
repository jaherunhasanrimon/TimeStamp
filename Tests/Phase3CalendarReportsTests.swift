import Testing
@testable import TimeStamp
import Foundation

@Suite("Phase 3: Interactive Calendar & Multi-View Reports Tests")
@MainActor
struct Phase3CalendarReportsTests {

    @Test("CalendarLayoutHelper snaps clicked Y position, moved blocks, and resized edges accurately")
    func calendarSnappingMoveAndResize() {
        let cal = Calendar.current
        let day = cal.startOfDay(for: Date())
        let hourHeight: CGFloat = 60.0 // 1 pt == 1 min

        // Click at 9:18 (558 pt) with 15m snap -> 9:15 (555 min)
        let snapped = CalendarLayoutHelper.snappedStartDate(
            atY: 558,
            hourHeight: hourHeight,
            dayDate: day,
            snapMinutes: 15,
            calendar: cal
        )
        #expect(abs(snapped.timeIntervalSince(day) - 555 * 60) < 0.01)

        // Move block down by +32 pts (snaps to +30 min), preserving 60m duration
        let origStart = day.addingTimeInterval(9 * 3600)
        let origEnd = day.addingTimeInterval(10 * 3600)
        let moved = CalendarLayoutHelper.movedDates(
            originalStart: origStart,
            originalEnd: origEnd,
            deltaY: 32,
            hourHeight: hourHeight,
            snapMinutes: 15
        )
        #expect(abs(moved.start.timeIntervalSince(day) - (9 * 3600 + 1800)) < 0.01)
        #expect(abs(moved.end.timeIntervalSince(moved.start) - 3600) < 0.01)

        // Resize top downward past minimum clamp -> clamps to minimum 5m duration (300s)
        let clampedTop = CalendarLayoutHelper.resizedDates(
            originalStart: origStart,
            originalEnd: origEnd,
            edge: .top,
            deltaY: 120,
            hourHeight: hourHeight,
            snapMinutes: 15,
            minDurationSeconds: 300
        )
        #expect(abs(clampedTop.end.timeIntervalSince(clampedTop.start) - 300) < 0.01)

        // Resize bottom +44 pts (snaps to +45 min) -> 1h45m total
        let extendedBottom = CalendarLayoutHelper.resizedDates(
            originalStart: origStart,
            originalEnd: origEnd,
            edge: .bottom,
            deltaY: 44,
            hourHeight: hourHeight,
            snapMinutes: 15
        )
        #expect(abs(extendedBottom.end.timeIntervalSince(extendedBottom.start) - 6300) < 0.01)
    }

    @Test("DateHelper.startOfWeek consistently resolves Monday 00:00 across week")
    func dateHelperStartOfWeek() {
        let cal = DateHelper.isoCalendar
        var comps = DateComponents(year: 2026, month: 11, day: 25, hour: 15) // Wednesday
        let wed = cal.date(from: comps)!
        let mon = DateHelper.startOfWeek(for: wed, in: cal)
        #expect(cal.component(.day, from: mon) == 23)
        #expect(cal.component(.weekday, from: mon) == 2)

        comps.day = 29 // Sunday
        let sun = cal.date(from: comps)!
        let monFromSun = DateHelper.startOfWeek(for: sun, in: cal)
        #expect(cal.component(.day, from: monFromSun) == 23)
    }

    @Test("Extended CSV, JSON, and PDF exports include billable amounts, tags, and valid PDF bytes")
    func extendedCSVJSONAndPDFExports() throws {
        let client = Client(name: "Globex", hourlyRate: 100.0, currency: "€")
        let project = Project(name: "Core SDK", colorHex: "#36B37E", hourlyRate: 120.0, clientId: client.id)
        let tagA = Tag(name: "backend")
        let tagB = Tag(name: "urgent")

        let start = Date(timeIntervalSince1970: 1700000000)
        let entry = TimeEntry(
            entryDescription: "Optimize queries",
            startDate: start,
            endDate: start.addingTimeInterval(5400), // 1.5h -> 1.5 * 120 = 180.00
            accumulatedDuration: 5400,
            projectId: project.id,
            tagIds: [tagA.id, tagB.id],
            isBillable: true
        )

        let csv = ExportService.generateCSV(
            entries: [entry],
            projects: [project],
            clients: [client],
            tasks: [],
            tags: [tagA, tagB],
            defaultHourlyRate: 50.0,
            includeExtendedColumns: true
        )
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count == 2)
        #expect(lines[0].hasSuffix(",Tags,Billable,Rate,Amount"))
        #expect(lines[1].contains("backend; urgent"))
        #expect(lines[1].contains(",Yes,120.00,180.00"))

        let jsonData = ExportService.generateJSON(
            entries: [entry],
            projects: [project],
            clients: [client],
            tasks: [],
            tags: [tagA, tagB],
            defaultHourlyRate: 50.0
        )
        let decoded = try JSONDecoder().decode([ExportItem].self, from: jsonData)
        #expect(decoded.count == 1)
        #expect(decoded[0].tags == ["backend", "urgent"])
        #expect(decoded[0].isBillable == true)
        #expect(decoded[0].billableRate == 120.0)
        #expect(decoded[0].billableAmount == 180.0)

        let pdfData = ExportService.generatePDF(
            title: "TimeStamp Report",
            periodLabel: "Nov 2026",
            entries: [entry],
            projects: [project],
            clients: [client],
            tasks: [],
            defaultHourlyRate: 50.0
        )
        #expect(pdfData.count > 200)
        let pdfHeader = String(data: pdfData.prefix(6), encoding: .ascii) ?? ""
        #expect(pdfHeader.hasPrefix("%PDF-1"))
    }
}
