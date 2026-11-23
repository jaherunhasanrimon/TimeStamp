# Roadmap: TimeStamp

## Overview

TimeStamp is an authentic, native macOS desktop time-tracking application inspired by Toggl Track, built with Swift, SwiftUI, and SwiftData for Apple Silicon Macs. This roadmap takes TimeStamp from initial app shell and SwiftData persistence to a full productivity release featuring drift-free background timing, macOS menu bar integration, global hotkeys, daily/weekly dashboards, interactive calendar timeline blocks, and Swift Charts reports.

## Phases

- [x] **Phase 1: Project Scaffolding, SwiftData Models & App Shell** - Bootstrap macOS app target, SwiftData container, design tokens, and sidebar navigation
- [ ] **Phase 2: Core Drift-Free Timer Engine** - Implement wall-clock reference timer, start/pause/stop/continue mechanics, and sleep/wake listeners
- [ ] **Phase 3: Time Entries Log & Manual Tracking** - Deliver daily grouped entry lists, daily duration totals, inline editing, and manual logging
- [ ] **Phase 4: Projects, Tasks, and Clients Management** - Build color-coded projects, task hierarchy, client entities, and entity filtering
- [ ] **Phase 5: macOS Menu Bar Companion & Global Hotkeys** - Add MenuBarExtra live ticker, quick toggle menu, and system-wide keyboard shortcuts
- [ ] **Phase 6: Today Dashboard & Swift Charts Reports** - Build daily progress summary, weekly bar chart, distribution analytics, and CSV/JSON export
- [ ] **Phase 7: Interactive Calendar Timeline View** - Implement visual day & week calendar time block grids with click-to-edit
- [ ] **Phase 8: Settings, Theme Polish & End-to-End Verification** - Deliver preferences (Dark/Light/System), shortcuts config, and full verification

## Phase Details

### Phase 1: Project Scaffolding, SwiftData Models & App Shell

**Goal**: Bootstrap macOS app target, SwiftData container, design tokens, and sidebar navigation
**Mode:** mvp
**UI hint**: yes
**Depends on**: Nothing (first phase)
**Requirements**: Foundation for all v1 requirements
**Success Criteria**:

  1. macOS application target builds cleanly and launches displaying a modern macOS 14+ navigation split view with sidebar.
  2. SwiftData `ModelContainer` initializes with all schemas (`TimeEntry`, `Project`, `Task`, `Client`, `Tag`) with preview sample data.
  3. Shared design system tokens for colors, typography, card containers, and status indicators match macOS Apple Silicon HIG.

**Plans**: 2 plans

Plans:
**Wave 1**

- [x] 01-01: Create macOS app target structure, SwiftData models (`TimeEntry`, `Project`, `Task`, `Client`, `Tag`), and preview container.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02: Build root window layout, sidebar navigation (`AppSidebar`), design system tokens, and empty detail views.

---

### Phase 2: Core Drift-Free Timer Engine

**Goal**: Implement wall-clock reference timer, start/pause/stop/continue mechanics, and sleep/wake listeners
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 1
**Requirements**: TIMER-01, TIMER-02, TIMER-03, TIMER-04, TIMER-05
**Success Criteria**:

  1. User can start a timer with optional description, project, and task from the sticky top timer bar.
  2. User can pause an active timer and resume it without losing accrued duration.
  3. User can stop the timer, immediately persisting a completed `TimeEntry` in SwiftData.
  4. User can continue tracking a previous time entry with one click.
  5. Timer accurately computes elapsed duration across Mac minimization, screen lock, and system sleep/wake cycles with zero drift.

**Plans**: 2 plans

Plans:

- [ ] 02-01: Implement `TimeCalculator`, `@Observable class TimerManager`, and `SleepWakeMonitor` with unit tests for drift-free math.
- [ ] 02-02: Build `ActiveTimerBar` UI with live duration display, project/task selector, and start/pause/stop controls.

---

### Phase 3: Time Entries Log & Manual Tracking

**Goal**: Deliver daily grouped entry lists, daily duration totals, inline editing, and manual logging
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 2
**Requirements**: ENTRY-01, ENTRY-02, ENTRY-03, ENTRY-04, ENTRY-05
**Success Criteria**:

  1. Tracked entries appear grouped chronologically by day with formatted start/end timestamps and durations.
  2. Each day group displays an accurate total tracked time header calculated using `Calendar.current`.
  3. User can edit an entry's description, project, start time, and stop time inline or via an edit sheet.
  4. User can delete an entry with confirmation dialog.
  5. User can manually log past time entries with custom start and end times via a dedicated entry modal.

**Plans**: 2 plans

Plans:

- [ ] 03-01: Build `EntriesListView` with daily grouped sections, duration calculations, entry rows, and swipe/context menu actions.
- [ ] 03-02: Implement `EntryEditSheet` and `ManualEntryModal` with date/time pickers and validation.

---

### Phase 4: Projects, Tasks, and Clients Management

