# TimeStamp — Toggl Track Feature Parity Build Log

## Executive Summary
Systematic parity engineering across Phases 0–6 completed cleanly on Apple Silicon (`macOS 14.0+`, Swift 5.10 / SwiftUI), closing all identified bugs, missing workflows, interaction gaps, and visual differences against Toggl Track for macOS while preserving TimeStamp branding, local data safety, and zero paywalls.

## Phase History & Verified Outcomes

### Phase 0 — Bug Triage, Calculation Integrity & Test Infrastructure Repair
- Fixed active-timer double-counting in `PersistenceStore.progress(for:)` (`Sources/Models/PersistenceStore.swift`) and `CompactTrackerView.todayTotalDuration` (`Sources/Views/Tracker/CompactTrackerView.swift`) by skipping uncompleted `endDate == nil` entries in the completed loop and accumulating active elapsed time from `TimerManager` once.
- Guarded `UNUserNotificationCenter.current()` and `NSSound.beep()` in `NotificationManager.swift` with `hasValidAppBundle` (`Bundle.main.bundleURL.pathExtension == "app"`) so CLI native test runners never crash.
- Isolated in-memory test runs of `PomodoroManager` (`TimerManager.isInMemoryStore`) from `UserDefaults.standard`.
- Fixed `QAAuditRunner.swift` duplicate `@main` symbol collision into `@Suite("QA Audit Integration Tests")` inside `scripts/run-qa-tests.sh` using native `swift test --enable-swift-testing --disable-xctest` linked against `Testing.__swiftPMEntryPoint()`.
- Switched default app theme (`@AppStorage("appTheme")`) from `"dark"` to `"system"` (`Sources/App/TimeStampApp.swift`).

### Phase 1 — Core Timer, Entry UX & Visual Foundations
- Added live description autocomplete popover (`AutocompletePopoverView.swift`) with `RECENT ENTRIES` & `PROJECTS · Client` results, highlighted matching substrings, and keyboard (`↑`/`↓`/`Return`/`Esc`) navigation.
- Added `@` Project picker and `#` Tag picker inline triggers inside `ActiveTimerBar.swift`.
- Added Toggl vertical Play / `+` mode toggle circles, inline Manual Mode (`⌘D`), `0:00:00` compact bar ticker (`TimeCalculator.formatCompactDuration`), `⌘E` live running-entry editing (`EntryEditSheet`), duplicate entry (`PersistenceStore.duplicateTimeEntry`), non-blocking 6s Undo Delete banner (`undoLastDelete`), Favorite entries (`isFavorite` + quick-start), same-day identical collapsible entry groups (`EntryGroupingHelper`), entry text + billable filters (`EntryFilter`), enforced Default Project preference (`applyDefaultProjectIfIdle`), global menu shortcuts (`⌘N`, `⌘D`, `⌘S`, `⌘O`, `⌘E`, `⌘,`, `⇧⌘M`, `⇧⌘E`), vector laptop/hands empty-state artwork (`TogglEmptyStateView`), and Toggl pill capsule switcher (`CapsuleViewSwitcher`).
- Verified with `Tests/Phase1CoreTrackingTests.swift` (7 tests).

### Phase 2 — Projects, Clients, Tasks & Tags Parity
- Extended `Project` with backward-compatible `estimatedHours` (`Sources/Models/Project.swift`).
- Upgraded `ProjectEditorSheet` with Hourly Rate, Time Estimate hours, and Billable by default controls; added effective rate badges and estimate progress bars to `ProjectRowView`.
- Added Client filter dropdown in `ProjectsListView`; added Currency and Default Hourly Rate controls to `ClientEditorSheet` and rate pill display in `ClientRowView`.
- Polished `ProjectPickerPopover`: excluded archived projects, added expandable inline active Tasks, keyboard navigation, and styled `+ Create project` with magenta `+` and primary text color (`toggl_macos_project_picker.jpg` parity).
- Upgraded `ProjectTaskPickerButton` to use `ProjectPickerPopover` across `EntryEditSheet` and `MenuBarPopoverView`.
- Added inline tag rename in `TagPickerPopover` and created dedicated `TagsListView` wired into `SidebarDestination.tags` (`AppSidebar`, `DetailContainerView`).
- Verified with `Tests/Phase2ProjectsTagsTests.swift` (4 tests).

### Phase 3 — Interactive Calendar & Multi-View Reports
- Enhanced `CalendarLayoutHelper` with configurable pixel-to-time snapping (`1/5/15/30m`), duration-preserving `movedDates`, and edge-clamped `resizedDates`.
- Upgraded `CalendarBlockView`, `DayTimelineGridView`, `WeekTimelineGridView`, and `CalendarTimelineView` with double-click empty-slot creation (`CalendarQuickCreateSheet`), drag-to-move, top/bottom resize handles, `$` billable badges, live active timer block, and right-click context menu (`Continue`, `Duplicate`, `Edit`, `Toggle Billable`, `Delete`).
- Added opt-in read-only local `AppleCalendarService` (`EventKit`) overlay with `NSCalendarsUsageDescription` & `NSCalendarsFullAccessUsageDescription` in `TimeStamp.app/Contents/Info.plist` (honestly documenting Google/Outlook as requiring external OAuth).
- Built multi-tab `ReportsView` (`Summary`, `Detailed`, `Weekly`) featuring `< Period >` stepper, Client/Project/Tag/Billable/Description filters, 4 KPIs, Stacked Bar (`ReportsDailyBarChartView`), Donut (`ReportsDonutChartView`), Expandable Project->Task Hierarchy (`ReportsHierarchyView`), Sortable Detailed Table (`ReportsDetailedTableView`), Mon–Sun Matrix (`ReportsWeeklyMatrixView`), extended CSV/JSON columns, and native CoreGraphics PDF report export (`ExportService.generatePDF`).
- Verified with `Tests/Phase3CalendarReportsTests.swift` (3 tests).

