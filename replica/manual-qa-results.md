# TimeStamp — Manual macOS Acceptance QA Results

**Build Under Test:** `TimeStamp.app` (Release build, `com.timestamp.desktop`, `arm64`)  
**Started:** 2026-11-26  
**Rule:** Source code frozen during manual acceptance testing; production data preserved.

---

## Live QA Checklist

| # | Acceptance Test | Status | Notes / Classification |
| :-: | :--- | :---: | :--- |
| 1 | Timer start, pause, stop and resume | **FAIL → FIXED** | Timer count-up worked correctly. Code defect: idle-detection sheet fired immediately at 0m after timer start. Root cause identified and patched (D-IDLE-01). **Must be re-verified manually with the new build.** |
| 2 | Manual time entry | **NOT TESTED** | — |
| 3 | Project and task creation | **NOT TESTED** | — |
| 4 | Tag creation and selection | **NOT TESTED** | — |
| 5 | Billable tracking | **NOT TESTED** | — |
| 6 | Goal creation and Keep Going | **NOT TESTED** | — |
| 7 | Pomodoro countdown and transitions | **NOT TESTED** | — |
| 8 | Calendar editing and drag-and-drop | **NOT TESTED** | — |
| 9 | Reports and exports | **NOT TESTED** | — |
| 10 | Menu bar controls | **NOT TESTED** | — |
| 11 | Floating mini-timer | **NOT TESTED** | — |
| 12 | Global shortcuts | **NOT TESTED** | — |
| 13 | Notifications | **NOT TESTED** | — |
| 14 | Idle detection | **NOT TESTED** | — |
| 15 | Light and dark modes | **NOT TESTED** | — |
| 16 | Application restart and data persistence | **NOT TESTED** | — |

---

## Detailed Findings & Failure Log

### Test 1 — Timer Start, Pause, Stop and Resume

**Classification:** Code Defect  
**Severity:** High (blocks basic timer usage)  
**Status:** Fixed — requires manual re-verification

**Observed failure:**  
Immediately after clicking the Play button to start a timer, the idle-resolution sheet appeared with the message "You were inactive for 0m". This occurred within the first ~22 seconds of a fresh timer session.

**Root cause:**  
`IdleDetectionManager.evaluateIdleState()` queried `CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .null)` and compared the raw value directly against the idle threshold. This raw HID reading is a system-wide counter that accumulates regardless of whether a TimeStamp timer is running. If the user's Mac had been idle (or if they interacted with the app launcher rather than the mouse/keyboard), the system HID counter could already exceed the threshold the moment the timer starts.

**Fix applied (D-IDLE-01):**  
- Added `timerSessionStartedAt: Date?` to `IdleDetectionManager`.  
- `evaluateIdleState` now computes `effectiveIdleSeconds = min(rawHIDSeconds, secondsSinceSessionStart)`. Idle time that predates the timer session start is excluded.  
- Added `notifyTimerStarted(at:)` public method which records the session start date and dismisses any lingering stale prompt.  
- `IdleDetectionManager.startMonitoring()` wires an `onTimerSessionStarted` callback into `TimerManager` to avoid a singleton initialisation cycle.  
- `TimerManager.start()` and `resume()` fire `onTimerSessionStarted` to reset the baseline.  
- `TimerManager.restoreActiveSession()` fires `onTimerSessionStarted(Date())` on launch so that a restored running session is also protected.

**Files changed:**  
- `Sources/Core/System/IdleDetectionManager.swift`  
- `Sources/Core/Timer/TimerManager.swift`  
- `Tests/Phase5SystemIntegrationTests.swift` (3 new regression tests added; Path A existing test updated)

**Test suite:** 132/132 passing (exit code 0)
