# Requirements: TimeStamp

**Defined:** 2026-11-23
**Core Value:** Frictionless, accurate time tracking that stays out of the user's way while providing immediate, reliable visibility into where time goes on macOS.

## v1 Requirements

### Timer & Tracking Engine

- [x] **TIMER-01**: User can start a new timer with optional description, project, and task
- [x] **TIMER-02**: User can pause an active timer and resume it without losing accrued time
- [x] **TIMER-03**: User can stop an active timer, which saves it as a completed time entry
- [x] **TIMER-04**: User can continue tracking a previous time entry with one click
- [x] **TIMER-05**: Timer accurately tracks elapsed time across Mac minimization, screen lock, and system sleep/wake cycles without drift

### Time Entries Management

- [x] **ENTRY-01**: User can view tracked time entries grouped chronologically by day
- [x] **ENTRY-02**: User can view daily total duration headers for each group of entries
- [x] **ENTRY-03**: User can edit description, start time, end time, and project of an existing entry
- [x] **ENTRY-04**: User can delete a time entry with confirmation
- [x] **ENTRY-05**: User can manually log past time entries with custom start and end times

### Projects Management

- [x] **PROJ-01**: User can create a new project with a name and custom color
- [x] **PROJ-02**: User can edit project details (name, color, client assignment)
- [x] **PROJ-03**: User can archive or delete a project
- [x] **PROJ-04**: User can filter time entries and statistics by project

### Tasks Hierarchy

- [x] **TASK-01**: User can create tasks under specific projects
- [x] **TASK-02**: User can mark tasks as completed or active
- [x] **TASK-03**: User can associate a time entry with a specific task

### Clients Management

- [x] **CLNT-01**: User can create and manage client profiles with name and notes
- [x] **CLNT-02**: User can associate projects with a client
- [x] **CLNT-03**: User can filter entries and view total time tracked per client

### Today & Weekly Dashboard

- [x] **DASH-01**: User can view total time tracked today and compare against a daily target
- [x] **DASH-02**: User can view a weekly summary bar chart of tracked hours across Monday to Sunday
- [x] **DASH-03**: User can view recent activity entries directly from the dashboard

### Productivity Reports & Analytics

- [x] **REPT-01**: User can view total time distribution by project using interactive charts
- [x] **REPT-02**: User can view total time distribution by client
- [x] **REPT-03**: User can filter report date ranges (Today, This Week, This Month, Custom)
- [x] **REPT-04**: User can export report summaries as CSV or JSON files

### Calendar Timeline View

- [ ] **CAL-01**: User can view time entries as visual blocks on a daily time grid (00:00 - 24:00)
- [ ] **CAL-02**: User can view a weekly multi-column timeline of time blocks
- [ ] **CAL-03**: User can click a calendar block to inspect and edit entry details

### macOS System Integration & Menu Bar

- [x] **SYS-01**: User can view the active timer duration ticker in the macOS menu bar (`MenuBarExtra`)
- [x] **SYS-02**: User can start, pause, or stop the timer from the menu bar dropdown popup
- [x] **SYS-03**: User can trigger a global keyboard shortcut from any application to start/stop the active timer

### Settings & Preferences

- [ ] **SET-01**: User can switch between Dark, Light, and System appearance modes
- [ ] **SET-02**: User can configure the global hotkey shortcut
- [ ] **SET-03**: User can configure timer preferences (default project, auto-stop options)

## v2 Requirements

### Cloud Sync & Integrations

- **SYNC-01**: User data seamlessly synchronizes across multiple Macs via iCloud / CloudKit
- **SYNC-02**: User can import calendar events from Apple Calendar / Google Calendar
- **SYNC-03**: User receives Mac Idle Detection prompt when inactive for more than 5 minutes

## Out of Scope

| Feature | Reason |
|---------|--------|
| Screen recording & keystroke spying | Violates user trust and privacy; TimeStamp is built for personal productivity |
| Full accounting & invoicing engine | Scope explosion; TimeStamp provides clean CSV/JSON exports for accounting tools |
| Web or Windows/Linux clients | v1 is hyper-focused on an authentic, lightweight native macOS Apple Silicon experience |
| User authentication / team roles | Single-user local-first design for v1 release |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TIMER-01 | Phase 2 | Complete |
| TIMER-02 | Phase 2 | Complete |
| TIMER-03 | Phase 2 | Complete |
| TIMER-04 | Phase 2 | Complete |
| TIMER-05 | Phase 2 | Complete |
| ENTRY-01 | Phase 3 | Complete |
| ENTRY-02 | Phase 3 | Complete |
| ENTRY-03 | Phase 3 | Complete |
| ENTRY-04 | Phase 3 | Complete |
| ENTRY-05 | Phase 3 | Complete |
| PROJ-01 | Phase 4 | Complete |
| PROJ-02 | Phase 4 | Complete |
| PROJ-03 | Phase 4 | Complete |
| PROJ-04 | Phase 4 | Complete |
| TASK-01 | Phase 4 | Complete |
| TASK-02 | Phase 4 | Complete |
| TASK-03 | Phase 4 | Complete |
| CLNT-01 | Phase 4 | Complete |
| CLNT-02 | Phase 4 | Complete |
| CLNT-03 | Phase 4 | Complete |
| SYS-01 | Phase 5 | Complete |
| SYS-02 | Phase 5 | Complete |
| SYS-03 | Phase 5 | Complete |
| DASH-01 | Phase 6 | Complete |
| DASH-02 | Phase 6 | Complete |
| DASH-03 | Phase 6 | Complete |
| REPT-01 | Phase 6 | Complete |
| REPT-02 | Phase 6 | Complete |
| REPT-03 | Phase 6 | Complete |
| REPT-04 | Phase 6 | Complete |
| CAL-01 | Phase 7 | Pending |
| CAL-02 | Phase 7 | Pending |
| CAL-03 | Phase 7 | Pending |
| SET-01 | Phase 8 | Pending |
| SET-02 | Phase 8 | Pending |
| SET-03 | Phase 8 | Pending |

**Coverage:**
- v1 requirements: 35 total
- Mapped to phases: 35
- Unmapped: 0 ✓

---
*Requirements defined: 2026-11-23*
*Last updated: 2026-11-23 after initial definition*