### Phase 4 — Goals & Pomodoro Parity
- Extended `Goal` (`Sources/Models/Goal.swift`) with multi-project `projectIds: [UUID]`, `startDate`, `endDate` (`UNTIL`), while preserving original canonical `rawValue` strings (`"Daily"`, `"At least"`, etc.) and tolerant decoding so real production `timestamp_store.json` files upgrade seamlessly without error.
- Updated `PersistenceStore.entryMatchesGoal`, `progress`, and `deleteProject` for multi-project & active date windows without sample seeding or goal-count limits.
- Rebuilt `GoalEditorSheet` to match `toggl_macos_goal_popover.jpg` (`GOAL` header, icon selector, multi-project `TRACK` picker, decimal hours `FOR`, `UNTIL No end date`, Live Preview, `Delete`, `Save`) and polished borderless `KEEP GOING` inside `GoalsCardView`.
- Upgraded `PomodoroManager` & `PomodoroPopoverView` to match `toggl_macos_pomodoro_window.jpg` (`"I'm focusing on..."` -> `DETAILS` popover, 60-tick dial, `"Start session"`, `"Pomodoro settings ▸"`, standalone `Window("Pomodoro")`, `autoStartBreaks`, `autoStartFocus`, `countUpMode`, notification & sound toggles).
- Verified with `Tests/Phase4GoalsPomodoroTests.swift` (3 tests).

### Phase 5 — Native macOS Companion, Mini-Timer, Idle, Reminders, Autotracker & Settings
- Created `FloatingMiniTimerView` (`Window("Mini Timer", id: "mini-timer")`, `⇧⌘M`) with always-on-top pin (`NSWindow.Level.floating`), Pause/Stop, and quick-start input.
- Upgraded `MenuBarLabelView` (optional project/description beside duration) and `MenuBarPopoverView` (Favorites/Recent quick resume + Mini-Timer button).
- Added `IdleDetectionManager` (`CGEventSource.secondsSinceLastEventType` HID inactivity — zero Accessibility/Screen Recording permissions) & `IdleResolutionSheet` with all 4 Toggl actions (`Discard & continue`, `Discard`, `Keep`, `Add as new entry`).
- Added `ReminderManager` workday weekday schedule notifications (`UNUserNotificationCenter`).
- Added strictly opt-in `ActivityTrackerManager` (`NSWorkspace` >10s spans, zero keystrokes/screenshots, customizable bundle exclusions, keyword `AutotrackerRule` matching, and 1-click activity history purge).
- Added `SystemIntegrationManager` (`showDockIcon` via `NSApp` guarded safely for CLI tests + `SMAppService.mainApp` Login Item toggle).
- Reorganized `SettingsView` into 6 clean macOS tabs (`General`, `Timer`, `Pomodoro`, `Idle & Reminders`, `Activity`, `Data`).
- Verified with `Tests/Phase5SystemIntegrationTests.swift` (3 tests).

### Phase 6 — Final QA, Packaging & Visual Inspection
- Fixed two real release-runtime bugs caught on live launch: tolerant production `Goal` enum decoding (`At least`/`Daily`) and safe `NSApp != nil` guard in `SystemIntegrationManager.applyDockIconPolicy()`.
- Fixed two visual layout bugs caught in PNG screenshot review: greedy `Color.clear` vertical expansion in `WeekTimelineGridView` weekday header and standalone window background fill in `PomodoroPopoverView`.
- Verified **129 tests across 25 suites passing** in `./scripts/run-qa-tests.sh` (`0.081s`), `100.0 / 100` feature parity in `replica/features.csv` via `parity.py`, valid codesigned ARM64 release `TimeStamp.app`, and intact production DB (`36 timeEntries`, `1 goal`, `2 projects`, `4 clients`, `4 tags`, `1 task`).


---

## Phase 7 — Idle Detection Bug Fix (D-IDLE-01)

**Date:** 2026-11-27  
**Trigger:** Manual Acceptance Test 1 — false idle-resolution sheet fired immediately (0m) after starting a timer.

### Changes
- **`Sources/Core/System/IdleDetectionManager.swift`**
  - Added `timerSessionStartedAt: Date?` private property.
  - Added `notifyTimerStarted(at:)` public method.
  - `startMonitoring()` now wires `timerManager.onTimerSessionStarted` callback.
  - `evaluateIdleState()` caps raw HID idle seconds to `min(rawHIDSeconds, secondsSinceSessionStart)`.
  - `dismissPrompt()` clears `timerSessionStartedAt`.

- **`Sources/Core/Timer/TimerManager.swift`**
  - Added `onTimerSessionStarted: ((Date) -> Void)?` callback property.
  - `start()`, `resume()`, `restoreActiveSession()` all invoke the callback.

- **`Tests/Phase5SystemIntegrationTests.swift`**
  - Updated Path A test to backdate entry and call `notifyTimerStarted` correctly.
  - Added 3 new regression tests (D-IDLE-01 suite).

### Test Result
**132/132 tests passing** (25 suites, 0.085s, exit code 0).  
3 net new regression tests added.

### Release Build
Rebuilt `TimeStamp.app` from clean release target.
