# Comprehensive Gap Analysis: TimeStamp vs. Toggl Track macOS

**Audit Date:** 2026-11-26  
**Scope:** Product-level comparison across all Sections 4.A–4.K & 15 Reference Screens before implementation.

---

## Executive Summary of Findings

The existing TimeStamp v1.0 codebase has a solid drift-free timer core, SwiftUI design system (`#14101A` / `#FDFBFA` + `#E54583`), backup-safe persistence, and repaired Goals/Pomodoro/Tags/Billable engines. However, deep source & visual inspection uncovered **critical live bugs**, **broken Settings bindings**, **missing Toggl Track signature interactions**, and **incomplete Calendar/Reports/macOS integration**.

---

## Confirmed Code Bugs Discovered During Audit

| ID | Location | Root Cause | Impact | Target Phase |
| :--- | :--- | :--- | :--- | :--- |
| **BUG-A** | `PersistenceStore.swift:318-344` | `progress(for:activeEntry:activeDuration:)` iterates `for entry in timeEntries` without skipping `entry.endDate == nil` (or `entry.id == active.id`), AND adds `activeDuration` again afterward. Since `TimerManager.start()` persists `activeEntry` into `store.timeEntries` immediately, running timer duration is **counted twice** in live goal progress! | Live Goal progress advances at 2x speed while running. | Phase 0 |
| **BUG-B** | `CompactTrackerView.swift:25-28` | `todayTotalDuration` sums all `todayEntries` (including running `endDate == nil`) and adds `activeDuration` a second time. | `TODAY TOTAL` counter in Compact Tracker advances at 2x speed while running! | Phase 0 |
| **BUG-C** | `Tests/QAAuditRunner.swift` | Defining `@main` inside `Tests/` causes a duplicate `_main` linker symbol when running `swift test --enable-swift-testing --disable-xctest`. Meanwhile, all 106 existing `@Test` assertions in `Tests/*.swift` could not execute! | Blocks SPM's native Swift Testing runner for 19 existing test suites. | Phase 0 |
| **BUG-D** | `TimerPreferencesSectionView.swift` & `ActiveTimerBar.swift` | `@AppStorage("defaultProjectId")` is configurable in Settings, yet `TimerManager` / `ActiveTimerBar` never read or apply the default project! Similarly `playTimerSounds` and `notificationsEnabled` are unused. | Selecting a Default Project in Settings has no effect. | Phase 1 / Phase 4 |
| **BUG-E** | `TimeStampApp.swift:10` | `@AppStorage("appTheme")` defaults to `"dark"`, conflicting with `ThemePickerView` (`"system"`) and Toggl's System appearance default. | New installs don't automatically follow System appearance. | Phase 0 / Phase 1 |
| **BUG-F** | `ProjectEditorSheet.swift` & `ClientEditorSheet.swift` | `Project` & `Client` models store `hourlyRate`, `isBillableDefault`, `currency`, yet the editor sheets have zero controls for them! | Users cannot enter project/client rates or default billable status in the UI. | Phase 2 |
| **BUG-G** | `ProjectTaskPickerButton.swift:37` | `Menu` lists archived projects (`store.projects` unfiltered) and lacks search or quick project creation inside `EntryEditSheet` and `MenuBarPopoverView`. | Archived projects pollute edit dropdowns; inconsistent with `ProjectPickerPopover`. | Phase 2 |
| **BUG-H** | `ExportService.swift` | CSV & JSON exports omit `isBillable`, `tags`, `hourlyRate`, and `billableAmount`. | Financial/tag data is lost on export. | Phase 3 |

---

## Systematic Feature & Visual Gap Inventory (By Area)

