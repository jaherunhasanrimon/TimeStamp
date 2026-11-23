import Foundation
import Carbon

public final class GlobalHotkeyManager {
    public static let shared = GlobalHotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var onTrigger: (() -> Void)?
    public private(set) var isRegistered: Bool = false

    // Default: 'T' key (keyCode 17) and Option + Shift (⌥⇧T)
    public static let defaultKeyCode: UInt32 = 17
    public static let defaultModifiers: UInt32 = UInt32(optionKey | shiftKey)
    public static let signature: OSType = 0x544D5350 // 'TMSP'
    public static let hotKeyIDValue: UInt32 = 1

    private init() {}

    deinit {
        unregister()
    }

    /// Registers the system-wide global hotkey using Carbon Event Manager
    public func register(
        keyCode: UInt32 = defaultKeyCode,
        modifiers: UInt32 = defaultModifiers,
        onTrigger: @escaping () -> Void
    ) {
        unregister()

        self.onTrigger = onTrigger

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handleHotKeyEvent(event)
            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            return
        }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: Self.hotKeyIDValue)
        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if regStatus == noErr {
            self.isRegistered = true
        } else {
            unregister()
        }
    }

    /// Handles the hotkey trigger event and dispatches to the main queue
    private func handleHotKeyEvent(_ event: EventRef?) {
        DispatchQueue.main.async { [weak self] in
            self?.onTrigger?()
        }
    }

    /// Unregisters any currently registered hotkeys and removes the event handler
    public func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
        self.isRegistered = false
    }

    /// Connects the global hotkey to automatically toggle the TimerManager state
    @MainActor
    public func setupTimerToggle(timerManager: TimerManager) {
        register {
            MainActor.assumeIsolated {
                if timerManager.isRunning || timerManager.isPaused {
                    _ = timerManager.stop()
                } else {
                    timerManager.start(
                        description: "",
                        projectId: timerManager.retainedProjectId,
                        taskId: timerManager.retainedTaskId
                    )
                }
            }
        }
    }
}
