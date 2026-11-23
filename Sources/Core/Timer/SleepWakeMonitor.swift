import Foundation
#if canImport(AppKit)
import AppKit
#endif

public final class SleepWakeMonitor: @unchecked Sendable {
    private var sleepObserver: (any NSObjectProtocol)?
    private var wakeObserver: (any NSObjectProtocol)?

    public var onSleep: (@MainActor () -> Void)?
    public var onWake: (@MainActor () -> Void)?

    public init(onSleep: (@MainActor () -> Void)? = nil, onWake: (@MainActor () -> Void)? = nil) {
        self.onSleep = onSleep
        self.onWake = onWake
        setupObservers()
    }

    private func setupObservers() {
        #if canImport(AppKit)
        let notificationCenter = NSWorkspace.shared.notificationCenter

        sleepObserver = notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.onSleep?()
            }
        }

        wakeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.onWake?()
            }
        }
        #endif
    }

    public func invalidate() {
        #if canImport(AppKit)
        if let sleepObserver = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver)
            self.sleepObserver = nil
        }
        if let wakeObserver = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
            self.wakeObserver = nil
        }
        #endif
    }

    deinit {
        invalidate()
    }
}
