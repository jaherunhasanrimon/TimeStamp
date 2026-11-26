# Toggl Track Complete Product & Platform Feature Inventory

**Sources:**
- Official Documentation: `https://support.toggl.com/`
  - macOS Desktop App (`toggl-track-desktop-app-for-macos-1669b8x`)
  - Creating a Time Entry (`creating-a-time-entry-wg8nug`)
  - Time Tracking Goals (`time-tracking-goals-19bzb8u`)
  - Timeline Feature (`the-timeline-feature-1txzwm1`)
  - Pomodoro, Idle Detection, Autotracker, Reminders, Mini Timer, Reports, Exports
- Observed Reference Screenshots (`replica/screens/`, 13 screenshots total covering macOS Desktop & Web companion)

---

## Classification Legend
- **Platform**: `macOS` (Desktop native), `Web` (Web Workspace), `Both`
- **Access Tier / Dependency**:
  - `Free Local`: Works offline with zero subscription/credentials
  - `Auth / Cloud`: Requires Toggl account/server sync (TimeStamp provides local equivalent)
  - `Paid Tier in Toggl`: Requires Starter/Premium in Toggl (TimeStamp provides **for free** locally)
  - `macOS Permission`: Requires macOS system permission (`Notifications`, `Screen Recording`, `Calendar`, `Login Item`)

---

## A. Timer and Time Entry Management

| Feature | Platform | Toggl Tier / Dependency | Verified Behavior |
| :--- | :--- | :--- | :--- |
| Start / Stop Timer | Both | Free | One-click circular `#E54583` play button starts live wall-clock entry; stop completes & persists. Starting while one runs stops previous cleanly without overlap. |
| Description Autocomplete | Both | Free | Typing in `"What are you working on?"` opens popover listing matching `PROJECTS` (`· Client`) & recent `TIME ENTRIES` with highlighted query match. |
| Inline `@` and `#` Triggers | macOS | Free | Typing `@` opens Project Picker popover; typing `#` opens Tag Picker popover inside description input. |
| Manual Mode Toggle | macOS | Free | Vertical stacked mode buttons on top-right (Play = Timer mode, `+` = Manual Entry mode) or `⌘D`. Logs past entry with date, start/end times, duration. |
| Continue / Duplicate Entry | Both | Free | Hover play button restarts a new running entry copying description, project, task, tags, billable. Context menu also offers `Duplicate` (copies completed block). |
| Edit Entry (Running & Completed) | Both | Free | Clicking entry or `⌘E` edits description, project, task, tags, billable, start/end time, date, or duration. |
| Delete Entry + Undo | Both | Free | Deleting entry removes it from store with short Undo protection toast (restores exact deleted ID & attributes). |
| Search & Filter Entries | Both | Free | Filter list by keyword query, Project, Client, Tag, Billable status, or date. |
| Group Similar Time Entries | Both | Free | Collapses identical same-day entries (same description, project, task, tags, billable) into expandable `[N] Title  Total` group. |
| Favorite Time Entries | Both | Paid Tier in Toggl (Free in TimeStamp) | Pin frequent entries as Favorites; one-click start from Favorites bar / menu bar. |
| Keyboard Shortcuts | macOS | Free | `⌘N` new entry/focus, `⌘D` timer/manual mode, `⌘S` stop running timer, `⌘O` continue last entry, `⌘E` edit running entry, `⇧⌘M` toggle mini-timer, `⌘,` Preferences. |
| Sleep / Wake / Restart Recovery | macOS | Free | Wall-clock `Date` arithmetic + `SleepWakeMonitor`; uncompleted running session (`endDate == nil`) restores accurately across quit/relaunch. |

---

## B. Projects, Clients, Tasks & Tags

| Feature | Platform | Toggl Tier / Dependency | Verified Behavior |
| :--- | :--- | :--- | :--- |
| Project Hierarchy | Both | Free | Client -> Projects -> Tasks; TimeEntries link to `projectId` and optional `taskId`, never directly to Client. |
| Search-First Project Picker | macOS | Free | `#36B37E` green-bordered search bar, `• No Project` selected pill, `NO CLIENT` & client sections, project dots + inline Tasks, sticky `+ Create project` (magenta `+`, primary text). |
| Quick Inline Project Creation | Both | Free | Create project directly inside Project Picker or Goal Editor without leaving current workflow, including inline Client creation. |
| Archive / Restore / Safe Delete | Both | Free | Archiving hides project from active pickers while keeping historical reports; deleting removes child tasks and unlinks entries safely without deleting tracked time. |
| Project Estimates & Billable Rates | Both | Paid Tier in Toggl (Free in TimeStamp) | Per-project hourly rate, billable default toggle, and hour estimate with progress bar in Projects list. |
| Default Project Preference | macOS | Free | Auto-selects configured default project when starting new entries or clearing completed timer. |
| Multi-Tag Management | Both | Free | Create, rename, recolor, delete, search, multi-select tags (`TagPickerPopover` & dedicated Manage `Tags` screen). Safe cascade removal from historical entries. |

---

## C. Productivity: Goals & Pomodoro

