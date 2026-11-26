import Foundation
import UserNotifications
import AppKit
import Observation

@Observable
@MainActor
public final class NotificationManager {
    public static let shared = NotificationManager()

    public private(set) var isAuthorized: Bool = false

    private var hasValidAppBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app" && Bundle.main.bundleIdentifier != nil
    }

    public init() {
        checkCurrentAuthorization()
    }

    public func checkCurrentAuthorization() {
        guard hasValidAppBundle else { return }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            _Concurrency.Task { @MainActor in
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }

    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        guard hasValidAppBundle else {
            completion?(false)
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            _Concurrency.Task { @MainActor in
                self.isAuthorized = granted
                if let error = error {
                    print("[NotificationManager] Authorization error: \(error.localizedDescription)")
                }
                completion?(granted)
            }
        }
    }

    public func sendNotification(
        title: String,
        subtitle: String? = nil,
        body: String,
        soundName: String? = nil,
        playSound: Bool = true
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let sub = subtitle {
            content.subtitle = sub
        }
        content.body = body
        content.sound = playSound ? .default : nil

        if hasValidAppBundle {
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil // Deliver immediately
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("[NotificationManager] Delivery error: \(error.localizedDescription)")
                }
            }
        }

        // Play system sound feedback if enabled & running inside app bundle
        #if os(macOS)
        let globalSoundAllowed = (UserDefaults.standard.object(forKey: "playTimerSounds") == nil || UserDefaults.standard.bool(forKey: "playTimerSounds"))
        if hasValidAppBundle && playSound && globalSoundAllowed {
            NSSound.beep()
        }
        #endif
    }
}
