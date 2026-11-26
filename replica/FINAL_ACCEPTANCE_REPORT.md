# TimeStamp — Final Release Acceptance Testing Report

**Date:** 2026-11-26  
**Target Platform:** macOS 14.0+ Apple Silicon (`arm64e-apple-macos14.0`)  
**Release Artifact:** `TimeStamp.app` (Mach-O 64-bit `arm64`, 12 MB, Bundle ID `com.timestamp.desktop`)  
**Verdict:** **Conditional Release Readiness (Local Personal Beta)** — All 129 automated tests across 25 suites pass after a clean build (`exit code 0`), release binary launches and persists without crash, and isolated fresh install starts with zero records; **14+ live desktop UI, TCC permission, global shortcut, notification, and physical mouse-gesture interactions remain pending manual macOS desktop sign-off.**

---

## 1. Clean Build & Automated Test Suite Verification

### Execution Command
```bash
swift package clean && ./scripts/run-qa-tests.sh
```

> **Test Runner Note:** Command Line Tools on this host omits CLI `xctest` (`xcrun -f xctest` exits 72). Consequently, `./scripts/run-qa-tests.sh` compiles the `TimeStamp` and `TimeStampTests` modules via `swift test --enable-swift-testing --disable-xctest`, links all compiled `.o` objects against Swift Testing's `__swiftPMEntryPoint()` into `.build/all_tests_runner`, and executes every `@Test` natively without skipping any suite.

### Observed Clean Build & Run Output (Verbatim Summary)
- **Clean Build Time:** `Build complete! (57.77s)` (compiling `99` `TimeStamp` targets and `127` `TimeStampTests` / runner steps cleanly with zero compiler errors)
- **Test Execution Result:** **`Test run with 129 tests in 25 suites passed after 0.079 seconds.`**
- **Exit Code:** `0` (`CLEAN_QA_EXIT_CODE=0`)
- **Failed Tests:** `0`
- **Skipped Tests:** `0`

#### Suite Breakdown (All 25 Suites Observed Passing)
1. `Timer Engine & Drift-Free Math Tests`
2. `Entry Editing, Manual Logging, and Synchronization Tests`
3. `DateHelper & Daily Grouping Tests`
4. `Project and Task Management Tests`
5. `Client Management and Entry Filtering Tests`
6. `Dashboard Metrics & Productivity Tests`
7. `Reports Analytics & Data Export Tests`
8. `Calendar Layout & Overlap Clustering Tests`
9. `Calendar Timeline Navigation & Aggregation Tests`
10. `MenuBar Companion and Ticker Tests`
11. `Global System Hotkey Tests`
12. `Settings & Preferences Tests`
13. `Domain Model & PersistenceStore Tests`
14. `GoalEngineTests`
15. `PomodoroEngineTests`
16. `Priority 3: Billable Tracking & Tags Engine Tests`
17. `Goals Engine & Storage Integrity Repair Tests`
18. `End-to-End System Tests: Complete v1.0 User Journey`
19. `QA Audit Integration Tests`
20. `TogglReplicaTests`
21. `Phase 1: Core Tracking UX, Autocomplete, Grouping & Favorites Tests` (`7` tests)
22. `Phase 2: Projects, Clients, Tasks & Tags Parity Tests` (`4` tests)
23. `Phase 3: Interactive Calendar & Multi-View Reports Tests` (`3` tests)
24. `Phase 4: Goals Multi-Project & Date Bounds + Pomodoro Parity Tests` (`3` tests)
25. `Phase 5: Idle Detection, Workday Reminders & Activity Recorder Tests` (`3` tests)

*Verification Caveat:* `Phase 1–5` automated tests validate models, state transitions, persistence, goal math, Pomodoro state machine, CSV/JSON/PDF export bytes, calendar geometry/snapping math, and mocked idle/activity logic in isolation (`PersistenceStore(inMemory: true)`). Live SwiftUI pointer clicks, keyboard focus popovers, `DragGesture` manipulation, TCC prompts, `SMAppService` registration, and multi-app Carbon hotkeys are not exercised inside headless Swift Testing runs.

---

## 2. Feature Matrix Audit & Parity Score Explanation (`replica/features.csv`)

