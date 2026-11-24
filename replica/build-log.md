# Replica Build Log: TimeStamp (Toggl Track macOS Replica)

**Date**: 2026-11-24  
**Target Platform**: macOS 14.0+ Apple Silicon (Swift & SwiftUI)  
**Reference Sources**: `replica/screens/` (8 high-res reference screenshots)

---

## Log Entries

### Priority 2: Pomodoro Engine & macOS Notifications
- **Status**: Completed & Verified
- **Components & Models Built**:
  - `Sources/Services/Notifications/NotificationManager.swift`:
    - Integrates native macOS `UNUserNotificationCenter` for desktop alerts with authorization handling and audio bell feedback.
  - `Sources/Core/Pomodoro/PomodoroManager.swift`:
    - Full `@Observable` state machine managing `.work`, `.shortBreak`, `.longBreak`, and interval cycle count (default: 4 work sessions before a 15-minute long break).
    - Default durations: 25m focus, 5m short break, 15m long break.
    - Start, Pause, Resume, Skip, Reset, and Reset Cycle controls.
    - **Timer Integration**: Starting work automatically syncs and starts productive tracking in `TimerManager`. Work session completion automatically stops `TimerManager` and saves the `TimeEntry`.
    - **Break Isolation**: Breaks explicitly ensure `TimerManager` is stopped; break time is strictly NOT logged as productive work.
    - **Background & Sleep Immunity**: Uses wall-clock timestamp deltas (`Date().timeIntervalSince(start)`) and `SleepWakeMonitor` to ensure countdown integrity across macOS sleep and backgrounding.
    - **State Persistence**: Serializes running state, completed session count, and elapsed time to `UserDefaults` for seamless restoration across app restarts.
  - `Sources/Views/Pomodoro/PomodoroPopoverView.swift`:
    - Polished Toggl-style popover anchored to the 🍅 tomato button in `ActiveTimerBar`.
    - Displays session badge, circular progress ring, large monospaced countdown digits (`24:59`), completed interval pills (🍅🍅⚪⚪), and Start / Pause / Skip / Reset buttons.
  - `Sources/Views/Timer/ActiveTimerBar.swift`:
    - Activated the tomato icon button with live pulsing ring during active sessions and popover attachment.
  - `Sources/Views/MenuBar/MenuBarLabelView.swift` & `MenuBarPopoverView.swift`:
    - Displays active Pomodoro session countdown (`🍅 24:15`) in the macOS system menu bar, with quick pause/resume controls in the menu bar popover.
  - `Sources/Views/Settings/TimerPreferencesSectionView.swift`:
    - Added user-configurable duration pickers (Focus, Short Break, Long Break) and native notification permission authorization button.
  - `Tests/PomodoroEngineTests.swift`:
    - 7 comprehensive automated tests verifying default durations, start/pause/resume, work completion transition, 4-cycle long break, break isolation, custom durations, and notification safety.

---

### Priority 1: Full Goals Engine & Persistence
- **Status**: Completed & Verified
- `Goal.swift`, `PersistenceStore.swift`, `GoalEditorSheet.swift`, `GoalsCardView.swift`, `GoalEngineTests.swift` (8 tests passing).

---

### Visual Reconstruction (Earlier Phases)
- `S01`: Compact Desktop Tracker Window (`CompactTrackerView.swift`, `ActiveTimerBar.swift`, `CircularPlayButton.swift`, `CapsuleViewSwitcher.swift`, `TogglEmptyStateView.swift`).
- `S02`: Project & Task Selector Popover (`ProjectPickerPopover.swift`).
- `S03`: Daily Time Entries Log (`DayGroupHeaderView.swift`, `TimeEntryRowView.swift`, `EntriesListView.swift`).
- `S04`: Interactive Calendar Timeline (`CalendarTimelineView.swift`).
- `S05`: Full App Dashboard & Workspace Navigation (`AppSidebar.swift`).
- `S06`: Reports & Analytics (`ReportsView.swift`, `ReportsDonutChartView.swift`).

