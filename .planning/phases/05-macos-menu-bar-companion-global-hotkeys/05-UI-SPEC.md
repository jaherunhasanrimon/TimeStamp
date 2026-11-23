---
phase: 05
slug: macos-menu-bar-companion-global-hotkeys
status: approved
shadcn_initialized: false
preset: macos-native
created: 2026-11-23
---

# Phase 5 — UI Design Contract: macOS Menu Bar Companion & Global Hotkeys

> Visual and interaction design contract for Phase 5 MenuBarExtra status item, live ticker, quick-entry popover window, and global system hotkeys. Inherits core tokens from `01-UI-SPEC.md` and locks decisions D-01 through D-08.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Native SwiftUI (macOS 14+) |
| Preset | macOS Native Human Interface Guidelines |
| Component library | Native SwiftUI Views & Modifiers (`MenuBarExtra`) |
| Icon library | SF Symbols 5 (`stopwatch`, `stopwatch.fill`, `play.fill`, `pause.fill`, `stop.fill`, `xmark`, `folder`, `circle.fill`, `macwindow`, `power`, `arrow.up.forward.app`) |
| Font | San Francisco (System & Monospaced Digits) |

---

## Spacing Scale

Declared values (conforming to 4pt grid in `AppSpacing`):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Status bar icon-to-text gap, inline control spacing |
| sm | 8px | Button padding, control bar gaps, row vertical margins |
| md | 16px | Popover internal padding, section margins |
| lg | 24px | Section separation |
| xl | 32px | Outer container margins |

Exceptions:
- Menu Bar Popover Window width: fixed 320px width (`D-05`)
- Menu Bar Popover Window height: auto-sizing (~280px - 340px)
- Status bar item height: standard macOS menu bar height (24px)

---

## Typography

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Menu Bar Status Ticker | 13pt | Regular | 1.0 (`monospacedDigit()`) | Live menu bar duration (`00:24:15`) (`D-04`) |
| Popover Large Ticker | 22pt | Bold | 1.0 (`monospacedDigit()`) | Prominent live duration inside popover |
| Popover Title | 13pt | Semibold | 1.2 | "TimeStamp" header title |
| Description Input | 13pt | Regular | 1.3 | "What are you working on?" input field |
| Label | 12pt | Medium | 1.2 | Project / Task pill text, button labels |
| Caption | 11pt | Regular | 1.2 | Hotkey hints ("⌥⇧T"), status secondary text |

---

## Color (60-30-10 Rule)

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#1C1C1E` (Dark) / `#FFFFFF` (Light) | Popover window surface (`AppColors.background`) |
| Secondary (30%) | `#2C2C2E` (Dark) / `#F2F2F7` (Light) | Card background, input background, subtle dividers |
| Accent (10%) | `#7B61FF` (Dark) / `#5C3BFE` (Light) | Primary Start button, active project dot |
| Destructive | `#FF453A` (Dark) / `#D70015` (Light) | Stop button, Discard button |
| Warning | `#FF9F0A` | Paused status bar icon and paused indicator pill (`D-03`) |

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Menu Bar Tooltip (Idle) | "TimeStamp — Click to track time" |
| Menu Bar Tooltip (Running) | "TimeStamp — Tracking: {description}" |
| Menu Bar Tooltip (Paused) | "TimeStamp — Paused" |
| Popover Description Placeholder | "What are you working on?" |
| Popover Start Button | "Start" |
| Popover Stop Button | "Stop" |
| Popover Pause Button | "Pause" |
| Popover Resume Button | "Resume" |
| Popover Discard Button | "Discard" |
| Open Main Window CTA | "Open TimeStamp" |
| Quit App CTA | "Quit" |
| Hotkey Hint Label | "Global Hotkey: ⌥⇧T" |

---

## Component Specifications

### 1. `MenuBarLabelView` (`D-01`, `D-02`, `D-03`, `D-04`)
- Status item placed directly in the macOS menu bar.
- States:
  - **Idle (`D-01`)**: Monochrome stopwatch icon (`Image(systemName: "stopwatch")`).
  - **Running (`D-02`)**: Stopwatch icon + duration ticker (`HStack(spacing: 4) { Image(systemName: "stopwatch"); Text(timerManager.formattedDuration).font(.system(size: 13, design: .default).monospacedDigit()) }`).
  - **Paused (`D-03`)**: Pause icon with warning tint + paused duration (`HStack(spacing: 4) { Image(systemName: "pause.fill").foregroundStyle(.orange); Text(timerManager.formattedDuration).font(.system(size: 13, design: .default).monospacedDigit()).foregroundStyle(.secondary) }`).
- Guaranteed zero layout jitter with strict fixed `HH:MM:SS` and `.monospacedDigit()` (`D-04`).

### 2. `MenuBarPopoverView` (`D-05`, `D-06`)
- Fixed width: 320px.
- Sections:
  1. **Header Bar**:
     - Left: App icon + "TimeStamp" title.
     - Right: Large live ticker (`22pt` monospaced digits) or "00:00:00" when idle.
  2. **Quick Entry & Project Section**:
     - Description text field ("What are you working on?").
     - `ProjectTaskPickerButton` with color dot, project name, and task picker.
  3. **Controls Bar**:
     - When Idle: Large prominent Start button (`play.fill`) with brand accent tint.
     - When Running: Stop button (`stop.fill`, red tint), Pause button (`pause.fill`), Discard button (`xmark`).
     - When Paused: Resume button (`play.fill`), Stop button (`stop.fill`), Discard button (`xmark`).
  4. **Footer Section**:
     - Divider.
     - "Open TimeStamp" button (brings main application window to front).
     - "Quit" button (terminates application).
     - Shortcut caption: "Toggle Timer: ⌥⇧T".

### 3. `GlobalHotkeyManager` (`D-07`, `D-08`)
- Singleton listening for `Option+Shift+T` (`⌥⇧T`) system-wide using Carbon `RegisterEventHotKey`.
- Action:
  - If timer is running: stops timer, saves completed entry.
  - If timer is idle: starts timer pre-populating `retainedProjectId` and `retainedTaskId`.
- Runs on main dispatch queue, thread-safe with `TimerManager`.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-11-23