### How the Prior `100.0 / 100` Score Was Calculated
Inspecting `.agents/skills/replica-diff/parity.py` reveals the exact scoring math:
- **Weights (`WEIGHT`):** `must = 3`, `should = 2`, `could = 1`
- **Credits (`CREDIT`):** `yes` / `done` = `1.0`, `partial` = `0.5`, `no` = `0.0`
- **Formula:** `feature_score = 100.0 * sum(weight * credit) / sum(weight)` over rows where `original != "no"` and `clone != "skip"`. `--visual` layout scores were omitted unless explicitly passed.
- **Why `100.0 / 100` Overstated Parity:**
  1. `replica/features.csv` originally contained only **37 counted local-desktop scope rows** (+ `1` `original=no` convenience row). It did **not** score Toggl cloud authentication, cross-device sync, teams, approvals, invoicing, XLSX export, OAuth calendars, or web profitability reports.
  2. Several rows requiring physical macOS permissions or unverified runtime UI triggers (Apple Calendar `EventKit`, cross-app `⌥⇧T`, floating Mini-Timer z-order, live HID Idle sheet, live Notification banners, live `NSWorkspace` polling) were prematurely marked `clone = yes` / `Complete` before interactive desktop testing.

### Post-Acceptance Feature Matrix Revision (`replica/features.csv`)
In accordance with strict acceptance standards (*"Do not mark untested features complete"*), untested runtime OS/UI/TCC rows in `replica/features.csv` were downgraded to `clone = partial`, `"Verified"` claims for unclicked UI interactions were updated to `"Pending Interactive QA"`, and excluded Toggl cloud/team features were added explicitly with `clone = skip`.

Running `python3 .agents/skills/replica-diff/parity.py replica/features.csv --markdown` now reports honestly:
- **Weighted Desktop Scope Score:** **`83.5 / 100`** (`37` counted features)
- **Must-Haves Completed (`clone = yes`):** **`19 of 27`** (`8` must-have features downgraded to `partial` pending live macOS GUI/OS/TCC verification)
- **Extra Local Convenience (`original = no`):** Pause & resume timer (`1` feature, excluded from parity score)
- **Explicitly Excluded SaaS / Cloud / Privacy Scope (`clone = skip`, `7` features):** Excluded cleanly from denominator and enumerated in Section 3.

#### Weakest Areas by Parity Score
| Area | Counted Features | Parity Score | Reason Not `100.0` |
| :--- | :---: | :---: | :--- |
| `shortcuts` | 1 | `50.0` | Cross-app hotkey & SwiftUI `.commands` unverified interactively |
| `calendar` | 2 | `50.0` | Live `DragGesture`/double-click & EventKit TCC prompt unverified |
| `system` | 5 | `50.0` | Live Mini-Timer pin, Menu Bar popover, CGEventSource wait, OS notification banner & NSWorkspace polling unverified |
| `settings` | 1 | `50.0` | Live Dock toggle (`NSApp.setActivationPolicy`) & `SMAppService` approval unverified |
| `reports` | 2 | `75.0` | Detailed & Weekly tabs compiled but not visually or interactively verified live |
| `timer` | 10 | `85.2` | Autocomplete live popover, `@`/`#` key triggers, & inline manual mode bar unverified live |
| `entries`, `window`, `projects`, `clients`, `tags`, `goals`, `pomodoro`, `export`, `data` | 16 | `100.0` | Logic unit-tested & key dark/light screens visually inspected offscreen; live clicks still listed in Section 4 checklist |

---

## 3. Unsupported & Excluded Toggl Track Features