| Feature | Platform | Toggl Tier / Dependency | Verified Behavior |
| :--- | :--- | :--- | :--- |
| Goals Engine | Both | 4-goal limit on Free Toggl (Unlimited in TimeStamp) | Track `atLeast` or `lessThan` targets across `Daily`, `Weekdays (Mon-Fri)` (evaluated per individual day), `Weekly` cadences. Filter by multiple projects/clients/tasks/tags/billable. |
| Goal Start & End Dates | Both | Free | Optional `UNTIL` date with `No end date` toggle (`startDate`..`endDate`). |
| Goal Creation / Edit Popover | macOS | Free | Native Toggl popover (`GOAL`, green-outlined title + icon selector, `TRACK` folder/tag filters, `FOR` target type/hours/cadence, `UNTIL` checkbox/date, `Delete`, `Save`, plus Live Preview). |
| Keep Going Action | macOS | Free | Click `KEEP GOING` on a goal row to start/focus matching timer without creating duplicate timers. |
| Pomodoro Window & Companion | macOS | Free | Click 🍅 opens Toggl Pomodoro experience: `"I'm focusing on..."` (`DETAILS` popover), tick-marked ring (`Focus / 25:00 / Ready?`), `Start session`, Pause/Skip/Reset, `Pomodoro settings ▸`. |
| Pomodoro Auto-Transitions & Cycle | macOS | Free | Configurable Work/Short Break/Long Break durations, long break every N sessions, optional auto-start breaks & focus, optional countdown vs count-up display, native notifications & sound. |

---

## D. Calendar & Timeline

| Feature | Platform | Toggl Tier / Dependency | Verified Behavior |
| :--- | :--- | :--- | :--- |
| Day & Week Timeline Views | Both | Free | 24-hour vertical schedule grid (`Day` & `Week`), overlap column clustering, current-time red indicator, daily column totals. |
| Direct Calendar Manipulation | macOS | Free | Double-click empty hour slot to create entry at that exact timestamp; drag block vertically/across days to move; drag top/bottom resize handle to change duration with configurable snap interval (`1/5/15/30m`). |
| Calendar Block Actions | macOS | Free | Click opens inspector popover (`Continue`, `Edit`, project/client/billable/tags); right-click context menu (`Continue`, `Duplicate`, `Edit`, `Toggle Billable`, `Delete`). |
| Local Activity Timeline (Opt-In) | macOS | Privacy Opt-in (`NSWorkspace`, optional Screen Recording for window titles) | Records active app switches (>10s threshold) strictly locally with exclude list, visible indicator, and 1-click purge. Never captures keystrokes/screenshots. |
| External Calendar Integration | Both | Apple Calendar (`EventKit` + Info.plist permission), Google/Outlook (OAuth Cloud Credentials) | Read-only local macOS Calendar event overlay via `EventKit` when authorized; Google/Outlook clearly documented as OAuth-dependent without fake sync. |

---

## E. Reports & Exports

| Feature | Platform | Toggl Tier / Dependency | Verified Behavior |
| :--- | :--- | :--- | :--- |
| Summary Report | Both | Free / Pro | 4 KPI cards (`Total Hours`, `Billable Hours`, `Amount`, `Average Daily Hours`), Stacked Bar chart (`Duration by day/project`), Donut distribution chart (`Slice by: Project/Client/Tag`), Breakdown table with project->task hierarchy. |
| Detailed Report | Both | Free | Searchable, filterable, sortable table of every individual time entry with date, time span, project, client, task, tags, billable toggle, inline edit, and duration. |
| Weekly Report | Both | Free | 7-day Monday–Sunday matrix showing daily hours per Project/Client/Tag plus column & row totals. |
| Comprehensive Filtering | Both | Free | Filter Reports by Date Range preset (`Today`, `Yesterday`, `This Week`, `Last Week`, `This Month`, `Last Month`, `Custom`), Project, Client, Tag, Billable status (`All`/`Billable`/`Non-Billable`), Description keyword. |
| Exports (CSV, JSON, PDF) | Both | PDF Free / CSV&XLSX Paid in Toggl (All Free in TimeStamp) | RFC 4180 CSV (including Tags, Billable, Rate, Amount), structured JSON, and clean native macOS PDF report export via `NSPrintOperation` / CoreGraphics `PDFDocument`. |

---

## F. macOS Integration, Preferences & Data Safety

| Feature | Platform | Toggl Tier / Dependency | Verified Behavior |
| :--- | :--- | :--- | :--- |
| Menu Bar Companion | macOS | Free | Live ticker (`🍅 24:15` or `00:12:34`), optional project/description display, popover start/stop/pause/favorites/recent switch, show/hide main window. |
| Floating Mini-Timer (`⇧⌘M`) | macOS | Free | Always-on-top compact floating window with pin toggle, description, project dot, live duration, Start/Stop/Pause. |
| Idle Detection | macOS | Free (`CGEventSource.secondsSinceLastEventType`) | Detects keyboard/mouse inactivity while timer runs; prompts upon return with 4 Toggl actions: *Discard idle time*, *Discard & continue*, *Keep idle time*, *Split idle as new entry*. |
| Tracking Reminders | macOS | Paid/Desktop in Toggl (Free in TimeStamp) | Local `UNUserNotificationCenter` workday schedule nudge if not tracking. |
| Autotracker Rules | macOS | Free (`NSWorkspace`) | Opt-in local keyword rules matching active app name to suggest/notify starting timer for a target project. |
| Dock & Login Preferences | macOS | Free | Toggle Dock Icon visibility (`NSApp.setActivationPolicy`), Open at Login (`SMAppService.mainApp` with graceful unsigned status reporting), Global Shortcuts (`Carbon` `RegisterEventHotKey` + custom key recorder). |
| Clean Install & Safe Data Persistence | Local | Free | Zero seeded sample records on fresh install; atomic JSON writes; backward-compatible `Codable` schema; automatic timestamped backups before reset/migration. |

---

## G. Explicitly Out of Scope (Cloud / Account Dependent)
- Toggl Cloud Login / OAuth Authentication / Workspace Invitations / Team Member Approvals / Workspace Billing & Upgrades.
- Google Calendar & Microsoft Outlook OAuth sync (documented as requiring external client IDs/backend OAuth).
