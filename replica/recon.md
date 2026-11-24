# Recon Map: Toggl Track (macOS Desktop & Web Companion)

**Scope:** Toggl Track macOS Desktop Client & Companion Dashboard (Time Tracking, Project/Task Selector, List/Calendar Views, Reports & Analytics, Goals, Menu Bar)  
**For:** TimeStamp (macOS Native Swift & SwiftUI Apple Silicon Desktop App)  
**Date:** 2026-11-24  
**Reference Screenshots:** `replica/screens/` (4 reference screenshots provided by user)

---

## Sources

| # | Source | Evidence | Notes |
|---|---|---|---|
| 1 | Reference Image 1 (`toggl_desktop_main.jpg`) | Desktop Client Main Window | Dark plum palette, Pomodoro tomato icon, inline project/tag/billable actions, magenta circular start button, List/Calendar capsule switcher, Today total, Goals drawer, "Let's get tracking!" empty state |
| 2 | Reference Image 2 (`toggl_desktop_project_picker.jpg`) | Project & Task Selector Popover | Green-bordered search input ("Search by project, task or client"), "No Project" option, grouped by client, colored project dots, sticky "+ Create project" footer |
| 3 | Reference Image 3 (`toggl_web_timer_view.jpg`) | Full Dashboard & Timer View | Sidebar (Track, Analyze, Manage, Admin), top timer bar, subnav (Calendar, List view, Timesheet), Goals drawer, purple binoculars & pink clouds empty state, notification popover |
| 4 | Reference Image 4 (`toggl_web_reports_view.jpg`) | Reports & Analytics View | Subnav (Summary, Detailed, Workload, etc.), date range stepper, filter pills, 4 KPI metric cards, "Duration by day" chart card, "Client distribution" donut card, "Project & member breakdown" |

---

## Core Loop

One-click frictionless time logging with instant project/task categorization, visual list/calendar inspection, and clear productivity analytics on macOS.

---

## Screen Inventory

| ID | Screen | Route / How to Reach | Purpose | Key Components | States Seen |
|---|---|---|---|---|---|
| **S01** | **Desktop Tracker (Compact Main)** | Launch / Default View / Window Toggle | Primary daily time-tracking companion window | Window header ("Workspace"), Pomodoro icon, description input, Project/Tag/Billable icons, duration ticker, Magenta circular start button, List/Calendar switcher, Today total, Goals card, Empty state illustration | Empty, Running, Paused, Logged Entries |
| **S02** | **Project & Task Picker Popover** | Click Folder icon in Timer Bar | Quick fuzzy search and hierarchical project/client assignment | Green focus border search input, "No Project" row, Client group headers, Project color dots, Task rows, Sticky "+ Create project" bottom action | Empty search, Filtered results, New project creation |
| **S03** | **List View (Time Entries Log)** | Switcher: "List" active on S01 or S05 | Chronological audit log of tracked sessions grouped by day | Day group headers (Date, daily total sum), entry row (description, project tag with color dot, client name, start/stop times, duration, play-again button, context menu) | Empty ("Let's get tracking!"), populated list, multi-day scroll |
| **S04** | **Calendar View (Timeline)** | Switcher: "Calendar" active on S01 or S05 | Visual schedule block view of logged time against wall-clock hours | Day/Week grid, time ruler (00:00 - 24:00), draggable/resizable entry blocks colored by project, current time indicator line | Empty day, populated schedule, active timer block |
| **S05** | **Expanded App Dashboard / Sidebar Shell** | Maximize / Expand button or Window Menu | Full management workspace with persistent navigation | Left sidebar (Track: Overview, Timer; Analyze: Reports; Manage: Projects, Clients, Tags; Admin: Settings), top sticky bar, main workspace | Full desktop view |
| **S06** | **Reports & Analytics (Summary)** | Sidebar: "Reports" -> "Summary" | Productivity breakdown, billable vs non-billable, and export | Date range navigator, filter pills, 4 KPI cards (Total Hours, Billable Hours, Amount, Average Daily Hours), Duration by day chart, Client distribution donut, Breakdown table | Empty state ("Nothing to see here..."), populated charts |
| **S07** | **Menu Bar Companion** | macOS Menu Bar Extra | Headless ambient time tracking from anywhere | Live menu bar ticker, quick start/stop button, popover summary with recent entries, quit action | Idle, Running |