The following Toggl Track platform features are **unsupported** or **intentionally excluded** in this offline native macOS build:
1. **Cloud Authentication & Cross-Device Sync:** No Toggl Track server login, SSO, API token sync, or provisioned Apple CloudKit container (offline atomic JSON store only).
2. **Multi-User Workspaces, Teams, Roles & Timesheet Approvals:** Single-user local workspace only; no member invitations, team management, or supervisor approvals.
3. **Google Calendar & Microsoft Outlook OAuth Sync:** Not implemented because external OAuth client secrets/backends are required. Local read-only Apple Calendar (`EventKit`) overlay substitutes for subscribed macOS calendars.
4. **Workload, Profitability & Saved/Shared Web Reports:** Only `Summary`, `Detailed`, and `Weekly` reports are implemented.
5. **Client Invoicing & XLSX Spreadsheet Exports:** Supports RFC 4180 CSV (including Tags, Billable, Rate, Amount), structured JSON, and CoreGraphics native PDF exports only.
6. **Window Titles & URL Capture in Activity Timeline:** Omitted intentionally (`ActivityTrackerManager` records frontmost `NSWorkspace` application names > 10s only) to avoid requiring intrusive Accessibility or Screen Recording permissions.
7. **Browser Extensions & External SaaS Integrations:** No Jira, Linear, Asana, GitHub, Chrome, or Firefox extensions.

---

## 4. Release Build & Runtime Launch Verification

1. **Bundle Verification:**
   - Executable: `TimeStamp.app/Contents/MacOS/TimeStamp` (`Mach-O 64-bit executable arm64`, `12M`, built via `swift build -c release` in `33.58s`).
   - Manifest: `TimeStamp.app/Contents/Info.plist` (`1.4K`, contains `NSCalendarsUsageDescription` and `NSCalendarsFullAccessUsageDescription`).
2. **Code Signing Check (`codesign --verify --deep --strict --verbose=2 TimeStamp.app`):**
   - `TimeStamp.app: valid on disk`
   - `TimeStamp.app: satisfies its Designated Requirement`
   - `Signature=adhoc`, `TeamIdentifier=not set`, `Identifier=com.timestamp.desktop`, `Format=app bundle with Mach-O thin (arm64)`.
3. **Direct Binary Launch & Runtime Diagnostics:**
   - Launched `./TimeStamp.app/Contents/MacOS/TimeStamp` directly and monitored for 4 seconds (`LAUNCH_STATUS=RUNNING pid=52769`).
   - Observed stdout/stderr console output: empty (`0` runtime errors, `0` failed JSON decode warnings after Phase 6 `Goal` enum compatibility fix).
   - Observed crash logs in `~/Library/Logs/DiagnosticReports/`: zero crash reports generated after the final `15:53`/`15:58` rebuilds (earlier `15:51` and `15:53` `.ips` logs predate the `SystemIntegrationManager.applyDockIconPolicy()` `NSApp` guard and were fixed cleanly).
   - Observed live memory (`ps -o rss=`): **`139,920 KB` (~136.6 MB RSS)** during initial active AppKit launch (`125–132 MB` RSS measured in prior 3s launch checks — notably higher than the `<40 MB` aspirational constraint in `.planning/PROJECT.md` because SwiftUI + Swift Charts + Metal layer caches allocate shared framework memory eagerly).

---

## 5. Interactive macOS User Verification Checklist

> **How to read this table:** Column **"Automated / Render Coverage"** states strictly what was proven without manual clicks; **"Manual macOS QA"** defines the physical verification step required from you.

