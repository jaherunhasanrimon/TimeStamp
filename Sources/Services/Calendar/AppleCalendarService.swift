import Foundation
import AppKit
import Observation
import EventKit

public struct ExternalCalendarEvent: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let calendarTitle: String
    public let colorHex: String

    public init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        calendarTitle: String,
        colorHex: String
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendarTitle = calendarTitle
        self.colorHex = colorHex
    }
}

/// Privacy-first read-only Apple Calendar overlay using native EventKit.
/// Note: External cloud calendars (Google / Outlook) require explicit OAuth credentials
/// and are not bundled into offline local builds; users can subscribe via macOS Calendar.
@Observable
@MainActor
public final class AppleCalendarService {
    public static let shared = AppleCalendarService()

    public private(set) var events: [ExternalCalendarEvent] = []
    public private(set) var authorizationStatusDescription: String = "Not requested"
    public private(set) var isAuthorized: Bool = false

    private let eventStore = EKEventStore()

    private var canQueryEventKitSafely: Bool {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return false }
        let hasFull = Bundle.main.object(forInfoDictionaryKey: "NSCalendarsFullAccessUsageDescription") != nil
        let hasLegacy = Bundle.main.object(forInfoDictionaryKey: "NSCalendarsUsageDescription") != nil
        return hasFull || hasLegacy
    }

    public init() {
        refreshAuthorizationStatus()
    }

    public func refreshAuthorizationStatus() {
        guard canQueryEventKitSafely else {
            isAuthorized = false
            authorizationStatusDescription = "Available inside TimeStamp.app"
            return
        }

        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .authorized:
            isAuthorized = true
            authorizationStatusDescription = "Authorized (Read-only)"
        case .writeOnly:
            isAuthorized = false
            authorizationStatusDescription = "Write-only access (read access required)"
        case .denied, .restricted:
            isAuthorized = false
            authorizationStatusDescription = "Denied in System Settings > Privacy & Security"
        case .notDetermined:
            isAuthorized = false
            authorizationStatusDescription = "Not connected yet"
        @unknown default:
            isAuthorized = false
            authorizationStatusDescription = "Unknown"
        }
    }

    public func requestAccessAndLoad(from startDate: Date, to endDate: Date) async {
        guard canQueryEventKitSafely else {
            refreshAuthorizationStatus()
            return
        }

        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            refreshAuthorizationStatus()
            if granted {
                loadEvents(from: startDate, to: endDate)
            }
        } catch {
            authorizationStatusDescription = "Calendar permission failed: \(error.localizedDescription)"
            isAuthorized = false
        }
    }

    public func loadEvents(from startDate: Date, to endDate: Date) {
        refreshAuthorizationStatus()
        guard isAuthorized else {
            events = []
            return
        }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        self.events = ekEvents.compactMap { ev -> ExternalCalendarEvent? in
            guard !ev.isAllDay else { return nil }
            let id = ev.eventIdentifier ?? UUID().uuidString
            let hex = Self.hexString(from: ev.calendar?.color)
            return ExternalCalendarEvent(
                id: id,
                title: ev.title ?? "Calendar Event",
                startDate: ev.startDate,
                endDate: ev.endDate,
                calendarTitle: ev.calendar?.title ?? "Calendar",
                colorHex: hex
            )
        }
    }

    public func events(on date: Date, calendar: Calendar = .current) -> [ExternalCalendarEvent] {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        return events.filter { $0.endDate > dayStart && $0.startDate < dayEnd }
    }

    private static func hexString(from nsColor: NSColor?) -> String {
        guard let color = nsColor?.usingColorSpace(.sRGB) else { return "#5C85D6" }
        let r = Int(round(color.redComponent * 255))
        let g = Int(round(color.greenComponent * 255))
        let b = Int(round(color.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
