import Foundation
import AppKit
import Observation

public struct ActivitySpan: Identifiable, Codable, Equatable {
    public let id: UUID
    public let appName: String
    public let bundleIdentifier: String
    public let startDate: Date
    public var endDate: Date

    public var duration: TimeInterval {
        max(0, endDate.timeIntervalSince(startDate))
    }

    public init(
        id: UUID = UUID(),
        appName: String,
        bundleIdentifier: String,
        startDate: Date,
        endDate: Date
    ) {
        self.id = id
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.startDate = startDate
        self.endDate = endDate
    }
}

public struct AutotrackerRule: Identifiable, Codable, Equatable {
    public let id: UUID
    public var keyword: String
    public var projectId: UUID?
    public var isBillable: Bool
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        keyword: String,
        projectId: UUID? = nil,
        isBillable: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.keyword = keyword
        self.projectId = projectId
        self.isBillable = isBillable
        self.isEnabled = isEnabled
    }
}

/// Privacy-first local frontmost-application Activity Recorder and Autotracker rule matcher.
/// - Strictly opt-in (`isEnabled` defaults to `false`).
/// - Captures ONLY active application name and duration > 10s (zero keystrokes, zero screenshots, zero clipboard).
/// - Supports custom bundle exclusions and 1-click deletion of all recorded activity history.
@Observable
@MainActor
public final class ActivityTrackerManager {
    public static let shared = ActivityTrackerManager(
        timerManager: TimerManager.shared,
        notificationManager: NotificationManager.shared,
        isInMemory: false
    )

    public var isEnabled: Bool {
        didSet {
            persistConfig()
            if !isInMemory {
                isEnabled ? startPolling() : stopPolling()
            }
        }
    }
    public var autoStartOnRuleMatch: Bool {
        didSet { persistConfig() }
    }
    public var minimumDurationSeconds: TimeInterval = 10.0
    public var retentionDays: Int {
        didSet { persistConfig() }
    }
    public var excludedBundleIds: [String] {
        didSet { persistConfig() }
    }

    public private(set) var spans: [ActivitySpan] = []
    public private(set) var rules: [AutotrackerRule] = []
    public private(set) var lastSuggestedRule: AutotrackerRule? = nil

    private var currentAppName: String? = nil
    private var currentBundleId: String? = nil
    private var currentSpanStart: Date? = nil
    private var pollTimer: Timer?

    private let timerManager: TimerManager
    private let notificationManager: NotificationManager
    private let isInMemory: Bool
    private let storageURL: URL?

    public static let defaultExcludedBundleIds: [String] = [
        "com.apple.keychainaccess",
        "com.1password.1password",
        "com.apple.systempreferences"
    ]

    public init(
        timerManager: TimerManager,
        notificationManager: NotificationManager? = nil,
        isInMemory: Bool = false,
        customStorageURL: URL? = nil
    ) {
        self.timerManager = timerManager
        self.notificationManager = notificationManager ?? NotificationManager.shared
        self.isInMemory = isInMemory

        if isInMemory || timerManager.isInMemoryStore {
            self.isEnabled = false
            self.autoStartOnRuleMatch = false
            self.retentionDays = 7
            self.excludedBundleIds = Self.defaultExcludedBundleIds
            self.storageURL = customStorageURL
        } else {
            let d = UserDefaults.standard
            self.isEnabled = d.bool(forKey: "activityTrackerEnabled")
            self.autoStartOnRuleMatch = d.bool(forKey: "autotrackerAutoStart")
            let days = d.integer(forKey: "activityRetentionDays")
            self.retentionDays = days > 0 ? days : 7
            if let savedExclusions = d.stringArray(forKey: "activityExcludedBundles") {
                self.excludedBundleIds = savedExclusions
            } else {
                self.excludedBundleIds = Self.defaultExcludedBundleIds
            }

            if let customStorageURL {
                self.storageURL = customStorageURL
            } else {
                let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                let dir = appSupport?.appendingPathComponent("TimeStamp", isDirectory: true)
                if let dir {
                    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                }
                self.storageURL = dir?.appendingPathComponent("activity_history.json")
            }

            loadPersistedActivity()
            if isEnabled {
                startPolling()
            }
        }
    }

    private struct StoragePayload: Codable {
        var spans: [ActivitySpan]
        var rules: [AutotrackerRule]
    }

    private func persistConfig() {
        guard !isInMemory && !timerManager.isInMemoryStore else { return }
        let d = UserDefaults.standard
        d.set(isEnabled, forKey: "activityTrackerEnabled")
        d.set(autoStartOnRuleMatch, forKey: "autotrackerAutoStart")
        d.set(retentionDays, forKey: "activityRetentionDays")
        d.set(excludedBundleIds, forKey: "activityExcludedBundles")
    }