### Priority 3: Billable Tracking & Tags Flow (Completed)
- **Part A (Billable Tracking)**:
  - Connected and enhanced the `$` billable toggle in `ActiveTimerBar.swift` with real-time toggle reflection on active sessions and `project.isBillableDefault` auto-enablement.
  - Ensured `TimerManager.start`, `continueEntry`, and `restoreActiveSession` accept, preserve, and retain `isBillable: Bool`.
  - Added billable indicator `$` in `AppColors.billable` (`#36B37E`) to `TimeEntryRowView.swift`.
  - Added billable checkbox toggle to `EntryEditSheet.swift` for both editing existing entries and manual logging.
  - Integrated hourly rates across `Project` (`hourlyRate: Double?`) and `Client` (`hourlyRate: Double?`), calculating accurate billable amount in `ReportsView.swift` with project override -> client fallback -> $50/hr default rate.
- **Part B (Tag Management)**:
  - Created authentic `TagPickerPopover.swift` styled after Toggl Track with real-time tag search, inline `+ Create tag "..."` button, multi-selection checkmarks, and hover/context-menu delete.
  - Connected 🏷️ button in `ActiveTimerBar.swift` with dynamic badge count and popover anchor.
  - Added multi-tag selection and removable capsule chips to `EntryEditSheet.swift`.
  - Rendered `#tag` badges in `TimeEntryRowView.swift`.
  - Added tag-based filtering (`EntryFilter.tag(UUID)`) with Tags section in filter dropdown menu of `EntriesListView.swift`.
  - Added `ReportDimension.tags` to `ReportsView.swift` for tag-level productivity distribution.
- **Part C (Data Integrity & Cascade Safety)**:
  - Implemented case-insensitive duplicate tag prevention.
  - Verified `PersistenceStore.deleteTag(id:)` cleans up deleted tag IDs across historical time entries without data loss.
  - Retained `retainedTagIds` and `retainedIsBillable` for chaining work.
- **Part D (Automated Verification)**:
  - Created `Tests/BillableAndTagsTests.swift` covering 8 dedicated test scenarios.
  - Recompiled release binary and packaged into `TimeStamp.app`.

---

### Priority 4: Goals Engine & Storage Integrity Repair (Toggl Parity)
- **Status**: Completed & Verified
- **Reference Analysis & Root Causes**:
  - Eliminated the false 6h 20m tracked time on fresh installs: removed automatic sample goals seeding from `PersistenceStore.init(inMemory: false)` and resolved duplicate entries.
  - Fixed duration doubling in `TimeEntry.effectiveDuration`: previously added `accumulatedDuration + (endDate - startDate)` which doubled stopped entries. Canonical duration is now strictly invariant across running, paused, stopped, and edited states.
  - Created automated timestamped backups in `~/Library/Application Support/TimeStamp/backups/` and non-destructive clean state reset via `resetToCleanState(createBackup:)`.
- **Goals Engine Architecture & Toggl Semantics**:
  - `Goal.swift`: Added `GoalTargetType` (`.atLeast`, `.lessThan`), `GoalCadence` (`.daily`, `.weekdays`, `.weekly`), and multi-criteria filters (`projectId`, `clientId`, `taskId`, `tagIds`, `billableFilter`).
  - **Weekday Semantics**: "Each weekday (Monday–Friday)" operates as an independent daily target evaluated for each individual weekday.
  - **Client Hierarchy**: Strict adherence to Toggl hierarchy (Client -> Projects -> TimeEntries). Client-filtered goals match entries where `store.project(for: entry.projectId)?.clientId == goal.clientId`.
  - **Live Preview in Editor**: `GoalEditorSheet.swift` includes an interactive Live Progress Preview card showing matching time in the active period before saving.
  - **Visual Badges**: `GoalsCardView.swift` displays `OVER LIMIT` in destructive red `#FF453A`, `COMPLETED` in green `#36B37E`, and `KEEP GOING` in Toggl magenta `#E54583` with duplicate timer prevention.
- **Project Picker Popover Polish**:
  - Set popover width to `360` to accommodate long project and client names.
  - Styled `+ Create project` footer with Toggl magenta `#E54583` text and icon.
- **Verification**:
  - `Tests/GoalsAndStorageRepairTests.swift`: 16 comprehensive automated tests covering clean installs, safe backups, at-least/less-than goals, project/client/tag/billable filters, weekday cadence, live timer updates, and anti-double-counting.
  - Successfully built, signed, and packaged release binary into `TimeStamp.app`.
