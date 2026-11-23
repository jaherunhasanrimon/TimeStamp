# Phase 5: macOS Menu Bar Companion & Global Hotkeys - Context

**Gathered:** 2026-11-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 5 delivers the native macOS system menu bar companion and system-wide global hotkeys for frictionless background time tracking:
- MenuBarExtra live ticker and status item reflecting idle, running, and paused states (`SYS-01`).
- Interactive menu bar popover window (`.window` style) with quick timer controls, description field, and project/task selection (`SYS-02`).
- Global keyboard hotkey (`Option+Shift+T` / `⌥⇧T`) to start or stop tracking from any application without switching focus (`SYS-03`).
- Seamless synchronization between the MenuBarExtra companion, `TimerManager`, and the main app window.

Out of scope for Phase 5:
- Productivity charts and summary dashboards (Phase 6).
- Visual calendar timeline 24h block grid (Phase 7).
- Advanced user preferences sheet and hotkey customization recorder UI (Phase 8).
</domain>

<decisions>
## Implementation Decisions

### Menu Bar Status Item & Ticker Display
- **D-01 (Idle Status Item):** Clean monochrome stopwatch icon (`Image(systemName: "stopwatch")`) in the macOS status bar for an unobtrusive, native macOS appearance.
- **D-02 (Running Status Item):** Stopwatch icon followed by the live duration ticker (`[Icon] 00:24:15`) for immediate visibility into active session elapsed time directly in the menu bar.
- **D-03 (Paused Status Item):** Pause icon with paused duration (`[Pause Icon] 00:24:15` rendered with warning/secondary styling) to provide a distinct, glanceable visual indicator that tracking is suspended.
- **D-04 (Ticker Formatting & Jitter Prevention):** Fixed-width monospaced `HH:MM:SS` (e.g. `00:24:15`) formatted using `.monospacedDigit()` to completely prevent menu bar text width jumping and status bar item layout jitter.

### Menu Bar Popover Window Architecture & Content
- **D-05 (MenuBarExtra Presentation Style):** SwiftUI `MenuBarExtra` configured with `.window` style (~320px width) allowing interactive controls, text fields, and custom buttons impossible in traditional `.menu` dropdowns.
- **D-06 (Popup Quick-Timer Content):** Comprehensive quick companion interface:
  - Header with app brand, live duration ticker, and window close/open actions.
  - Quick-entry description text field ("What are you working on?").
  - Project and task selector pill (reusing or adapting `ProjectTaskPickerButton`).
  - Timer control buttons: Start/Stop toggle button, Pause/Resume button, and Discard button.
  - Footer actions: "Open TimeStamp" (brings main application window to front) and "Quit TimeStamp".

### Global System Hotkeys & Shortcuts
- **D-07 (Global Hotkey Action):** Instant Timer Toggle — Pressing the global hotkey when the timer is idle starts tracking immediately (pre-populating the last retained project and task). Pressing the hotkey when a timer is running immediately stops and saves the session.
- **D-08 (Default Hotkey Combination):** `Option+Shift+T` (`⌥⇧T`) as the default system-wide shortcut — ergonomic, memorable ("Timer"), and avoids collisions with popular developer and productivity software.

### the agent's Discretion
- Visual padding and micro-spacing within the 320px `MenuBarExtra` popover window.
- Hotkey monitoring implementation: using macOS Carbon `RegisterEventHotKey` or native event monitors suitable for command-line tool builds without sandbox conflicts.
- Graceful handling of window activation when "Open TimeStamp" is pressed from the menu bar popup.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing:**

### Domain Models & Persistence
- `Sources/Core/Timer/TimerManager.swift` — Single source of truth for timer state (`isRunning`, `isPaused`, `activeEntry`, `formattedDuration`, `start`, `pause`, `resume`, `stop`, `discard`).
- `Sources/Models/PersistenceStore.swift` — Reactive data store holding projects, tasks, and time entries.
- `Sources/App/TimeStampApp.swift` — App entry point hosting `WindowGroup` and where `MenuBarExtra` will be declared.

### Design System & Existing Views
- `Sources/DesignSystem/Colors.swift` — Semantic colors (`AppColors.brandAccent`, `AppColors.destructive`, `AppColors.projectColors`).
- `Sources/DesignSystem/Typography.swift` — Typography hierarchy and monospaced tickers (`AppTypography.ticker`).
- `Sources/Views/Timer/ProjectTaskPickerButton.swift` — Project and task dropdown picker component.
- `Sources/Views/Timer/ActiveTimerBar.swift` — Reference for timer control button layout and state handling.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TimerManager.shared`: Thread-safe, `@Observable` timer engine already providing `formattedDuration`, `start(...)`, `pause()`, `resume()`, `stop()`, and `discard()` methods.
- `ProjectTaskPickerButton`: Already implemented with project dots, client tags, and task sub-menus; can be placed inside the menu bar popup window.
- `DateHelper.formatHumanDuration`: Available for compact time summaries.

### Established Patterns
- `@Observable` macro bindings directly connected to `@Environment(TimerManager.self)` and `@Environment(PersistenceStore.self)`.
- Swift Testing (`import Testing`) with `@MainActor` test suites.
- Mac window management via standard `NSApplication.shared.activate(ignoringOtherApps: true)` to bring main window forward.
</code_context>