### A. Timer & Time Entry Management (Phase 1)
1. **Description Autocomplete Popover** (*Toggl Screenshot 4*): Missing! Typing in `"What are you working on?"` must suggest matching unique past entries (`TIME ENTRIES`) and matching projects (`PROJECTS · Client`) with highlighted query characters, keyboard navigation (↑/↓/Return/Esc), and instant selection.
2. **Inline `@` (Project) & `#` (Tag) Triggers**: Missing! Typing `@` opens `ProjectPickerPopover`; `#` opens `TagPickerPopover`.
3. **Inline Manual Mode Switching (`⌘D`)**: Currently clicking `+` only opens a modal sheet; Toggl switches between Timer Mode and Manual Mode with vertical stacked circle toggles (Play / `+`) and lets users enter manual Start/End/Duration or open quick log cleanly.
4. **Duplicate Entry & Delete Undo Protection**: Context menu has Continue/Edit/Delete; missing explicit **Duplicate** completed entry action and non-blocking **5-second Undo Delete** banner.
5. **Group Similar Time Entries**: Missing! Setting + collapsible grouping in `EntriesListView` for same-day entries sharing description, project, task, tags, and billable flag.
6. **Favorite Time Entries**: Missing! Star/pin entries, display Favorites quick-start strip in Tracker & Menu Bar.
7. **Entry Search Bar & Billable Filter**: `EntriesListView` filters by project/client/tag, missing free-text description search & billable/non-billable filter.
8. **Toggl Keyboard Shortcuts**: Missing `⌘N` (new/focus), `⌘D` (mode toggle), `⌘S` (stop running), `⌘O` (continue last), `⌘E` (edit running), `⌘,` (Settings), `⇧⌘M` (Mini-Timer).
9. **Compact Timer Format (`0:00:00`)**: `ActiveTimerBar` and `TODAY TOTAL` currently display `00:00:00` instead of Toggl's compact `0:00:00` (while keeping `TimeCalculator.formatDuration` `00:00:00` for Menu Bar zero-jitter & existing tests!).

### B. Main Timer Interface & Visual Fidelity (Phase 1 & Phase 4)
1. **`ActiveTimerBar` Alignment**: Add stacked vertical Timer/Manual mode circles on right (matching Screenshot 1), selected project pill styling (`• Project` with `×` clear on hover matching Screenshot 5), inline `@`/`#` & autocomplete overlay.
2. **`CapsuleViewSwitcher`**: Screenshot 1 shows dark pill track `#1D1625` / `#100D15` with elevated selected segment `#2E2438` (and works cleanly in Light Mode too). Currently `CapsuleViewSwitcher` uses underline tabs instead of the macOS desktop capsule pill shown in Screenshot 1! Updating `CapsuleViewSwitcher` to match Screenshot 1 aligns 1:1 with the latest Toggl Track macOS app.
3. **`TogglEmptyStateView`**: Replace `👐` emoji with crisp vector SwiftUI illustration matching Screenshot 1 (white spotlight circle, dark laptop with `#E54583` circle dot, stylized typing hands).
4. **`ProjectPickerPopover` Polish** (*Screenshot 3*): Make `+` icon magenta (`#E54583`) and `"Create project"` text primary white/ink (`Color.primary`), support expandable inline Tasks under each project, and keyboard Up/Down/Return navigation.
5. **Running Entry Editing**: Clicking the active timer bar or pressing `⌘E` edits the currently running entry (start time, description, project, task, tags, billable) live without breaking the active timer.

### C. Projects, Clients & Tasks (Phase 2)
1. **Project Rates, Billable Default & Estimates**: Add `estimatedHours: Double?` to `Project.swift`, add Rate, Currency/Billable Default, and Estimate controls to `ProjectEditorSheet.swift`, and render estimate progress bars in `ProjectRowView.swift`.
2. **Client Rate & Currency Editing**: Add `hourlyRate` & `currency` inputs to `ClientEditorSheet.swift`.
3. **Inline Tasks in Project Picker**: Expand tasks nested beneath projects in `ProjectPickerPopover`, plus create project inside `EntryEditSheet` & `MenuBarPopoverView` using unified `ProjectPickerPopover`.
4. **Filter Projects by Client**: Add client filter dropdown alongside `[Active | Archived]` in `ProjectsListView.swift`.
5. **Default Project Enforcement**: Wire `@AppStorage("defaultProjectId")` into `TimerManager` & `ActiveTimerBar`.

### D. Tags Management (Phase 2)
1. **Dedicated Tags Management Screen**: Add `Tags` under `MANAGE` in `AppSidebar` (`SidebarDestination.tags`) matching Toggl's sidebar, supporting create, rename, recolor, usage count, search, and safe delete.

### E. Goals System (Phase 4)
1. **Goal Start & End Dates (`UNTIL`)**: Add `startDate: Date` and `endDate: Date?` to `Goal.swift` (backward compatible `Codable`), respecting end date boundaries in `PersistenceStore.progress`.
2. **Multiple Project Selection**: Support `projectIds: [UUID]` (preserving legacy `projectId: UUID?` decoding seamlessly) so goals like *"Python 2 hrs + MATHS 0.5 hr"* can target multiple projects!
3. **Toggl-Style Goal Popover Editor** (*Screenshot 5*): Upgrade Goal creation/editing to an authentic Toggl popover anchored to `+`/row (`GOAL` title + icon dropdown, `TRACK` multi-project & tag & client & billable pickers, `FOR` target type + decimal hours / hrs+mins + cadence, `UNTIL` date + `No end date` checkbox, Live Preview card, `Delete` & `Save`) + fix `KEEP GOING` borderless text button & clean subtitle (`0/2.5 hours`) in `GoalsCardView` matching Screenshot 1!