| # | Area | Automated / Offscreen Coverage Verified | Manual macOS Action & Permission Needed | Pass? |
| :--- | :--- | :--- | :--- | :---: |
| 1 | **Timer start, pause, stop & resume** | `TimerTests` verifies start/stop/pause/resume/duration math & zero overlap | Click Play/Pause/Stop in Compact UI & confirm 1s live tick + state transitions | [ ] |
| 2 | **Manual time entry** | `EntryEditTests` verifies start/end/duration persistence & editing | Press `⌘D` (or `+` toggle), type duration/range in bar, press Return | [ ] |
| 3 | **Project & task creation** | `ProjectManagementTests`, `Phase2ProjectsTagsTests`, `project_picker_dark.png` | Open Project Picker -> `+ Create project`, add inline Task, expand tasks in picker | [ ] |
| 4 | **Tag creation & selection** | `BillableAndTagsTests`, `Phase2ProjectsTagsTests` verify CRUD, rename, cascade | Type `#` in description bar + open Sidebar -> `Tags` to create/rename/delete tags | [ ] |
| 5 | **Billable tracking** | `BillableAndTagsTests`, `Phase3CalendarReportsTests`, `reports_summary_dark.png` | Toggle `$` in timer bar, edit entry billable state, verify `$` rate totals in Reports | [ ] |
| 6 | **Goal creation & Keep Going** | `GoalEngineTests`, `Phase4GoalsPomodoroTests`, `goal_popover_dark.png`, `compact_dark.png` | Open `+` Goal popover, pick multiple projects + `UNTIL` date, save, click `KEEP GOING` | [ ] |
| 7 | **Pomodoro countdown & transitions** | `PomodoroEngineTests`, `Phase4GoalsPomodoroTests`, `pomodoro_window_dark.png` | Click 🍅, set `"I'm focusing on..."` Details, click `Window` pop-out, complete 1m test cycle | [ ] |
| 8 | **Calendar editing & drag-and-drop** | `CalendarLayoutTests`, `Phase3CalendarReportsTests`, `calendar_week_dark.png` | Double-click slot to create, drag block move & bottom handle resize, click `Apple Cal` & **grant Calendar TCC** | [ ] |
| 9 | **Reports & exports** | `ReportsAndExportTests`, `Phase3CalendarReportsTests`, `reports_summary_dark.png` | Switch `[Summary | Detailed | Weekly]`, test filters, export CSV/JSON/PDF via macOS Save panel | [ ] |
| 10 | **Menu bar controls** | `MenuBarCompanionTests` verifies ticker formatting strings | Click macOS status bar item, verify ticker + project name + Favorites quick resume + `Mini-Timer` | [ ] |
| 11 | **Floating mini-timer** | `mini_timer_dark.png` offscreen visual render verified | Press `⇧⌘M`, test always-on-top pin across Spaces/windows & stop button | [ ] |
| 12 | **Global shortcuts** | `GlobalHotkeyTests` verifies hotkey registration API lifecycle | Focus Safari/Xcode and press `⌥⇧T` to confirm global start/stop without Accessibility permission; test `⌘N/D/S/O/E/,` | [ ] |
| 13 | **Notifications** | CLI bundle guard tested safely | Grant **macOS Notification Permission** in System Settings & verify Pomodoro/Workday banners + alert sound | [ ] |
| 14 | **Idle detection** | `Phase5SystemIntegrationTests` verifies all 4 resolution paths cleanly | Set Idle Threshold to `1 min` in Settings, start timer, leave Mac untouched 60s, test all 4 sheet buttons | [ ] |
| 15 | **Light & dark modes** | `SettingsTests`, `compact_dark.png`, `compact_light.png` verified | Set Appearance = `System`, toggle macOS System Appearance Light ↔ Dark while app is open | [ ] |
| 16 | **Restart & persistence** | `QAAuditRunner` & `verify_fresh_install.swift` isolated disk check verified | Start/complete an entry & edit a goal in `TimeStamp.app`, quit (`⌘Q`), relaunch and confirm intact state | [ ] |

---

## 6. Data Integrity Verification

### Production Database Protection
- **Target Path:** `~/Library/Application Support/TimeStamp/timestamp_store.json`
- **SHA-256 Before Test Suite + Isolated Fresh-Install Run:**  
  `c61d76afe54cad191ae58f510f55145be40039c7df1f97d375ee454cafca4f75`
- **SHA-256 Immediately After Full QA Run + Isolated Sandbox Test:**  
  `c61d76afe54cad191ae58f510f55145be40039c7df1f97d375ee454cafca4f75` (**Byte-for-byte identical, `PROD_DB_UNCHANGED=YES`**)
- **Current Production Counts Verified:** `40 timeEntries`, `1 goal` (`Research`), `2 projects` (`Eng`, `Research`), `4 clients`, `4 tags`, `1 task`. *(Note: 3 empty manual 30-min entries on project `Research` were recorded at `16:06:43–16:06:49` prior to the isolated QA run when desktop state saved manually; zero records were deleted or reset.)*
- **Existing Backup Preserved:** `~/Library/Application Support/TimeStamp/backups/timestamp_store_backup_20261124_165721.json` (`14,852 bytes`).