    private func saveActivityData() {
        guard !isInMemory, let storageURL else { return }
        let payload = StoragePayload(spans: spans, rules: rules)
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(payload) {
            try? data.write(to: storageURL, options: .atomic)
        }
    }

    private func loadPersistedActivity() {
        guard let storageURL, let data = try? Data(contentsOf: storageURL) else { return }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        if let payload = try? dec.decode(StoragePayload.self, from: data) {
            self.spans = payload.spans
            self.rules = payload.rules
            pruneExpiredSpans()
        }
    }

    public func startPolling() {
        stopPolling()
        let timer = Timer(timeInterval: 5.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.captureFrontmostSample(now: Date())
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    public func stopPolling() {
        flushCurrentSpan(now: Date())
        pollTimer?.invalidate()
        pollTimer = nil
    }

    public func captureFrontmostSample(now: Date = Date()) {
        guard isEnabled else { return }
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let name = app.localizedName ?? "Application"
        let bundleId = app.bundleIdentifier ?? name
        recordFocusSample(appName: name, bundleIdentifier: bundleId, at: now)
    }

    /// Deterministic testable handler for frontmost-app sample transitions.
    public func recordFocusSample(appName: String, bundleIdentifier: String, at now: Date = Date()) {
        guard isEnabled else { return }
        if excludedBundleIds.contains(where: { $0.caseInsensitiveCompare(bundleIdentifier) == .orderedSame }) {
            flushCurrentSpan(now: now)
            return
        }

        if currentBundleId == bundleIdentifier, let _ = currentSpanStart {
            // Same app remains active; will finalize when app switches or flushes
            return
        }

        // Flush previous span if duration >= minimumDurationSeconds (default 10s)
        flushCurrentSpan(now: now)

        currentAppName = appName
        currentBundleId = bundleIdentifier
        currentSpanStart = now

        evaluateAutotrackerRules(appName: appName, bundleIdentifier: bundleIdentifier)
    }

    public func flushCurrentSpan(now: Date = Date()) {
        if let start = currentSpanStart, let name = currentAppName, let bid = currentBundleId {
            let duration = now.timeIntervalSince(start)
            if duration >= minimumDurationSeconds {
                let span = ActivitySpan(
                    appName: name,
                    bundleIdentifier: bid,
                    startDate: start,
                    endDate: now
                )
                spans.insert(span, at: 0)
                pruneExpiredSpans(referenceDate: now)
                saveActivityData()
            }
        }
        currentAppName = nil
        currentBundleId = nil
        currentSpanStart = nil
    }

    // MARK: - Autotracker Rules

    public func addRule(_ rule: AutotrackerRule) {
        rules.append(rule)
        saveActivityData()
    }

    public func deleteRule(id: UUID) {
        rules.removeAll { $0.id == id }
        saveActivityData()
    }

    public func matchingRule(appName: String, bundleIdentifier: String) -> AutotrackerRule? {
        let lowerApp = appName.lowercased()
        let lowerBundle = bundleIdentifier.lowercased()
        return rules.first { rule in
            guard rule.isEnabled else { return false }
            let kw = rule.keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !kw.isEmpty else { return false }
            return lowerApp.contains(kw) || lowerBundle.contains(kw)
        }
    }

    private func evaluateAutotrackerRules(appName: String, bundleIdentifier: String) {
        guard let rule = matchingRule(appName: appName, bundleIdentifier: bundleIdentifier) else { return }
        lastSuggestedRule = rule
        if autoStartOnRuleMatch && !timerManager.isRunning {
            timerManager.start(
                description: appName,
                projectId: rule.projectId,
                isBillable: rule.isBillable
            )
        } else if !timerManager.isRunning {
            notificationManager.sendNotification(
                title: "Autotracker Match: \(appName)",
                body: "Matched rule “\(rule.keyword)”. Open TimeStamp to start tracking."
            )
        }
    }

    public func addExclusion(bundleId: String) {
        let trimmed = bundleId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !excludedBundleIds.contains(trimmed) else { return }
        excludedBundleIds.append(trimmed)
    }

    public func removeExclusion(bundleId: String) {
        excludedBundleIds.removeAll { $0 == bundleId }
    }

    public func pruneExpiredSpans(referenceDate: Date = Date()) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -max(1, retentionDays), to: referenceDate) ?? referenceDate
        spans.removeAll { $0.endDate < cutoff }
    }

    /// Immediately deletes all recorded local activity timeline spans.
    public func deleteAllActivityData() {
        currentAppName = nil
        currentBundleId = nil
        currentSpanStart = nil
        spans.removeAll()
        lastSuggestedRule = nil
        saveActivityData()
    }
}