### F. Pomodoro System (Phase 4)
1. **Toggl Pomodoro Window / Rich Companion** (*Screenshot 2*): Match Screenshot 2 visually and functionally:
   - `"I'm focusing on..."` button opening a `DETAILS` popover (`Description...` green border, Folder, Tag, `$`, `Save`).
   - Tick-marked ring dial (`Focus` / `25 : 00` / `Ready?`).
   - Prominent `Start session` pill button + Pause / Skip / Reset.
   - `Pomodoro settings ▸` link opening Pomodoro preferences.
   - Option for dedicated floating `Pomodoro` window OR attached popover.
2. **Missing Pomodoro Settings**: Add `autoStartBreaks`, `autoStartFocus`, `countUpMode` (countdown vs count-up), `notificationsEnabled`, and `soundEnabled` toggles.

### G. Calendar & Timeline (Phase 3)
1. **Direct Manipulation**:
   - Double-click (or drag-select) on empty hour slot to create a new entry anchored to that day/time.
   - Drag calendar block vertically (or across columns in Week view) to reschedule with live snap preview.
   - Drag bottom (or top) handle on `CalendarBlockView` to resize duration with snapping.
2. **Snap Interval Setting**: `1`, `5`, `15` (default), or `30` minutes.
3. **Rich Block Styling & Context Menu**: Show `$` billable badge + project color tint (matching Screenshot 7), live running timer block updating every second, and right-click menu (`Continue`, `Duplicate`, `Edit`, `Toggle Billable`, `Delete`).
4. **Local Activity Timeline Strip + Apple Calendar**:
   - Opt-in local app activity strip (when Activity Recording enabled).
   - Optional read-only Apple Calendar (`EventKit`) overlay with safe `NSCalendarsUsageDescription` Info.plist key and permission request; Google/Outlook documented honestly as OAuth-dependent without simulation.

### H. Reports & Exports (Phase 3)
1. **Summary, Detailed & Weekly Subtabs** (*Screenshot 8*):
   - **Summary**: 4 KPI cards + **Stacked Bar Chart (`Duration by Day / Project`)** + Donut Chart (`Slice by: Project/Client/Tag`) + Expandable Hierarchy Breakdown Table (`Project -> Tasks`).
   - **Detailed**: Full searchable/sortable entry audit log table with inline billable & project details.
   - **Weekly**: 7-day Monday–Sunday hours matrix broken down by Project/Client/Tag with daily & row totals.
2. **Full Multi-Filter Toolbar**: Filter by Client, Project, Tag, Billable (`All` / `Billable` / `Non-Billable`), and Description search alongside Date Range stepper (`< This week >`, Today/Yesterday/Week/Last Week/Month/Last Month/Custom).
3. **PDF Export + Enriched CSV/JSON**: Add native PDF summary report export alongside enriched CSV & JSON (including Tags, Billable, Rate, Amount).

### I & J. macOS Integration & Settings (Phase 5)
1. **Floating Mini-Timer (`⇧⌘M`)**: Separate always-on-top compact floating window with Pin button, live timer, description, project dot, Play/Pause/Stop.
2. **Show/Hide Global Shortcut & Menu Bar Enhancements**: Support Show/Hide window shortcut alongside Toggle Timer shortcut, plus optional project & description in `MenuBarLabelView`, Favorites & Recent switchers in `MenuBarPopoverView`, and `Open at Login` (`SMAppService.mainApp`) + `Show Dock Icon` toggle (`NSApp.setActivationPolicy`).
3. **Idle Detection Service**: `CGEventSource.secondsSinceLastEventType` polling while timer runs; interactive Idle Resolution window offering all 4 Toggl options (*Discard idle*, *Discard & continue*, *Add idle as separate entry*, *Keep idle*).
4. **Time-Tracking Reminders**: Scheduled macOS notification reminders (days of week + time window) when no timer is running.
5. **Privacy-First Autotracker & Activity Recorder**: Opt-in `NSWorkspace` frontmost app observer (>10s threshold), app exclusion list, keyword-to-project Autotracker suggestion rules, optional window title note explaining Screen Recording permission, zero keystrokes/screenshots, and 1-click *Disable & Delete Activity Data* button.
6. **Reorganized Settings Experience**: Structured tabs/categories matching Toggl Preferences (`General`, `Timer & Defaults`, `Pomodoro`, `Calendar & Activity`, `Shortcuts`, `Idle & Reminders`, `Autotracker`, `Data & Backups`) with transparent local-profile & future CloudKit readiness info (no fake login/sync).