### Isolated Fresh-Install Verification
Verified by executing standalone binary `verify_fresh_install` against an empty sandbox directory (`scratch/fresh_install_sandbox`) using `PersistenceStore(inMemory: false, storageDirectory: sandboxDir)`:
- Initial load counts: `timeEntries=0 projects=0 clients=0 tasks=0 tags=0 goals=0` (zero seeded sample goals or entries).
- Write + clean re-instantiation persistence check: `timeEntries=1 projects=1 clients=0 goals=0` (`FRESH_INSTALL_VERIFICATION=PASSED`).

---

## 7. Visual Quality & Reference Comparison

Every rendered screenshot in `replica/output/screenshots/` was visually inspected against the reference captures in `replica/screens/`. *(No synthetic visual similarity percentage is invented; structural differences are reported directly below.)*

> **Capture Method Note:** Cross-process `screencapture -l <windowID>` failed on this headless CLI session (`could not create image from window`) because macOS Screen Recording TCC blocks unpermitted terminal capture. All verification PNGs below were rendered directly in-process via AppKit `NSHostingView` + `NSBitmapImageRep` using `NSAppearance` `.darkAqua` / `.aqua` on an in-memory store.

| TimeStamp Screen | Toggl Reference | Layout, Typography, Spacing, Color & Interaction Findings |
| :--- | :--- | :--- |
| [compact_dark.png](file:///Users/jahirunhassanrimon/My%20Projects/personal/TimeStamp/replica/output/screenshots/compact_dark.png) & [compact_light.png](file:///Users/jahirunhassanrimon/My%20Projects/personal/TimeStamp/replica/output/screenshots/compact_light.png) | `toggl_macos_main_empty.jpg`, `toggl_desktop_main.jpg`, `toggl_desktop_entries_dark_light.jpg` | **Matches closely:** Dark `#14101A` / card `#1B1525` & warm light `#FDFBFA` backgrounds, tomato trigger, `0:00:00` tabular clock, magenta `#E54583` Play CTA + vertical Play/`+` circles, capsule pill `[ List | Calendar ]`, borderless `KEEP GOING`, and vector hands/laptop spotlight empty state render sharply with strong Light/Dark contrast. **Differences:** Header link reads `EXPAND TO WORKSPACE ↗` (instead of `EXPLORE ON WEB APP ↗`), goal rows show an extra detail subtitle (`0m / At least 2h 30m (Daily)`), and the Goals `+` button lacks Toggl's outer circular border. |
| [pomodoro_window_dark.png](file:///Users/jahirunhassanrimon/My%20Projects/personal/TimeStamp/replica/output/screenshots/pomodoro_window_dark.png) | `toggl_macos_pomodoro_window.jpg` | **Matches closely:** Edge-to-edge card background, `"I'm focusing on..."` rounded button, 60 radial dial ticks, large centered `25:00` + `"Ready?"`, full-width magenta `"Start session"`, and `"Pomodoro settings >"` disclosure match Toggl's hierarchy cleanly. **Differences:** Header reads `"Focus Session"` instead of `"Focus"`, idle outer ring renders dimmed (`0.20` alpha) until started rather than Toggl's solid magenta ready ring, and window title bar is only shown inside the popped-out `Window("Pomodoro")`. |
| [goal_popover_dark.png](file:///Users/jahirunhassanrimon/My%20Projects/personal/TimeStamp/replica/output/screenshots/goal_popover_dark.png) | `toggl_macos_goal_popover.jpg` | **Matches closely:** Emerald `#36B37E` focus border on goal name, compact icon selector dropdown, `TRACK` `[ 📁 ] [ 🏷 ]`, `FOR` `[ at least ⌄ ] [ 1 ] hours [ every day ⌄ ]`, `UNTIL No end date` with checkbox, and `Save` CTA. **Differences:** Includes `Any Client` picker, `All entries` picker, and a `LIVE PROGRESS PREVIEW` card beneath `UNTIL`, making the sheet slightly taller (`590pt`). |
| [project_picker_dark.png](file:///Users/jahirunhassanrimon/My%20Projects/personal/TimeStamp/replica/output/screenshots/project_picker_dark.png) | `toggl_macos_project_picker.jpg` | **Matches closely:** Emerald-green search field border, `• No Project`, uppercase Client headers, colored dots, pink checkmark, and sticky bottom bar with magenta `+` + primary white `"Create project"`. **Difference:** Minor row padding is slightly taller than Toggl's ultra-dense list. |
| [reports_summary_dark.png](file:///Users/jahirunhassanrimon/My%20Projects/personal/TimeStamp/replica/output/screenshots/reports_summary_dark.png) | `toggl_web_reports_populated.jpg`, `toggl_web_reports_view.jpg` | **Comparable Structure:** `[Summary | Detailed | Weekly]`, `< This Week >`, `Export` menu, filter controls, 4 KPI cards (`10:00:00`, `6:00:00`, `60%`, `$750.00`), stacked `DURATION BY DAY & PROJECT`, central donut chart, and expandable `PROJECT & TASK BREAKDOWN` render cleanly with clear spacing. **Differences:** Dark desktop palette vs Toggl Web light paper screenshot; omits Toggl Web Member/Rounding/Profitability/Workload tabs and `Save and share` cloud button. |
| [calendar_week_dark.png](file:///Users/jahirunhassanrimon/My%20Projects/personal/TimeStamp/replica/output/screenshots/calendar_week_dark.png) | `toggl_web_calendar_view.jpg` | **Visual Issue Caught & Fixed:** Fixed an initial greedy `Color.clear` spacer in `WeekTimelineGridView` that pushed the `MON–SUN` header downward; fixed grid now renders compact sticky weekday headers, `$` billable pills, translucent project-colored blocks, current-time magenta indicator line, snap selector (`15m snap`), and `Apple Cal` toggle. **Differences:** Darker grid theme vs Web white theme, and does not sync cloud OAuth calendars. |
| [mini_timer_dark.png](file:///Users/jahirunhassanrimon/My%20Projects/personal/TimeStamp/replica/output/screenshots/mini_timer_dark.png) | Toggl Mini-Timer companion | Clean 380×54 horizontal bar with description field, `0:00:00` ticker, magenta Play CTA, and Pin toggle rendered cleanly. |
| **Unrendered Screens (Visual Coverage Gap)** | `toggl_macos_autocomplete.jpg`, `toggl_web_projects_table.jpg`, Settings | **Not captured in PNG screenshots:** Live `AutocompletePopoverView`, populated `EntriesListView`, Reports `Detailed` & `Weekly` tabs, `TagsListView`, `ProjectsListView`, `IdleResolutionSheet`, and multi-tab `SettingsView` were compiled cleanly in the build target without dedicated visual PNG snapshots. |

---

## 8. Known Limitations

1. **Ad-hoc Signing & Login Item Approval:** `TimeStamp.app` is ad-hoc signed without an Apple Developer ID certificate or notarization, so `SMAppService.mainApp` Login Item registration may require explicit approval in `System Settings > General > Login Items` and Gatekeeper bypass on other Macs.
2. **Memory Footprint vs `<40 MB` Design Goal:** Live `ps -o rss=` measured `~125–140 MB` RSS in SwiftUI + Swift Charts desktop launches (`139,920 KB` direct launch RSS).
3. **TCC Permissions Required at Runtime:** Calendar overlay (`NSCalendarsUsageDescription`) and macOS Notification banners depend on user grants inside `TimeStamp.app`; Activity Timeline intentionally skips Accessibility / Screen Recording window-title capture.
4. **Offline-Only Architecture:** No remote Toggl account authentication, multi-user approvals, XLSX export, or cloud sync.

---

## 9. Release Readiness Assessment

- **Unit & Integration Stability:** **GO** — `129 / 129` tests across `25` suites pass cleanly (`0.079s`, `exit code 0`), release build succeeds (`33.58s`), binary launches with zero crashes/errors, and data-safety/fresh-install guarantees are proven with SHA-256 verification.
- **Interactive Desktop Parity & Permissions:** **CONDITIONAL HOLD FOR MANUAL QA** — User verification of the 16-item Interactive macOS Checklist (especially notifications, `⌥⇧T` cross-app hotkey, live `DragGesture` calendar editing, Apple Calendar `EventKit` prompt, Dock icon toggle, `SMAppService`, and visual inspection of `Detailed`/`Weekly` Reports & `AutocompletePopoverView`) is required before declaring final production sign-off.
