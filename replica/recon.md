# Recon Map: Toggl Track (macOS Desktop & Web Companion)

**Scope:** Complete macOS Desktop App & Companion Workspace Parity for **TimeStamp**  
**Date:** 2026-11-26  
**Reference Screenshots:** `replica/screens/` (13 high-resolution screenshots covering both Toggl Track macOS Desktop and Web companion)

---

## Sources

| # | Source | Evidence File | Key Takeaways |
|---|---|---|---|
| 1 | macOS Compact Main | `toggl_macos_main_empty.jpg` | Top timer bar (Pomodoro circle `🍅`, `"What are you working on?"`, `0:00:00`, `#E54583` circular play, vertical Timer/`+` Manual toggles, Row 2 Folder/Tag/`$`); capsule `[ List | Calendar ]` switcher; `TODAY TOTAL 0:00:00`; `Goals` card (`0/2.5 hours`, `KEEP GOING`); white spotlight laptop illustration. |
| 2 | macOS Pomodoro + Details | `toggl_macos_pomodoro_window.jpg` | Dedicated `Pomodoro` floating panel (`"I'm focusing on..."` button opening `DETAILS` popover with `#36B37E` green input + Folder/Tag/`$` + `Save`; tick-marked `#E54583` ring showing `Focus`, `25 : 00`, `Ready?`; `Start session`; `Pomodoro settings ▸`). |
| 3 | macOS Project Picker | `toggl_macos_project_picker.jpg` | `Search by project, task or client` green-bordered field; `• No Project` highlighted pill; `NO CLIENT` & client sections; project dots; sticky `+ Create project` (magenta `+`, primary label). |
| 4 | macOS Autocomplete | `toggl_macos_autocomplete.jpg` | Live dropdown under description field showing `PROJECTS` (and entries) with highlighted matching characters, project colors, and ` · ClientName`. |
| 5 | macOS Goal Popover | `toggl_macos_goal_popover.jpg` | `GOAL` popover (`x` close, green-bordered title + icon selector, `TRACK` folder + tag, `FOR` `[at least]` `[2.5]` `hours` `[every day]`, `UNTIL` date + `[✓] No end date`, note, `Delete`, `Save`); main bar shows selected project pill (`• Study Until She Reply.......`). |
| 6 | Desktop Dark vs Light | `toggl_desktop_entries_dark_light.jpg` | Side-by-side Dark Plum (`#14101A`) & Light Cream (`#FDFBFA`) day-grouped entries (`Today 4 h 15 min ^`, project dot + client, `$` billable, `04:15:00`, hover play). |
| 7-13 | Web Companion | `toggl_web_*.jpg` | Sidebar (`TRACK`, `ANALYZE`, `MANAGE`, `ADMIN`), Summary Report (4 KPIs, Stacked Bar Chart, Donut Chart, Expandable Breakdown, PDF/CSV Export), Calendar Week Grid, Projects Table. |

---

## Core Loop
Frictionless one-click or keyboard-driven time capture (`⌘N` / `⌥⇧T` / `Space` / Click) with autocomplete project/tag attachment, instant visual verification in List & Calendar, Pomodoro & Goal guidance, and accurate local Analytics/Exports.

---

## Complete Screen Inventory (15 Screens)

