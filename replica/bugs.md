# QA Bug Tracker: TimeStamp macOS Application

## Confirmed & Resolved Bugs

### BUG-01 [Severity S1 - Data Integrity] Duration Doubling on Stopped Entries
- **Symptom**: Stopped time entries reported double their actual tracked time (e.g. 1 hour reported as 2 hours, 3 hours reported as 6 hours).
- **Root Cause**: In `Sources/Models/TimeEntry.swift`, `effectiveDuration` calculated `accumulatedDuration + max(0, (endDate ?? Date()).timeIntervalSince(startDate))`. For stopped entries where `accumulatedDuration` was already saved as `(endDate - startDate)`, this added the duration twice ($T + T = 2T$).
- **Fix**: In `TimeEntry.swift`, `effectiveDuration` now checks `if let endDate = endDate`. If `accumulatedDuration > 0`, it returns `accumulatedDuration` directly.
- **Verification**: Regression test `TC-09` in `qa_audit_runner.swift` and `Tests/GoalsAndStorageRepairTests.swift`.

### BUG-02 [Severity S1 - Data Integrity] False 6h 20m Tracked Time on Fresh Installs
- **Symptom**: New application installations launched with pre-populated fake tracked time and mock goals.
- **Root Cause**: `PersistenceStore.init(inMemory: false)` called `seedSampleGoalsIfNeeded()`, injecting 4 sample goals on clean launch.
- **Fix**: Removed `seedSampleGoalsIfNeeded()` from `init`. Fresh installs start with 0 time entries, 0 goals, and 0 seeded entities. Sample seeding is isolated to explicitly requested demo mode.
- **Verification**: Verified via `TC-01..04` and fresh installation isolation test.

### BUG-03 [Severity S2 - Functional] Newly Created Goals Falsely Marked "COMPLETED"
- **Symptom**: Adding a new goal immediately evaluated to 100% completed even when no matching time was tracked.
- **Root Cause**: Combination of:
  1. The duration doubling bug in `effectiveDuration`.
  2. Multi-criteria matching not resolving project-to-client relationships.
  3. Goals created with default `0` duration or ambiguous cadences.
- **Fix**: Rebuilt the Goals Engine in `PersistenceStore.swift` with explicit target types (`.atLeast`, `.lessThan`), weekday independent daily semantics, client-project hierarchy resolution, and live preview card in `GoalEditorSheet`.
- **Verification**: Verified via `TC-12..18`.

### BUG-04 [Severity S3 - Visual Polish] Project Picker Width & Button Color
- **Symptom**: Long project names (e.g. `Study Until She Reply........`) were truncated in `ProjectPickerPopover`. Bottom `+ Create project` footer used white/primary text rather than Toggl magenta.
- **Root Cause**: Popover fixed width was 300px, and text style lacked `AppColors.togglMagenta`.
- **Fix**: Expanded width to 360px and applied `.foregroundStyle(AppColors.togglMagenta)` to both icon and label.
- **Verification**: Visually checked and verified against reference Screenshot 2.

### BUG-05 [Severity S4 - Theme Polish] Hardcoded Dark Hex in Popover Backgrounds
- **Symptom**: `TagPickerPopover.swift` search bar used hardcoded `Color(hex: "#1A1424")` and `ActiveTimerBar.swift` used `Color(hex: "#2C1E32")` behind the tomato icon, which looked unnatural in Light Mode.
- **Root Cause**: Static hex strings used instead of semantic dynamic tokens.
- **Fix**: Replaced with `AppColors.insetBackground` (resolves to `#100D15` in dark mode, `#ECE8E4` in light mode).
- **Verification**: Verified via `TC-28..31`.

---

## Current Status: 0 Open S1 / S2 / S3 / S4 Bugs
All identified issues have been fixed and regression-tested. Release build is verified and running.

---

### BUG-07 [Severity S2 - UX] False Idle Detection Immediately After Timer Start (D-IDLE-01)

- **Discovered:** Manual Acceptance Test 1 (Test 1: Timer start, pause, stop and resume)
- **Symptom:** Immediately after clicking Play to start a new timer (after ~22 seconds), the idle-resolution sheet appeared with "You were inactive for 0m". The timer count-up itself was correct.
- **Root Cause:** `IdleDetectionManager.evaluateIdleState()` compared the raw system-wide HID idle counter (`CGEventSource.secondsSinceLastEventType`) directly against the threshold without clamping it to the current timer session's elapsed time. If the Mac was idle before the timer started (e.g., user was reading, then clicked Play), the stale HID reading — accumulated before the session — could exceed the threshold the moment the first 15-second poll fired.
- **Fix (D-IDLE-01):**
  - Added `timerSessionStartedAt: Date?` property to `IdleDetectionManager`.
  - `evaluateIdleState` now computes `effectiveIdleSeconds = min(rawHIDSeconds, secondsSinceSessionStart)`. Idle time predating the timer session is excluded.
  - Added `notifyTimerStarted(at:)` to record the session baseline and auto-dismiss stale prompts.
  - `IdleDetectionManager.startMonitoring()` wires an `onTimerSessionStarted` callback into `TimerManager` to avoid a singleton initialisation cycle.
  - `TimerManager.start()`, `resume()`, and `restoreActiveSession()` all fire the callback.
- **Files Changed:** `Sources/Core/System/IdleDetectionManager.swift`, `Sources/Core/Timer/TimerManager.swift`
- **Regression Tests Added:** 3 new tests in `Tests/Phase5SystemIntegrationTests.swift` (D-IDLE-01 suite)
- **Test Suite After Fix:** 132/132 passing, exit code 0
- **Status:** FIXED
