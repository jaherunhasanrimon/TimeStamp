# Project Research Summary

**Project:** TimeStamp
**Domain:** Native macOS Desktop Time Tracking (Apple Silicon, macOS 14+ Sonoma & macOS 15+ Sequoia)
**Researched:** 2026-11-23
**Confidence:** HIGH

## Executive Summary

TimeStamp is a desktop time-tracking application engineered specifically for macOS on Apple Silicon. Inspired by the speed, simplicity, and refined interaction design of Toggl Track, TimeStamp prioritizes frictionless time entry, drift-free background precision, and rich visual productivity insights without the bloat of web-wrapper frameworks.

The recommended architectural approach is pure native Swift 5.10/6.0 with SwiftUI and SwiftData. This foundation ensures immediate startup, a negligible memory footprint (<35MB RAM compared to Electron's 200MB+), fluid 120Hz ProMotion animations, and seamless integration with macOS system components such as `MenuBarExtra` and global hotkey daemons.

Key risks center on timer accuracy during system sleep/App Nap, multi-threaded SwiftData access across menu bar and window scenes, and date-boundary management. These are fully mitigated by employing timestamp-based elapsed calculation, single-source-of-truth `@Observable` state, and strict `Calendar.current` interval grouping.

## Key Findings

### Recommended Stack

- **Core:** Swift 5.10+, SwiftUI (macOS 14+), SwiftData (Modern declarative `@Model` persistence).
- **Supporting:** `KeyboardShortcuts` (Global shortcut management), Apple `Charts` (Native visualization), `UniformTypeIdentifiers` (Data export).
- **Tooling:** Swift Package Manager, Xcode / Swift CLI, Swift Testing framework (`import Testing`).

### Expected Features

**Table Stakes (v1):**
- Running timer with start, pause, stop, and continue controls.
- Drift-free wall-clock timestamp calculations.
- Time entries CRUD with day/week grouped timelines.
- Projects with custom color identification.
- Tasks hierarchy under projects.
- Clients association with projects.
- Today's dashboard with daily/weekly totals.

**Differentiators (v1):**
- Menu Bar Companion (`MenuBarExtra`) with live status ticker.
- Configurable global keyboard shortcut to toggle timer from any macOS app.
- Interactive day and week calendar timeline visualization.
- Productivity reports with distribution charts by project and client.
- Native Dark and Light theme support following Apple HIG.

**Deferred (v2+):**
- CloudKit multi-device sync.
- System Idle Detection prompt.
- Calendar feed integrations (iCal / Google Calendar).

### Architecture Approach

A clean modular SwiftUI desktop architecture:
1. **Presentation:** `TimeStampApp` coordinating `MainWindow` and `MenuBarExtra`.
2. **State & Services:** `@Observable class TimerManager`, `SleepWakeMonitor`, and `HotKeyManager` on `@MainActor`.
3. **Data Layer:** SwiftData `ModelContainer` managing `TimeEntry`, `Project`, `Task`, `Client`, `Tag`.

### Critical Pitfalls

1. **Timer Sleep/Wake Drift:** Fixed by calculating `Date().timeIntervalSince(startDate)` rather than continuous integer tick increments.
2. **SwiftData Threading:** Mitigated by keeping primary UI mutations on `@MainActor` with a single shared container.
3. **Menu Bar vs Window Sync:** Solved by passing a unified `@Observable TimerManager` environment object to both scenes.

## Implications for Roadmap

The recommended 7-phase implementation roadmap:

### Phase 1: Project Scaffolding & SwiftData Foundation
- Setup Swift package / Xcode project for macOS 14+.
- Define SwiftData `@Model` classes (`TimeEntry`, `Project`, `Task`, `Client`, `Tag`).
- Setup design system tokens (colors, typography, spacing).

### Phase 2: Core Drift-Free Timer Engine & State Management
- Implement `TimeCalculator` and `@Observable TimerManager`.
- Build `SleepWakeMonitor` to reconcile system sleep/wake.
- Unit test timer arithmetic, pauses, and resumed sessions.

### Phase 3: Time Entries Management & Activity Feed
- Implement Time Entries grouped by day with daily sum headers.
- Entry CRUD (inline editing of description, project, start/end time, deletion).
- Manual time entry creation modal.

### Phase 4: Projects, Tasks, and Clients Management
- Projects management view with custom color picker.
- Task hierarchy under projects.
- Client creation and project association.

### Phase 5: macOS Menu Bar Companion & Global Hotkeys
- Build `MenuBarExtra` scene with live duration ticker and quick toggle.
- Integrate `KeyboardShortcuts` for global hotkey timer toggle from anywhere in macOS.

### Phase 6: Today Dashboard & Swift Charts Reports
- Dashboard view with today's total, weekly progress bar, and recent activity.
- Reports view with Swift Charts breakdowns (by project and client) and date range filtering.
- Data export service (CSV / JSON).

### Phase 7: Calendar Timeline View, Settings, and Final Verification
- Day and week calendar timeline block view.
- Preferences view (Theme dark/light, default timer options, shortcuts).
- Comprehensive end-to-end verification and build validation.

---
*Research completed: 2026-11-23*
*Ready for roadmap: yes*
