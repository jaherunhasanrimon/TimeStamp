import Foundation
import UserNotifications
import AppKit
import Observation

@Observable
@MainActor
public final class NotificationManager {
    public static let shared = NotificationManager()

    public private(set) var isAuthorized: Bool = false

    public init() {
        checkCurrentAuthorization()
    }

    public func checkCurrentAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            _Concurrency.Task { @MainActor in
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }

    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
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
        soundName: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let sub = subtitle {
            content.subtitle = sub
        }
        content.body = body
        content.sound = .default

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

        // Play system sound feedback
        #if os(macOS)
        NSSound.beep()
        #endif
    }
}