| ID | Screen / Component | How to Reach | Purpose | Key Components | States |
|---|---|---|---|---|---|
| **S01** | **Timer & Entries (Full Workspace)** | Sidebar: `Timer & Entries` | Primary full-width tracking + chronological log | Sticky `ActiveTimerBar`, Search/Filter bar, Favorite strip, Day groups (`DayGroupHeaderView`), `TimeEntryRowView` (grouped or ungrouped), Undo delete toast | Empty, Running, Paused, Manual Mode, Populated, Filtered, Grouped |
| **S02** | **Compact Tracker Window** | Default compact mode / Toggle from sidebar | Focused 440px Toggl Desktop window | `ActiveTimerBar`, `CapsuleViewSwitcher [List \| Calendar]`, `TODAY TOTAL`, `GoalsCardView`, `EntriesListView` / `CalendarTimelineView`, `TogglEmptyStateView` | Empty, Populated, List, Calendar, Running, Dark/Light |
| **S03** | **Dashboard Overview** | Sidebar: `Dashboard` | Daily & weekly executive productivity summary | `DailyProgressCardView` (ring + target), `WeeklyActivityChartView` (7-day stacked bar), `RecentActivityListView` (one-click continue) | Empty (binoculars), Populated, Live Timer Updating |
| **S04** | **Calendar Timeline** | Sidebar: `Calendar` or Switcher: `Calendar` | Interactive 24h Day/Week schedule grid | `CalendarTimelineView` toolbar (`Day\|Week`, `< Today >`, snap picker, Apple Calendar overlay toggle), `DayTimelineGridView`, `WeekTimelineGridView`, interactive `CalendarBlockView` | Empty, Populated, Dragging, Resizing, Double-click Create, Live Active Block |
| **S05** | **Projects Management** | Sidebar: `Projects` | Create, edit, archive, rate, estimate, and inspect projects | Search bar, `[Active \| Archived]` filter, Client filter, `+ New Project`, `ProjectRowView` (tasks, rate, estimate progress bar) | Empty, Active, Archived, Filtered, Expanded Tasks |
| **S06** | **Clients Management** | Sidebar: `Clients` | Manage clients, currencies, hourly rates, and linked projects | Search bar, `+ New Client`, `ClientRowView` (project count, tracked time, rate), `ClientEditorSheet` | Empty, Populated, Edit |
| **S07** | **Tags Management** | Sidebar: `Tags` | Bulk create, rename, recolor, and safely delete tags | Search bar, `+ New Tag`, Tag list with entry usage count & color swatch | Empty, Populated, Editing |
| **S08** | **Reports & Analytics** | Sidebar: `Reports` | Multi-tab productivity & revenue reporting | Subtabs `[Summary \| Detailed \| Weekly]`, Date range stepper + presets, Filter pills (`Client`, `Project`, `Tag`, `Billable`, `Description`), 4 KPI cards, Bar Chart, Donut Chart, Breakdown Table, Detailed Table, Weekly Matrix, Export Menu (`CSV`, `JSON`, `PDF`) | Empty (`Nothing to see here...`), Summary, Detailed, Weekly, Filtered |
| **S09** | **Settings & Preferences** | Sidebar: `Settings` or `⌘,` | Organized macOS preferences & local data tools | Tabbed/Grouped sections: General (Theme, Dock icon, Open at login), Timer & Defaults, Pomodoro, Calendar & Activity/Timeline, Shortcuts (`⌥⇧T` + recorder), Idle & Reminders, Autotracker Rules, Data & Backups | Default, Recording Shortcut, Permission Prompted, Backup Confirmed |
| **S10** | **Pomodoro Window & Companion** | Click 🍅 icon or Menu `Window -> Pomodoro` | Authentic Toggl Pomodoro focus/break timer | `"I'm focusing on..."` button -> `DETAILS` popover, tick-marked circular progress dial, `Focus / 25:00 / Ready?`, `Start session` / Pause / Skip / Reset, cycle dots, `Pomodoro settings ▸` | Idle, Focus Running, Paused, Short Break, Long Break |
| **S11** | **Goal Creation & Editing** | `+` or edit click on `GoalsCardView` | Configure personal tracking targets | Popover/Sheet (`GOAL` title + icon picker, `TRACK` multi-project / client / tag / billable filters, `FOR` target type `at least/less than` + hours + cadence `daily/weekdays/weekly`, `UNTIL` start & optional end date, Live Preview, `Delete`, `Save`) | Create, Edit, Over Limit Preview, Completed Preview |
| **S12** | **Project & Task Picker** | Click Folder icon or type `@` | Fuzzy search & select project/task/client | `#36B37E` search input, `• No Project`, `NO CLIENT` & client sections, color dots, nested task disclosure, sticky `+ Create project` | Unfiltered, Filtered, No Matches, Inline Create |
| **S13** | **Tag Picker Popover** | Click Tag icon or type `#` | Multi-select, search, create, delete tags | Dynamic inset search field, `+ Create tag "..."`, checkmark rows, delete action | Empty, Multi-selected, Search Creating |
| **S14** | **Time-Entry Editing & Idle Dialogs** | Click row, `⌘E`, `+` manual, Calendar click, Idle return | Modify entries or resolve detected away time | `EntryEditSheet` (with searchable Project picker, Tag picker, Billable, Favorites star, Start/End/Date/Duration), `IdleResolutionSheet` (4 Toggl actions) | Edit Completed, Edit Running, Manual Log, Idle Detected |
| **S15** | **Menu Bar Companion & Floating Mini-Timer** | macOS Status Bar extra / `⇧⌘M` | Headless ambient tracking from any app | Status ticker (`🍅` / elapsed / optional project+desc), Popover (`Start/Stop/Pause`, Favorites, Quick Project, Continue recent, Open Workspace, Toggle Mini-Timer), Floating Always-on-Top Mini-Timer strip | Idle, Running, Paused, Pomodoro, Floating Pinned |

---

## Core User Flows

```text
F01 Instant Entry with Autocomplete (2-3 keystrokes)
    S01/S02 Description Field -> Type "Pyt" -> Autocomplete Popover shows "Python · Me" -> Arrow/Click -> Press Return -> Timer Starts

F02 Switch Between Timer & Manual Mode
    S01/S02 Click vertical '+' Manual circle (or ⌘D) -> Top bar switches to Manual Entry inputs (Description, Date, Start, End, Duration, Add) OR opens Manual Log sheet

F03 Calendar Interactive Block Manipulation
    S04 Double-click 10:00 AM slot -> Opens pre-filled Entry Creator for 10:00–11:00 -> Save -> Block appears -> Drag block to 13:00 or drag bottom handle to 14:30 -> PersistenceStore updates immediately

F04 Pomodoro Focus with Details & Auto-Transition
    S10 Click 🍅 -> Click "I'm focusing on..." -> DETAILS popover (enter description, pick project/tags/billable, Save) -> Start session -> Focus countdown syncs live with TimerManager & Menu Bar -> Work finishes -> macOS Notification -> Transitions cleanly to Short Break (timer stopped)

F05 Idle Detection Recovery
    S14 Timer runs while user inactive >= threshold -> User moves mouse -> Idle modal prompts with exact idle duration -> User chooses "Discard idle & continue" -> Original entry truncated to idle start time, new timer starts fresh

F06 Reports Filtering & Export
    S08 Sidebar Reports -> Switch [Summary | Detailed | Weekly] -> Apply Client/Project/Tag/Billable filters -> Export PDF / CSV / JSON
```

---

## Out of Scope
- Toggl Cloud account login, OAuth backend servers, team invitations, workspace permissions, and subscription billing paywalls.
- Proprietary Toggl raster/SVG artwork (all illustrations drawn cleanly in native SwiftUI vectors & SF Symbols).
- Simulated external Google/Outlook calendar sync (honest OAuth credential requirement documented; real local macOS Apple Calendar `EventKit` read-only overlay supported via opt-in permission).
