import Foundation
import Observation

/// Schedules configurable workday tracking reminders via native macOS notifications.
@Observable
@MainActor
public final class ReminderManager {
    public static let shared = ReminderManager(
        timerManager: TimerManager.shared,
        notificationManager: NotificationManager.shared,
        isInMemory: false
    )

    public var isEnabled: Bool {
        didSet { persistConfig() }
    }
    public var reminderHour: Int {
        didSet { persistConfig() }
    }
    public var reminderMinute: Int {
        didSet { persistConfig() }
    }
    /// Calendar weekday integers (1 = Sun ... 7 = Sat); defaults to Mon-Fri [2,3,4,5,6].
    public var enabledWeekdays: Set<Int> {
        didSet { persistConfig() }
    }
    public var onlyWhenTimerIdle: Bool {
        didSet { persistConfig() }
    }

    public private(set) var lastTriggeredDayKey: String? = nil

    private let timerManager: TimerManager
    private let notificationManager: NotificationManager
    private let isInMemory: Bool
    private var checkTimer: Timer?

    public init(
        timerManager: TimerManager,
        notificationManager: NotificationManager? = nil,
        isInMemory: Bool = false
    ) {
        self.timerManager = timerManager
        self.notificationManager = notificationManager ?? NotificationManager.shared
        self.isInMemory = isInMemory

        if isInMemory || timerManager.isInMemoryStore {
            self.isEnabled = false
            self.reminderHour = 9
            self.reminderMinute = 30
            self.enabledWeekdays = [2, 3, 4, 5, 6]
            self.onlyWhenTimerIdle = true
        } else {
            let d = UserDefaults.standard
            self.isEnabled = d.bool(forKey: "reminderEnabled")
            self.reminderHour = d.object(forKey: "reminderHour") != nil ? d.integer(forKey: "reminderHour") : 9
            self.reminderMinute = d.object(forKey: "reminderMinute") != nil ? d.integer(forKey: "reminderMinute") : 30
            if let rawDays = d.array(forKey: "reminderWeekdays") as? [Int], !rawDays.isEmpty {
                self.enabledWeekdays = Set(rawDays)
            } else {
                self.enabledWeekdays = [2, 3, 4, 5, 6]
            }
            self.onlyWhenTimerIdle = d.object(forKey: "reminderOnlyWhenIdle") != nil ? d.bool(forKey: "reminderOnlyWhenIdle") : true
            startChecking()
        }
    }

    private func persistConfig() {
        guard !isInMemory && !timerManager.isInMemoryStore else { return }
        let d = UserDefaults.standard
        d.set(isEnabled, forKey: "reminderEnabled")
        d.set(reminderHour, forKey: "reminderHour")
        d.set(reminderMinute, forKey: "reminderMinute")
        d.set(Array(enabledWeekdays).sorted(), forKey: "reminderWeekdays")
        d.set(onlyWhenTimerIdle, forKey: "reminderOnlyWhenIdle")
    }

    public func startChecking() {
        checkTimer?.invalidate()
        let t = Timer(timeInterval: 30.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                _ = self?.evaluateAndNotifyIfNeeded(at: Date())
            }
        }
        RunLoop.main.add(t, forMode: .common)
        checkTimer = t
    }

    public func shouldTriggerReminder(
        at date: Date,
        isTimerRunning: Bool,
        calendar: Calendar = .current
    ) -> Bool {
        guard isEnabled else { return false }
        if onlyWhenTimerIdle && isTimerRunning {
            return false
        }
        let weekday = calendar.component(.weekday, from: date)
        guard enabledWeekdays.contains(weekday) else { return false }

        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let h = comps.hour, let m = comps.minute else { return false }
        guard h == reminderHour && abs(m - reminderMinute) <= 1 else { return false }

        let dayKey = "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
        guard dayKey != lastTriggeredDayKey else { return false }
        return true
    }

    @discardableResult
    public func evaluateAndNotifyIfNeeded(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard shouldTriggerReminder(at: date, isTimerRunning: timerManager.isRunning, calendar: calendar) else {
            return false
        }
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        lastTriggeredDayKey = "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
        notificationManager.sendNotification(
            title: "Reminder to Track Time",
            body: "No active timer is running. Start tracking your current task in TimeStamp."
        )
        return true
    }
}
