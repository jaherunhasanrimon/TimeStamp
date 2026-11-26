import Foundation
import AppKit
import Observation
import ServiceManagement

/// Manages native macOS system integration: Dock Icon policy and Launch at Login (`SMAppService`).
@Observable
@MainActor
public final class SystemIntegrationManager {
    public static let shared = SystemIntegrationManager()

    public var showDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(showDockIcon, forKey: "showDockIcon")
            applyDockIconPolicy()
        }
    }

    public private(set) var launchAtLoginStatusText: String = "Disabled"
    public var launchAtLoginEnabled: Bool = false

    private var hasValidAppBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    public init() {
        let d = UserDefaults.standard
        if d.object(forKey: "showDockIcon") != nil {
            self.showDockIcon = d.bool(forKey: "showDockIcon")
        } else {
            self.showDockIcon = true
        }
        refreshLaunchAtLoginStatus()
    }

    public func applyDockIconPolicy() {
        guard hasValidAppBundle, let app = NSApp else { return }
        let policy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        app.setActivationPolicy(policy)
    }

    public func refreshLaunchAtLoginStatus() {
        guard hasValidAppBundle else {
            launchAtLoginEnabled = false
            launchAtLoginStatusText = "Available in TimeStamp.app"
            return
        }
        let status = SMAppService.mainApp.status
        switch status {
        case .enabled:
            launchAtLoginEnabled = true
            launchAtLoginStatusText = "Enabled"
        case .requiresApproval:
            launchAtLoginEnabled = true
            launchAtLoginStatusText = "Requires approval in System Settings > Login Items"
        case .notRegistered:
            launchAtLoginEnabled = false
            launchAtLoginStatusText = "Disabled"
        case .notFound:
            launchAtLoginEnabled = false
            launchAtLoginStatusText = "App bundle not registered"
        @unknown default:
            launchAtLoginEnabled = false
            launchAtLoginStatusText = "Unknown"
        }
    }

    public func setLaunchAtLogin(_ enabled: Bool) {
        guard hasValidAppBundle else {
            refreshLaunchAtLoginStatus()
            return
        }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginStatusText = error.localizedDescription
        }
        refreshLaunchAtLoginStatus()
    }
}
