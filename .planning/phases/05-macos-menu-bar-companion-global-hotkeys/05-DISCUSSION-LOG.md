# Phase 5: macOS Menu Bar Companion & Global Hotkeys - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-23
**Phase:** 05-macos-menu-bar-companion-global-hotkeys
**Areas discussed:** Menu Bar Status Label & Ticker Display, Menu Bar Popup Style & Layout, Menu Bar Quick Controls & Interactions, Global Hotkey Defaults & Trigger Behavior

---

## Menu Bar Status Label & Ticker Display

| Option | Description | Selected |
|--------|-------------|----------|
| Clean monochrome stopwatch icon | Unobtrusive, native macOS status bar styling with SF Symbol 'stopwatch' | ✓ |
| Icon + App Name ('TimeStamp') | Highly visible, but consumes extra menu bar space | |
| Minimalist clock or dot icon | Subtle indicator with 'clock' or 'circle.fill' | |

**User's choice:** Clean monochrome stopwatch icon (SF Symbol 'stopwatch') for idle state.
**Notes:** Native look that blends seamlessly with other macOS menu bar extras.

---

## Running State Presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Stopwatch icon + live duration ticker | Immediate visibility into active session elapsed time ([Icon] 00:24:15) | ✓ |
| Icon + project color dot + live ticker | Displays current active project color alongside elapsed time | |
| Live duration ticker only without icon | Saves space on crowded menu bars | |

**User's choice:** Stopwatch icon + live duration ticker ([Icon] 00:24:15).
**Notes:** Provides glanceable feedback that a timer is actively running and tracking time.

---

## Paused State Indication

| Option | Description | Selected |
|--------|-------------|----------|
| Pause icon + paused duration | Distinct visual cue that timer is suspended ([Pause Icon] 00:24:15 in secondary/warning tone) | ✓ |
| Revert to idle icon only | Completely hides elapsed time while paused | |
| Blinking ticker | Flashing duration between visible and hidden | |

**User's choice:** Pause icon + paused duration ([Pause Icon] 00:24:15 in secondary/warning tone).
**Notes:** Prevents layout shifting while clearly communicating the suspended state.

---

## Ticker Jitter Prevention

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed-width monospaced HH:MM:SS with monospacedDigit() | Zero width jitter or bouncing every second | ✓ |
| Adaptive MM:SS / HH:MM:SS | Saves space, but width expands at 1 hour mark | |
| Compact human format ('24m', '1h 12m') | Extremely compact, but loses live second-ticker feedback | |

**User's choice:** Fixed-width monospaced HH:MM:SS (00:24:15) with monospacedDigit().
**Notes:** Eliminates visual distraction of shifting status bar icons.

---

## MenuBarExtra Presentation Style

| Option | Description | Selected |
|--------|-------------|----------|
| .window style (~320px width) | Rich interactive SwiftUI popover supporting text fields, project dropdown, start/pause/stop buttons | ✓ |
| Native .menu style | Standard macOS text menu with MenuItems, unable to host text inputs or rich pills | |
| Mini utility window (240px width) | Ultra-compact with only play/pause/stop and duration | |

**User's choice:** .window style (~320px width) rich interactive SwiftUI popover.
**Notes:** Allows full timer entry and project management directly from the menu bar without switching windows.

---

## Popup Content & Controls

| Option | Description | Selected |
|--------|-------------|----------|
| Quick-Timer Bar + Controls + 'Open Main Window' | Description input, project/task picker, start/pause/stop/discard, and 'Open TimeStamp' button | ✓ |
| Dashboard Companion | Active timer controls plus today's tracked total and recent 3 entries list | |
| Minimal Controls only | Start/Stop toggle, current task label, and 'Open Main Window' | |

**User's choice:** Quick-Timer Bar + Controls + 'Open Main Window'.
**Notes:** Balances quick-entry utility with clean ergonomics.

---

## Global Hotkey Action

| Option | Description | Selected |
|--------|-------------|----------|
| Toggle Timer | Starts timer (using last project/task) if idle, stops active timer if running | ✓ |
| Summon Menu Bar Popover | Opens/focuses the menu bar popup so user can enter description and choose project | |
| Toggle Timer with Audio Feedback | Starts/stops timer and plays subtle system sound (Tink/Pop) | |

**User's choice:** Toggle Timer (starts with last project/task if idle, stops if running).
**Notes:** Fastest possible friction-free time tracking trigger from any app.

---

## Default Global Hotkey

| Option | Description | Selected |
|--------|-------------|----------|
| Option+Shift+T (⌥⇧T) | Ergonomic, avoids conflicts with common apps like Slack, Safari, or IDEs | ✓ |
| Option+Command+T (⌥⌘T) | Common macOS developer shortcut pattern | |
| Control+Option+Space (⌃⌥Space) | Prominent global toggle hotkey | |

**User's choice:** Option+Shift+T (⌥⇧T).
**Notes:** Clear mnemonic for "Timer" without clashing with standard browser/terminal shortcuts.

---

## the agent's Discretion

- Micro-spacing, paddings, and corner radii inside the 320px popover window.
- Low-level system hotkey registration implementation (e.g. Carbon `RegisterEventHotKey` or `NSEvent` global monitors).
- macOS window activation to bring the main app window to the front.

## Deferred Ideas

- Customizable global hotkey recorder UI (deferred to Phase 8 Settings & Preferences).
- Optional audio feedback chime on timer toggle (can be added as a preference in Phase 8).
