import Foundation
import Observation

@Observable
@MainActor
public final class PomodoroManager {
    public static let shared = PomodoroManager()

    public enum SessionType: String, Codable, CaseIterable, Identifiable {
        case work = "Focus Session"
        case shortBreak = "Short Break"
        case longBreak = "Long Break"

        public var id: String { rawValue }
    }

    // MARK: - State Properties
    public private(set) var sessionType: SessionType = .work
    public private(set) var isRunning: Bool = false
    public private(set) var isPaused: Bool = false
    public private(set) var completedWorkSessions: Int = 0

    // Configurable Durations (in seconds)
    public var workDuration: TimeInterval = 25 * 60 {
        didSet { if !isRunning { resetCountdown() }; persistConfig() }
    }
    public var shortBreakDuration: TimeInterval = 5 * 60 {
        didSet { if !isRunning { resetCountdown() }; persistConfig() }
    }
    public var longBreakDuration: TimeInterval = 15 * 60 {
        didSet { if !isRunning { resetCountdown() }; persistConfig() }
    }
    public var targetIntervalCount: Int = 4 {
        didSet { persistConfig() }
    }
    public var autoStartBreaks: Bool = false {
        didSet { persistConfig() }
    }
    public var autoStartFocus: Bool = false {
        didSet { persistConfig() }
    }
    public var countUpMode: Bool = false {
        didSet { persistConfig() }
    }
    public var notificationsEnabled: Bool = true {
        didSet { persistConfig() }
    }
    public var soundEnabled: Bool = true {
        didSet { persistConfig() }
    }

    // Stored Focus Intent ("I'm focusing on...")
    public var focusDescription: String = ""
    public var focusProjectId: UUID? = nil
    public var focusTaskId: UUID? = nil
    public var focusTagIds: [UUID] = []
    public var focusIsBillable: Bool = false

    public func updateFocusIntent(
        description: String,
        projectId: UUID?,
        taskId: UUID?,
        tagIds: [UUID],
        isBillable: Bool
    ) {
        self.focusDescription = description
        self.focusProjectId = projectId
        self.focusTaskId = taskId
        self.focusTagIds = tagIds
        self.focusIsBillable = isBillable
    }

