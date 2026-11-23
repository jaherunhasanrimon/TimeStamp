# Phase 5: macOS Menu Bar Companion & Global Hotkeys - Technical Research

**Target Platform:** macOS 14.0+ (Apple Silicon)
**Research Date:** 2026-11-23
**Status:** Complete

---

## 1. Executive Summary

Phase 5 introduces persistent system-level interactions: a macOS `MenuBarExtra` companion with a live zero-jitter ticker, an interactive `.window` popover for quick time tracking, and a system-wide global hotkey (`⌥⇧T`) that toggles the active timer from any application.

All components can be implemented using native Swift and Apple APIs without third-party dependencies:
- **`MenuBarExtra`**: Native SwiftUI in `TimeStampApp` configured with `.menuBarExtraStyle(.window)`.
- **Status Item & Ticker**: Reactive SwiftUI label updating with `TimerManager.formattedDuration` and `monospacedDigit()`.
- **Global Hotkey**: Carbon Event Manager (`RegisterEventHotKey` + `InstallEventHandler`) via `import Carbon`, which works reliably across all applications on Apple Silicon macOS 14+ without requiring Accessibility (`AXIsProcessTrusted`) permissions or specialized entitlements.

---

## 2. MenuBarExtra in SwiftUI macOS 14+

### 2.1 Declaration and Sizing
In SwiftUI on macOS 14+, `MenuBarExtra` is declared directly inside the `App.body` alongside the main `WindowGroup`:

```swift
@main
struct TimeStampApp: App {
    @State private var store = PersistenceStore.shared
    @State private var timerManager = TimerManager.shared
    @State private var selectedDestination: SidebarDestination? = .timer

    var body: some Scene {
        WindowGroup("TimeStamp", id: "main") {
            ...
        }

        MenuBarExtra {
            MenuBarPopoverView()
                .environment(store)
                .environment(timerManager)
        } label: {
            MenuBarLabelView()
                .environment(timerManager)
        }
        .menuBarExtraStyle(.window)
    }
}
```

### 2.2 Status Bar Label & Zero-Jitter Rendering (`D-01`, `D-02`, `D-03`, `D-04`)
To prevent visual jitter (where icons and text bounce horizontally as digits change width):
1. **Font Monospacing**: The duration ticker string must use `Font.system(..., design: .default).monospacedDigit()`.
2. **Fixed Format**: Formatted as strict `HH:MM:SS` (e.g. `00:24:15`) so character count remains constant.
3. **State Switching**:
   - **Idle (`D-01`)**: `Image(systemName: "stopwatch")`
   - **Running (`D-02`)**: `HStack(spacing: 4) { Image(systemName: "stopwatch"); Text(timerManager.formattedDuration).monospacedDigit() }`
   - **Paused (`D-03`)**: `HStack(spacing: 4) { Image(systemName: "pause.fill").foregroundStyle(.orange); Text(timerManager.formattedDuration).monospacedDigit().foregroundStyle(.secondary) }`

### 2.3 Popover Window UX (`D-05`, `D-06`)
- Sized at fixed ~320px width, padding 16px, background matching macOS control surface (`AppColors.background`).
- Hosts:
  - Header with app icon, name, and live ticker.
  - Interactive description text field bound to draft entry description.
  - Project/task selector button (`ProjectTaskPickerButton`).
  - Timer controls: Play/Stop button, Pause/Resume button, and Discard button.
  - Footer actions: "Open TimeStamp" and "Quit TimeStamp".
- When "Open TimeStamp" is pressed:
  ```swift
  NSApplication.shared.activate(ignoringOtherApps: true)
  if let window = NSApplication.shared.windows.first(where: { $0.title == "TimeStamp" || $0.canBecomeMain }) {
      window.makeKeyAndOrderFront(nil)
  }
  ```

---

## 3. Global System Hotkeys: Carbon vs NSEvent

### 3.1 Architecture Evaluation

| API / Approach | Permissions Required | Background Interception | Apple Silicon / CLT Compatible | Recommended |
|----------------|----------------------|-------------------------|--------------------------------|-------------|
| `NSEvent.addGlobalMonitorForEvents` | **Requires Accessibility (AX)** | Passive observation only | Yes | No (requires system privacy approval) |
| Sindre Sorhus `KeyboardShortcuts` | None (uses Carbon) | Yes | Requires adding SPM package | Optional fallback |
| **Carbon Event Manager (`RegisterEventHotKey`)** | **None** | **Full global intercept** | **Yes (`import Carbon`)** | **Yes (Zero-dep native)** |

### 3.2 Carbon Hotkey Implementation
Carbon Event Manager is available via `import Carbon` in modern Swift:

```swift
import Foundation
import Carbon

public final class GlobalHotkeyManager {
    public static let shared = GlobalHotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var onTrigger: (() -> Void)?

    private init() {}

    public func register(keyCode: UInt32 = 17, modifiers: UInt32 = UInt32(optionKey | shiftKey), onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handleHotKey()
            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, selfPtr, &eventHandlerRef)

        var hotKeyID = EventHotKeyID(signature: OSType(0x544D5350), id: 1) // 'TMSP'
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
    }

    private func handleHotKey() {
        DispatchQueue.main.async { [weak self] in
            self?.onTrigger?()
        }
    }

    public func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
}
```

Key Details:
- Key code for `T` is `17` (`kVK_ANSI_T`).
- Modifiers: `optionKey | shiftKey` (`⌥⇧T`).
- Signature: `0x544D5350` (`'TMSP'`).
- Dispatches cleanly to `MainActor` / `TimerManager.shared`.

---

## 4. Timer Toggle Logic (`D-07`)

When the global hotkey is pressed:
```swift
@MainActor
func handleGlobalHotkeyToggle() {
    if timerManager.isRunning {
        _ = timerManager.stop()
    } else {
        timerManager.start(
            description: "",
            projectId: timerManager.retainedProjectId,
            taskId: timerManager.retainedTaskId
        )
    }
}
```

---

## 5. Validation Architecture

### Automated Testing
1. **`GlobalHotkeyTests`**:
   - Verifies registration and unregistration lifecycle.
   - Verifies callback invocation triggers `TimerManager` start/stop.
   - Verifies retained project/task persistence across toggles.
2. **`MenuBarStatusTests`**:
   - Verifies label state machine (idle -> running -> paused -> idle).
   - Verifies duration string monospacing and formatting.
   - Verifies quick-entry popover actions (start, pause, resume, stop, discard).

---

## 6. Implementation Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Menu bar icon width bouncing | Distracting visual jitter on screen | Strictly enforce `HH:MM:SS` format with `monospacedDigit()` |
| Hotkey conflict with other apps | Hotkey fails to fire or intercepts unintended keystroke | Use `Option+Shift+T` (`⌥⇧T`), which is rarely bound by macOS system or standard editors |
| App AppNap / Background throttling | Timer ticks slow down when app window is closed | `TimerManager` already uses wall-clock date subtraction (`Date().timeIntervalSince(startDate)`) — immune to AppNap |
