# Plan 02-01 Summary: Core Drift-Free Timer Engine & Services

**Status**: Complete
**Execution Date**: 2026-11-23
**Target Platform**: macOS 14.0+ (Apple Silicon)

---

## 1. Accomplishments

- **TimeCalculator (`Sources/Core/Timer/TimeCalculator.swift`)**:
  - Implemented pure wall-clock delta arithmetic (`calculateDuration`) ensuring 0% drift across sleep/wake and backgrounding (`TIMER-05`).
  - Added negative clock skew protection using `max(0, ...)` bounds.
  - Implemented `formatDuration(_:)` formatting intervals into standard `HH:MM:SS` (e.g. `00:04:12`) with zero-padded double digits (`D-07`).
- **SleepWakeMonitor (`Sources/Core/Timer/SleepWakeMonitor.swift`)**:
  - Attached listeners for `NSWorkspace.willSleepNotification` and `NSWorkspace.didWakeNotification` via `NotificationCenter.default`.
  - Safely notifies `TimerManager` upon system sleep and wake events for instant timestamp recalculation (`D-16`).
- **TimerManager (`Sources/Core/Timer/TimerManager.swift`)**:
  - `@Observable @MainActor` state machine coordinating all timer operations.
  - `start()`: Starts active session with description, project, task, and tags (`TIMER-01`).
  - `pause()` & `resume()`: Safely accumulates elapsed time without drift (`TIMER-02`).
  - `stop()`: Persists completed `TimeEntry` to `PersistenceStore`, retains last selected project/task for chained work (`TIMER-03`, `D-06`).
  - `discard()`: Aborts active session without persisting an entry (`D-08`).
  - `continueEntry()`: Clones all attributes, auto-stops any running timer, and immediately starts a new session (`TIMER-04`, `D-09`, `D-10`, `D-11`, `D-12`).
  - `restoreActiveSession()`: Rehydrates uncompleted active entries from disk upon app launch/restart with zero data loss (`D-14`).
  - `startTickTimer()`: 1 Hz cadence on `.common` RunLoop for minimal CPU (<0.1%) and battery efficiency (`D-15`).
- **Automated Unit Tests (`Tests/TimerTests.swift`)**:
  - 8 new tests added (13 total across test suites), verifying durations, formatting, clock skew defense, start/stop persistence, pause/resume, discard, continue auto-switching, and auto-restore.
  - Executed in `0.002s` with 100% pass rate.

---

## 2. Verification

- `swift build`: Succeeded with zero errors and zero warnings.
- `swift test`: 13/13 tests passed in 0.002s across `Timer Engine & Drift-Free Math Tests` and `Domain Model & PersistenceStore Tests`.
- All must-haves and criteria for Plan 02-01 verified.