---

## Flows

```
F01 Start & Log Time Entry (Quick Flow)
    S01 Timer Bar -> Type "Design System" -> Click Folder (S02) -> Select Project -> Click Magenta Start Button
    Happy path clicks: 3
    Edge: Started with no description, switched project mid-session, discarded via hotkey

F02 Search & Assign Project (Picker Flow)
    S01 -> Click Folder -> S02 opens -> Type search query -> Filter client/projects -> Press Return / Click row
    Happy path clicks: 2
    Edge: Project does not exist -> Click "+ Create project" -> Inline modal creation

F03 View & Audit Daily Log
    S01 List Mode -> Inspect Day Groups -> Click entry to edit details (Sheet/Popover) -> Click Play-Again to duplicate
    Happy path clicks: 1

F04 Analyze Time & Export Reports
    S05 Sidebar -> S06 Reports -> Adjust date range ("This week") -> Filter by Client/Project -> Inspect KPI cards and Charts -> Click Export CSV
    Happy path clicks: 3
```

---

## Components

| Component | Variants | States | Used On |
|---|---|---|---|
| **TimerBar** | Compact (S01), Full-width (S05) | Idle, Running, Paused | S01, S05 |
| **PlayButton** | Circular Magenta (36px), Small play-again (24px) | Default, Hover, Pressed, Active (Stop square) | S01, S03, S05 |
| **ProjectPicker** | Popover with Search & Groups | Default, Focused, Filtering, Empty | S01, S02, S05 |
| **SegmentedSwitcher** | Capsule pill `[ List \| Calendar ]` | Selected tab, hover | S01, S05 |
| **GoalsCard** | Collapsible dark card | Expanded, Collapsed, Goal item completed | S01, S05 |
| **KPISummaryCard** | 4-column metric card | Active value, Empty / "-" placeholder | S06 |
| **EmptyStateIllustration**| Typing hands (S01), Binoculars & clouds (S03/S06) | Display with title, subtitle, and action button | S01, S03, S06 |
| **FilterPill** | Rounded capsule tag with dropdown chevron | Inactive, Active, Removable | S06 |
| **ChartCard** | Rounded dark surface with header & dropdown action | Empty graphic, Rendered Swift Chart | S06 |

---

## Inferred Data Model

```
TimeEntry   id (uuid), description (string), project_id (uuid, nullable), task_id (uuid, nullable),
            start_date (date), end_date (date, nullable), duration (double),
            is_billable (boolean), tags (array of strings)
            evidence: S01 Timer bar icons, S03 entry rows, S06 KPI cards
            confidence: high

Project     id (uuid), name (string), client_id (uuid, nullable), color_hex (string),
            is_billable_default (boolean), is_archived (boolean)
            evidence: S02 Project picker grouped by client, colored dots
            confidence: high

Client      id (uuid), name (string), currency (string, default "$"), hourly_rate (double, nullable)
            evidence: S02 Client section headers ("NO CLIENT", "ME"), S06 Amount KPI card
            confidence: high

Task        id (uuid), name (string), project_id (uuid), is_completed (boolean)
            evidence: S02 "Search by project, task or client"
            confidence: high

Goal        id (uuid), title (string), target_duration (double), current_duration (double),
            period (daily | weekly | custom), icon_name (string), status (string)
            evidence: S01 Goals (4/4) card items with target durations and "KEEP GOING"
            confidence: high
```

---

## Feature Matrix

See `replica/features.csv`.

---

## Out of Scope (Cannot or Should Not be Cloned)

- Toggl proprietary cloud accounts, user authentication servers, team synchronization, and corporate billing plans.
- Proprietary SVG illustrations from Toggl (will use bespoke native SwiftUI Canvas / Shape / open iconography).
- Webhook integrations to third-party proprietary SaaS.

---

## Size & Complexity

- **Screens**: 7 screens (S01 - S07)
- **Flows**: 4 primary flows (F01 - F04)
- **Entities**: 5 models (TimeEntry, Project, Client, Task, Goal)
- **Hard Parts**: High-fidelity dark plum color system with WCAG compliance, floating compact companion layout alongside full dashboard window, high-density project/task popover picker, animated circular magenta start/stop timer button.
- **Estimated Effort**: M (Systematic SwiftUI component reconstruction).