---

## Phased Execution Plan

| Phase | Scope | Primary Targets |
| :--- | :--- | :--- |
| **Phase 0** | Fix test runner (`--enable-swift-testing --disable-xctest`), convert `QAAuditRunner` into non-`@main` suite or external script, fix **BUG-A** (`PersistenceStore.progress` double-counting), **BUG-B** (`CompactTrackerView` double-counting), **BUG-E** (default `"system"` theme), run all 106+ tests. | `PersistenceStore.swift`, `CompactTrackerView.swift`, `TimeStampApp.swift`, `Tests/` |
| **Phase 1** | **Core Tracking & Compact UI Parity**: Autocomplete popover, `@`/`#` triggers, Inline Manual Mode toggle & stacked vertical buttons, `0:00:00` compact ticker, Undo delete toast, Duplicate entry, Favorite entries, Group similar entries, Entry Search/Billable filter, `⌘N`/`⌘D`/`⌘S`/`⌘O`/`⌘E`/`⌘,` shortcuts, `CapsuleViewSwitcher` dark pill style, `TogglEmptyStateView` crisp vectors. | `ActiveTimerBar.swift`, `EntriesListView.swift`, `TimeEntryRowView.swift`, `CapsuleViewSwitcher.swift`, `TogglEmptyStateView.swift`, `TimeCalculator.swift`, `FavoritesManager`/model support |
| **Phase 2** | **Projects, Clients, Tasks & Tags**: Project `estimatedHours`, `ProjectEditorSheet` & `ClientEditorSheet` rates/billable/estimates, `ProjectRowView` estimate progress bar, `ProjectsListView` client filter, `ProjectPickerPopover` inline tasks + white `"Create project"` label + keyboard navigation, unified picker in `EntryEditSheet` & `MenuBarPopoverView`, dedicated `TagsListView` screen under `MANAGE`, enforce Default Project preference. | `Project.swift`, `ProjectEditorSheet.swift`, `ClientEditorSheet.swift`, `ProjectRowView.swift`, `ProjectsListView.swift`, `ProjectPickerPopover.swift`, `TagsListView.swift`, `AppSidebar.swift` |
| **Phase 3** | **Calendar & Reports**: Calendar double-click to create, drag-to-move, handle resize with snapping, right-click context menu, live running block, `$` indicator, Apple Calendar `EventKit` opt-in overlay (`Info.plist`), Reports `[Summary \| Detailed \| Weekly]` tabs, Stacked Bar Chart, Multi-Filter Toolbar, CSV/JSON billable+tags fields, Native PDF Export. | `CalendarTimelineView.swift`, `DayTimelineGridView.swift`, `WeekTimelineGridView.swift`, `CalendarBlockView.swift`, `CalendarLayoutHelper.swift`, `ReportsView.swift`, `ExportService.swift` |
| **Phase 4** | **Productivity (Goals & Pomodoro)**: `Goal` start/end dates & multi-project IDs, Screenshot 5 Toggl Goal Popover (`GOAL`/`TRACK`/`FOR`/`UNTIL`) + live preview, Screenshot 1 `KEEP GOING` borderless polish, Screenshot 2 Pomodoro floating window/panel (`I'm focusing on...` -> `DETAILS` popover, tick dial, `Start session`, `Pomodoro settings ▸`), auto-start & count-up Pomodoro options, live sound/notification toggles. | `Goal.swift`, `GoalEditorSheet.swift` / `GoalPopoverView`, `GoalsCardView.swift`, `PomodoroManager.swift`, `PomodoroPopoverView.swift`, `PomodoroWindowView.swift` |
| **Phase 5** | **macOS Integration & Advanced Preferences**: Floating Mini-Timer (`⇧⌘M`, always-on-top pin), Menu Bar project/desc display + favorites, Dock icon & Open at Login (`SMAppService`), Idle Detection (`CGEventSource`) + 4-option prompt window, Workday Tracking Reminders, Privacy-first Local Activity Recorder & Autotracker rules, reorganized Preferences UI. | `FloatingMiniTimerView.swift`, `IdleDetectionManager.swift`, `ReminderManager.swift`, `ActivityTrackerManager.swift`, `SettingsView.swift`, `MenuBarPopoverView.swift` |
| **Phase 6** | **Final Verification & Release**: Run full `swift test --enable-swift-testing --disable-xctest` (including all new unit & integration tests), build release `.app` (`swift build -c release`), codesign, launch & visually test Light/Dark/System themes + interactions via live GUI screenshots, verify `replica/features.csv` & `parity.py` & `imgdiff.py`, confirm zero production data loss. | All targets & `replica/` docs |