    // Live Countdown / Count-up
    public private(set) var remainingSeconds: TimeInterval = 25 * 60
    public var elapsedSeconds: TimeInterval {
        max(0, currentSessionDuration - remainingSeconds)
    }
    public var formattedRemainingTime: String {
        let total = max(0, Int(remainingSeconds.rounded()))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
    public var formattedDisplayTime: String {
        let value = countUpMode ? elapsedSeconds : remainingSeconds
        let total = max(0, Int(value.rounded()))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    public var currentSessionDuration: TimeInterval {
        switch sessionType {
        case .work: return workDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        }
    }

    public var progressPercentage: Double {
        let total = max(1.0, currentSessionDuration)
        let elapsed = total - remainingSeconds
        return min(1.0, max(0.0, elapsed / total))
    }

    // Wall-clock & Persistence Tracking
    private var sessionStartTime: Date?
    private var accumulatedSeconds: TimeInterval = 0
    private var tickTimer: Timer?
    private var sleepMonitor: SleepWakeMonitor?

    private let timerManager: TimerManager
    private let notificationManager: NotificationManager
    private let isInMemory: Bool

    public init(
        timerManager: TimerManager? = nil,
        notificationManager: NotificationManager? = nil,
        inMemory: Bool? = nil
    ) {
        let resolvedTimer = timerManager ?? TimerManager.shared
        self.timerManager = resolvedTimer
        self.notificationManager = notificationManager ?? NotificationManager.shared
        self.isInMemory = inMemory ?? resolvedTimer.isInMemoryStore
        if !self.isInMemory {
            loadConfig()
            setupSleepMonitor()
            restoreState()
        } else {
            resetCountdown()
        }
    }

    private func setupSleepMonitor() {
        self.sleepMonitor = SleepWakeMonitor(
            onSleep: { [weak self] in
                self?.updateTick()
            },
            onWake: { [weak self] in
                self?.updateTick()
            }
        )
    }

    // MARK: - Core Controls

    /// Starts or resumes the current session
    public func start(
        description: String? = nil,
        projectId: UUID? = nil,
        taskId: UUID? = nil,
        tagIds: [UUID]? = nil,
        isBillable: Bool? = nil
    ) {
        if isPaused {
            resume()
            return
        }

        self.isRunning = true
        self.isPaused = false
        self.sessionStartTime = Date()
        self.accumulatedSeconds = 0

        if sessionType == .work {
            // Start or sync with active TimerManager work entry (TIMER INTEGRATION)
            if !timerManager.isRunning {
                let candidateDesc = (description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let fallbackIntent = focusDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                let resolvedDesc: String
                if !candidateDesc.isEmpty {
                    resolvedDesc = candidateDesc
                } else if !fallbackIntent.isEmpty {
                    resolvedDesc = fallbackIntent
                } else {
                    resolvedDesc = timerManager.activeEntry?.entryDescription ?? "Pomodoro Session"
                }

                timerManager.start(
                    description: resolvedDesc,
                    projectId: projectId ?? focusProjectId ?? timerManager.retainedProjectId,
                    taskId: taskId ?? focusTaskId ?? timerManager.retainedTaskId,
                    tagIds: tagIds ?? (focusTagIds.isEmpty ? timerManager.retainedTagIds : focusTagIds),
                    isBillable: isBillable ?? (focusProjectId != nil ? focusIsBillable : timerManager.retainedIsBillable)
                )
            }
        } else {
            // During breaks, ensure TimerManager is NOT tracking productive time
            if timerManager.isRunning {
                _ = timerManager.stop()
            }
        }

        startTickTimer()
        updateTick()
        persistState()
    }

    public func pause() {
        guard isRunning && !isPaused else { return }

        if let start = sessionStartTime {
            accumulatedSeconds += max(0, Date().timeIntervalSince(start))
        }
        self.sessionStartTime = nil
        self.isPaused = true

        stopTickTimer()
        updateTick()

        // If in work session, pause productive timer
        if sessionType == .work && timerManager.isRunning && !timerManager.isPaused {
            timerManager.pause()
        }

        persistState()
    }

    public func resume() {
        guard isRunning && isPaused else { return }

        self.sessionStartTime = Date()
        self.isPaused = false

        if sessionType == .work {
            if timerManager.isPaused {
                timerManager.resume()
            } else if !timerManager.isRunning {
                timerManager.start(description: "Pomodoro Session")
            }
        }

        startTickTimer()
        updateTick()
        persistState()
    }

    public func skip() {
        stopTickTimer()
        sessionStartTime = nil
        accumulatedSeconds = 0

        if sessionType == .work {
            // Complete work session early
            if timerManager.isRunning {
                _ = timerManager.stop()
            }
            completedWorkSessions += 1
            transitionToBreak()
        } else {
            // Skip break directly into next work session
            transitionToWork()
        }

        persistState()
    }

    public func reset() {
        stopTickTimer()
        self.isRunning = false
        self.isPaused = false
        self.sessionStartTime = nil
        self.accumulatedSeconds = 0
        self.sessionType = .work
        self.remainingSeconds = workDuration

        persistState()
    }

    public func resetCycle() {
        self.completedWorkSessions = 0
        reset()
    }

    // MARK: - State Transitions & Countdown Logic

    public func updateTick() {
        guard isRunning else {
            resetCountdown()
            return
        }

        let totalAllowed = currentSessionDuration
        let currentRunElapsed: TimeInterval = {
            guard !isPaused, let start = sessionStartTime else { return 0 }
            return max(0, Date().timeIntervalSince(start))
        }()

        let totalElapsed = accumulatedSeconds + currentRunElapsed
        let remaining = max(0, totalAllowed - totalElapsed)
        self.remainingSeconds = remaining

        // Check completion
        if remaining <= 0 {
            handleSessionCompleted()
        }
    }

    private func handleSessionCompleted() {
        stopTickTimer()
        sessionStartTime = nil
        accumulatedSeconds = 0

        if sessionType == .work {
            // Stop productive work entry
            if timerManager.isRunning {
                _ = timerManager.stop()
            }
            completedWorkSessions += 1

            let isLongBreak = (completedWorkSessions % targetIntervalCount == 0)
            let breakMinutes = Int((isLongBreak ? longBreakDuration : shortBreakDuration) / 60)

            if notificationsEnabled {
                notificationManager.sendNotification(
                    title: "Pomodoro Completed! 🍅",
                    subtitle: "Cycle: \(completedWorkSessions)/\(targetIntervalCount)",
                    body: "Great work! Time for a \(breakMinutes)-minute \(isLongBreak ? "long" : "short") break.",
                    playSound: soundEnabled
                )
            }

            transitionToBreak()
            if autoStartBreaks {
                start()
            }
        } else {
            if notificationsEnabled {
                notificationManager.sendNotification(
                    title: "Break Over! ⚡️",
                    body: "Ready to jump into your next focus session?",
                    playSound: soundEnabled
                )
            }

            transitionToWork()
            if autoStartFocus {
                start()
            }
        }

        persistState()
    }

    private func transitionToBreak() {
        let isLong = (completedWorkSessions % targetIntervalCount == 0)
        self.sessionType = isLong ? .longBreak : .shortBreak
        self.remainingSeconds = isLong ? longBreakDuration : shortBreakDuration
        self.isRunning = false
        self.isPaused = false
    }

    private func transitionToWork() {
        self.sessionType = .work
        self.remainingSeconds = workDuration
        self.isRunning = false
        self.isPaused = false
    }

    private func resetCountdown() {
        self.remainingSeconds = currentSessionDuration
    }

    // MARK: - RunLoop Tick Timer

    private func startTickTimer() {
        stopTickTimer()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateTick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.tickTimer = timer
    }

    private func stopTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    // MARK: - State & Config Persistence

    private func persistConfig() {
        guard !isInMemory else { return }
        UserDefaults.standard.set(workDuration, forKey: "pomo_work_duration")
        UserDefaults.standard.set(shortBreakDuration, forKey: "pomo_short_break_duration")
        UserDefaults.standard.set(longBreakDuration, forKey: "pomo_long_break_duration")
        UserDefaults.standard.set(targetIntervalCount, forKey: "pomo_target_interval_count")
        UserDefaults.standard.set(autoStartBreaks, forKey: "pomo_auto_start_breaks")
        UserDefaults.standard.set(autoStartFocus, forKey: "pomo_auto_start_focus")
        UserDefaults.standard.set(countUpMode, forKey: "pomo_count_up_mode")
        UserDefaults.standard.set(notificationsEnabled, forKey: "pomo_notifications_enabled")
        UserDefaults.standard.set(soundEnabled, forKey: "pomo_sound_enabled")
    }

    private func loadConfig() {
        guard !isInMemory else { return }
        let defaults = UserDefaults.standard
        let wd = defaults.double(forKey: "pomo_work_duration")
        if wd > 0 { self.workDuration = wd }

        let sbd = defaults.double(forKey: "pomo_short_break_duration")
        if sbd > 0 { self.shortBreakDuration = sbd }

        let lbd = defaults.double(forKey: "pomo_long_break_duration")
        if lbd > 0 { self.longBreakDuration = lbd }

        let tic = defaults.integer(forKey: "pomo_target_interval_count")
        if tic > 0 { self.targetIntervalCount = tic }

        self.autoStartBreaks = defaults.bool(forKey: "pomo_auto_start_breaks")
        self.autoStartFocus = defaults.bool(forKey: "pomo_auto_start_focus")
        self.countUpMode = defaults.bool(forKey: "pomo_count_up_mode")
        if defaults.object(forKey: "pomo_notifications_enabled") != nil {
            self.notificationsEnabled = defaults.bool(forKey: "pomo_notifications_enabled")
        }
        if defaults.object(forKey: "pomo_sound_enabled") != nil {
            self.soundEnabled = defaults.bool(forKey: "pomo_sound_enabled")
        }
    }

    private func persistState() {
        guard !isInMemory else { return }
        UserDefaults.standard.set(isRunning, forKey: "pomo_isRunning")
        UserDefaults.standard.set(isPaused, forKey: "pomo_isPaused")
        UserDefaults.standard.set(sessionType.rawValue, forKey: "pomo_sessionType")
        UserDefaults.standard.set(completedWorkSessions, forKey: "pomo_completedSessions")
        UserDefaults.standard.set(sessionStartTime?.timeIntervalSince1970 ?? 0, forKey: "pomo_sessionStartTime")
        UserDefaults.standard.set(accumulatedSeconds, forKey: "pomo_accumulatedSeconds")
    }

    private func restoreState() {
        guard !isInMemory else { return }
        self.isRunning = UserDefaults.standard.bool(forKey: "pomo_isRunning")
        self.isPaused = UserDefaults.standard.bool(forKey: "pomo_isPaused")
        self.completedWorkSessions = UserDefaults.standard.integer(forKey: "pomo_completedSessions")

        if let rawType = UserDefaults.standard.string(forKey: "pomo_sessionType"),
           let st = SessionType(rawValue: rawType) {
            self.sessionType = st
        }

        let startEpoch = UserDefaults.standard.double(forKey: "pomo_sessionStartTime")
        if startEpoch > 0 {
            self.sessionStartTime = Date(timeIntervalSince1970: startEpoch)
        }
        self.accumulatedSeconds = UserDefaults.standard.double(forKey: "pomo_accumulatedSeconds")

        if isRunning {
            updateTick()
            if !isPaused {
                startTickTimer()
            }
        } else {
            resetCountdown()
        }
    }
}