**Goal**: Build color-coded projects, task hierarchy, client entities, and entity filtering
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 3
**Requirements**: PROJ-01, PROJ-02, PROJ-03, PROJ-04, TASK-01, TASK-02, TASK-03, CLNT-01, CLNT-02, CLNT-03
**Success Criteria**:

  1. User can create, edit, color-tag, and archive projects with custom color palettes.
  2. User can create tasks under specific projects and associate running/logged entries with tasks.
  3. User can create clients, associate projects to clients, and view total tracked time per client.
  4. User can filter time entries and views by selected project or client.

**Plans**: 2 plans

Plans:

- [ ] 04-01: Build `ProjectsListView`, `ProjectEditorSheet`, color picker swatches, and task hierarchy sub-lists.
- [ ] 04-02: Build `ClientsListView`, client creation sheet, client-to-project associations, and project/client filtering.

---

### Phase 5: macOS Menu Bar Companion & Global Hotkeys

**Goal**: Add MenuBarExtra live ticker, quick toggle menu, and system-wide keyboard shortcuts
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 2
**Requirements**: SYS-01, SYS-02, SYS-03
**Success Criteria**:

  1. macOS menu bar item (`MenuBarExtra`) displays the live running timer ticker and status icon.
  2. Clicking the menu bar item opens a clean popup with start/pause/stop buttons, active entry info, and recent entries.
  3. User can press a global hotkey from any macOS app to toggle or start/stop the active timer.

**Plans**: 2 plans

Plans:

- [ ] 05-01: Implement `MenuBarCompanionView` with `MenuBarExtra` scene, live ticker synchronization, and quick controls.
- [ ] 05-02: Integrate `KeyboardShortcuts` framework and build `HotKeyManager` for system-wide timer toggle.

---

### Phase 6: Today Dashboard & Swift Charts Reports

**Goal**: Build daily progress summary, weekly bar chart, distribution analytics, and CSV/JSON export
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 4
**Requirements**: DASH-01, DASH-02, DASH-03, REPT-01, REPT-02, REPT-03, REPT-04
**Success Criteria**:

  1. Dashboard renders today's total tracked time against a configurable daily goal and shows a weekly summary bar chart.
  2. Reports view visualizes time distribution across projects and clients using interactive Swift Charts.
  3. User can filter reports by date ranges (Today, This Week, This Month, Custom Date Range).
  4. User can export report data as formatted CSV or JSON files.

**Plans**: 2 plans

Plans:

- [ ] 06-01: Build `DashboardView` with today's summary card, daily goal progress ring, and weekly activity bar chart.
- [ ] 06-02: Build `ReportsView` with Swift Charts (donut/bar breakdowns), date range filters, and `ExportService` (CSV/JSON).

---

### Phase 7: Interactive Calendar Timeline View

**Goal**: Implement visual day & week calendar time block grids with click-to-edit
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 3
**Requirements**: CAL-01, CAL-02, CAL-03
**Success Criteria**:

  1. Day view displays a vertical 24-hour time grid with proportional visual time blocks corresponding to tracked entries.
  2. Week view displays a 7-day multi-column timeline showing weekly distribution and gaps.
  3. Clicking any visual time block opens the entry inspector for editing or continuing the session.

**Plans**: 2 plans

Plans:

- [ ] 07-01: Build `CalendarTimelineView` day view with vertical 24-hour scale, block layout math, and current time indicator.
- [ ] 07-02: Build multi-column week timeline view with block selection, quick continuation, and zoom/scroll controls.

---

### Phase 8: Settings, Theme Polish & End-to-End Verification

**Goal**: Deliver preferences (Dark/Light/System), shortcuts config, and full verification
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 1, Phase 5, Phase 6, Phase 7
**Requirements**: SET-01, SET-02, SET-03
**Success Criteria**:

  1. User can switch between Dark, Light, and System appearance modes with fluid transitions and full HIG adherence.
  2. User can customize the global hotkey and default timer behaviors in a native macOS Settings window.
  3. All 35 v1 requirements verified with automated unit/integration tests and complete manual walkthroughs.

**Plans**: 2 plans

Plans:

- [ ] 08-01: Build native macOS `SettingsView` with tabs for General, Appearance, Shortcuts, and Timer Behavior.
- [ ] 08-02: Execute comprehensive test suite, verify sleep/wake resilience, and complete end-to-end verification.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

| Phase | Mode | Plans Complete | Status | Completed |
|-------|------|----------------|--------|-----------|
| 1. Scaffolding, Models & Shell | mvp | 2/2 | Complete | 2026-11-23 |
| 2. Core Timer Engine | mvp | 0/2 | Planned | - |
| 3. Entries Log & Manual Tracking | mvp | 0/2 | Not started | - |
| 4. Projects, Tasks & Clients | mvp | 0/2 | Not started | - |
| 5. Menu Bar Companion & Hotkeys | mvp | 0/2 | Not started | - |
| 6. Dashboard & Reports | mvp | 0/2 | Not started | - |
| 7. Calendar Timeline View | mvp | 0/2 | Not started | - |
| 8. Settings & Verification | mvp | 0/2 | Not started | - |
