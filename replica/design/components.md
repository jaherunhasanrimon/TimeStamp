# TimeStamp — Component Specifications (Parity Complete)

Reference designs: `replica/screens/toggl_macos_main_empty.jpg`, `toggl_macos_pomodoro_window.jpg`, `toggl_macos_project_picker.jpg`, `toggl_macos_autocomplete.jpg`, `toggl_macos_goal_popover.jpg`, and `replica/design/tokens.json`.

## 1. Compact & Workspace Active Timer Bar (`ActiveTimerBar`)
- **Left**: Tomato Pomodoro trigger button (`32x32` circular pill -> `PomodoroPopoverView` & standalone window pop-out).
- **Center**: Single-line `"What are you working on?"` input (`AutocompletePopoverView` opens dynamically on text or `@`/`#`; keyboard `↑`/`↓`/`Return`/`Esc` supported). In manual mode (`⌘D`), inline `[ Start -> End | Duration ]` quick entry replaces timer ticker.
- **Action Row**: Project pill (`ProjectPickerPopover`), Tag `#` pill (`TagPickerPopover`), Billable `$` toggle pill, Favorites quick-resume menu, active running entry Quick Edit button (`⌘E`).
- **Right Controls**:
  - Live tabular `0:00:00` (`TimeCalculator.formatCompactDuration`)
  - Primary circular Play (`AppColors.togglMagenta`) / Stop (`AppColors.destructive`) CTA
  - Vertical stacked mode toggles: `[ ▶ Timer | + Manual ]`

## 2. Project Picker (`ProjectPickerPopover` & `ProjectTaskPickerButton`)
- Emerald-green focus-bordered search input (`AppColors.focusBorder`, auto-focused).
- `• No Project` clear selection row.
- Client-grouped active project sections (`NO CLIENT`, `<CLIENT>` uppercase headers) automatically excluding archived projects.
- Expandable active Tasks under projects (`>` chevron toggle or auto-expanded when search matches task name).
- Keyboard navigation (`↑`/`↓`/`Return`/`Esc`).
- Sticky bottom bar: magenta `+` icon with primary-colored `"Create project"` label (`ProjectEditorSheet`).

## 3. Capsule View Switcher & Empty State (`CapsuleViewSwitcher`, `TogglEmptyStateView`)
- Rounded capsule track (`AppColors.capsuleTrack`) with elevated active pill thumb (`AppColors.capsuleActiveThumb`): `[ List | Calendar ]`.
- Crisp vector illustration (`Path`/`RoundedRectangle` laptop with magenta center badge and hands) inside white spotlight circle cleanly centered above `"Let's get tracking!"`.

## 4. Goal Card & Goal Editor Popover (`GoalsCardView`, `GoalEditorSheet`)
- Collapsible card header `Goals (completed/total)` with `+` add and collapse chevron (zero 4-goal artificial paywall).
- Per-goal circular badge progress ring gradient (`goalGold` / `success` / `destructive`) + borderless `KEEP GOING` / `TRACKING` / `COMPLETED` / `OVER LIMIT` action.
- `GoalEditorSheet` matches Toggl `GOAL` popover layout: emerald-bordered title + circular Icon dropdown, `TRACK` multi-project picker + Tags + Client + Billable filter, `FOR` (`at least` / `less than` + decimal hours + `every day` / `every weekday` / `every week`), `UNTIL` (`No end date` checkbox + date picker), Live Preview card, `Delete`, and `Save`.

## 5. Pomodoro Panel & Window (`PomodoroPopoverView`)
- `"I'm focusing on..."` button opening `"DETAILS"` popover (`Description...`, Project picker, Tag picker, `$` Billable toggle, `Save`).
- 60-tick circular radial dial with outer phase progress stroke (`togglMagenta` work / `billable` break), tabular countdown or count-up timer, `"Start session"` CTA, Pause/Skip/Reset controls, `"Pomodoro settings ▸"` inline drawer, and pop-out standalone `"Pomodoro"` window.

## 6. Interactive Calendar (`CalendarTimelineView`, `DayTimelineGridView`, `WeekTimelineGridView`, `CalendarBlockView`)
- Fixed compact weekday header + 24-hour grid (`1/5/15/30m` configurable snap), double-click empty slot creation (`CalendarQuickCreateSheet`), block drag-to-move, top/bottom resize handles, `$` billable badge, live running block, right-click context menu, and opt-in EventKit Apple Calendar dashed overlay.

## 7. Multi-View Reports & Exports (`ReportsView`, `ExportService`)
- `[Summary | Detailed | Weekly]` tabs with `< Period >` stepper, Client/Project/Tag/Billable/Description filters, 4 KPIs, Stacked Daily Bar (`ReportsDailyBarChartView`), Donut (`ReportsDonutChartView`), Project->Task Hierarchy (`ReportsHierarchyView`), Detailed Table (`ReportsDetailedTableView`), Mon–Sun Matrix (`ReportsWeeklyMatrixView`), CSV/JSON with tags & billable math, and native CoreGraphics vector PDF export.

## 8. Companion Windows & macOS Settings
- **Floating Mini-Timer** (`FloatingMiniTimerView`, `⇧⌘M`) with `NSWindow.Level.floating` pin toggle.
- **Menu Bar Extra** (`MenuBarLabelView`, `MenuBarPopoverView`) with optional project/description suffix, Favorites quick-start, Pomodoro ticker, and Mini-Timer launcher.
- **Idle Resolution Sheet** (`IdleDetectionManager` via CoreGraphics HID `CGEventSource`) + **Workday Reminders** (`ReminderManager`) + **Opt-in Local Activity Recorder & Autotracker** (`ActivityTrackerManager`) + 6-tab **Settings** (`SettingsView`).
