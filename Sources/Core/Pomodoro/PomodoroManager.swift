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

    // Live Countdown
    public private(set) var remainingSeconds: TimeInterval = 25 * 60
    public var formattedRemainingTime: String {
        let total = max(0, Int(remainingSeconds.rounded()))
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

    public init(
        timerManager: TimerManager? = nil,
        notificationManager: NotificationManager? = nil
    ) {
        self.timerManager = timerManager ?? TimerManager.shared
        self.notificationManager = notificationManager ?? NotificationManager.shared
        loadConfig()
        setupSleepMonitor()
        restoreState()
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
        taskId: UUID? = nil
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
                timerManager.start(
                    description: description ?? (timerManager.activeEntry?.entryDescription ?? "Pomodoro Session"),
                    projectId: projectId ?? timerManager.retainedProjectId,
                    taskId: taskId ?? timerManager.retainedTaskId
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

            notificationManager.sendNotification(
                title: "Pomodoro Completed! 🍅",
                subtitle: "Cycle: \(completedWorkSessions)/\(targetIntervalCount)",
                body: "Great work! Time for a \(breakMinutes)-minute \(isLongBreak ? "long" : "short") break."
            )

            transitionToBreak()
        } else {
            notificationManager.sendNotification(
                title: "Break Over! ⚡️",
                body: "Ready to jump into your next focus session?"
            )

            transitionToWork()
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
        UserDefaults.standard.set(workDuration, forKey: "pomo_work_duration")
        UserDefaults.standard.set(shortBreakDuration, forKey: "pomo_short_break_duration")
        UserDefaults.standard.set(longBreakDuration, forKey: "pomo_long_break_duration")
        UserDefaults.standard.set(targetIntervalCount, forKey: "pomo_target_interval_count")
    }

    private func loadConfig() {
        let wd = UserDefaults.standard.double(forKey: "pomo_work_duration")
        if wd > 0 { self.workDuration = wd }

        let sbd = UserDefaults.standard.double(forKey: "pomo_short_break_duration")
        if sbd > 0 { self.shortBreakDuration = sbd }

        let lbd = UserDefaults.standard.double(forKey: "pomo_long_break_duration")
        if lbd > 0 { self.longBreakDuration = lbd }

        let tic = UserDefaults.standard.integer(forKey: "pomo_target_interval_count")
        if tic > 0 { self.targetIntervalCount = tic }
    }

    private func persistState() {
        UserDefaults.standard.set(isRunning, forKey: "pomo_isRunning")
        UserDefaults.standard.set(isPaused, forKey: "pomo_isPaused")
        UserDefaults.standard.set(sessionType.rawValue, forKey: "pomo_sessionType")
        UserDefaults.standard.set(completedWorkSessions, forKey: "pomo_completedSessions")
        UserDefaults.standard.set(sessionStartTime?.timeIntervalSince1970 ?? 0, forKey: "pomo_sessionStartTime")
        UserDefaults.standard.set(accumulatedSeconds, forKey: "pomo_accumulatedSeconds")
    }

    private func restoreState() {
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
