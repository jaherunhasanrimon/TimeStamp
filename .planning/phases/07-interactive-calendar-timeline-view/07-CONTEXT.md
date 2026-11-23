# Phase 7: Interactive Calendar Timeline View - Context

**Gathered:** 2026-11-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 7 implements the visual calendar timeline view for TimeStamp:
- Day view with a vertical 24-hour time grid (00:00 - 24:00) with proportional visual time blocks corresponding to tracked entries (`CAL-01`).
- Week view with a 7-day multi-column timeline (Monday through Sunday) showing daily time distribution and gaps (`CAL-02`).
- Overlapping entries layout algorithm dividing overlapping blocks into side-by-side sub-columns (`CAL-01`, `CAL-02`).
- Live current time horizontal indicator line with marker dot across today's timeline (`CAL-01`).
- Calendar block click interaction displaying an inspector popover with session details, quick "Continue" action, and "Edit" action opening `EntryEditSheet` (`CAL-03`).
- Live rendering of active running timer session extending to current time (`CAL-01`).
- Routing integration into `SidebarDestination.calendar` in `DetailContainerView`.

Out of scope for Phase 7:
- Settings & Preferences (Dark/Light appearance mode, hotkey configuration, timer defaults) (Phase 8).
- External calendar synchronization (Apple Calendar / Google Calendar) (v2).
</domain>

<decisions>
## Implementation Decisions

### 1. Vertical Time Grid & Scale (`CAL-01`)
- **D-01 (Time Grid Scale & Auto-Scroll):** Scrollable 24-hour vertical grid with 60px height per hour (1440px total canvas height). On view appearance, auto-scrolls to the current hour (or 8:00 AM if before 8:00 AM) using `ScrollViewReader`.
- Left time gutter displays hour labels formatted in system time (e.g. `08:00` or `8 AM`) using `AppTypography.caption` with subtle horizontal separator lines across each hour mark.

### 2. View Switching & Date Navigation (`CAL-01`, `CAL-02`)
- **D-02 (Toolbar Navigation & View Modes):**
  - Segmented control in toolbar: `[Day | Week]`.
  - Date navigation cluster: Previous (`chevron.left`) and Next (`chevron.right`) buttons.
  - "Today" quick-jump button that resets the date to today and scrolls to current time.
  - Dynamic date heading:
    - Day view: Formatted as `EEEE, MMM d, yyyy` (e.g. "Monday, Nov 23, 2026").
    - Week view: Formatted as `MMM d – MMM d, yyyy` (e.g. "Nov 17 – Nov 23, 2026").

### 3. Layout Geometry & Overlapping Entries (`CAL-01`, `CAL-02`)
- **D-03 (Side-by-Side Overlap Layout):**
  - Overlapping time entries within the same day column are detected and partitioned into non-overlapping sub-columns (Apple Calendar / Google Calendar algorithm).
  - Each block's vertical position: `top = (startHour * 60 + startMinute) * (60px / 60)`.
  - Each block's height: `height = max(24px, durationInMinutes * (60px / 60))`.
  - Blocks rendered with project color background (`Color(hex: project.colorHex).opacity(0.85)` or card background with color left-accent border), white/high-contrast text, entry description, and formatted time range.

### 4. Live Current-Time Indicator (`CAL-01`)
- **D-04 (Current Time Line):**
  - On the column for the current day, a prominent red or brand-accent horizontal rule with a circular marker dot indicates the exact current minute.
  - Automatically updates every minute while the app is active.
- **D-05 (Active Timer Live Block):**
  - If a timer is currently running today, it displays as an active block extending from its `startDate` to the current minute line, styled with an active indicator badge.

### 5. Calendar Block Interaction & Inspection (`CAL-03`)
- **D-06 (Popover Inspector & Edit Actions):**
  - Clicking any calendar block displays a macOS popover inspector (`.popover(item: ...)`):
    - Project swatch dot and project name.
    - Task name (if linked).
    - Entry description.
    - Exact time range (`formatTimeRange(start:end:)`) and total duration.
    - "Continue" button (`play.fill`) to immediately start a fresh timer with matching attributes (`timerManager.continueEntry()`).
    - "Edit" button that opens `EntryEditSheet` for full modification (duration, start/end dates, project, task, tags, or deletion).

### the agent's Discretion
- Week view column header presentation (displaying weekday abbreviation, day number, and day's total tracked time).
- Minimum block height handling for very short entries (< 15 mins) ensuring text readability without clipping.
- Smooth animated transitions between Day and Week view modes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing:**

### Domain Models & Persistence
- `Sources/Models/TimeEntry.swift` — Core entry model (`startDate`, `endDate`, `effectiveDuration`, `projectId`, `taskId`).
- `Sources/Models/Project.swift` — Project model for color hex styling (`colorHex`, `name`).
- `Sources/Models/PersistenceStore.swift` — Provides `timeEntries`, `projects`, and lookup methods `project(for:)`, `task(for:)`.
- `Sources/Core/Date/DateHelper.swift` — Calendar date manipulation, day boundaries, and human duration formatting.
- `Sources/Core/Timer/TimerManager.swift` — Live active entry duration and `continueEntry(_:)`.

### Existing Views & Design System
- `Sources/DesignSystem/Colors.swift` — `AppColors.brandAccent`, `AppColors.cardBackground`, `AppColors.border`.
- `Sources/DesignSystem/Typography.swift` — `AppTypography.caption`, `AppTypography.ticker`, `AppTypography.heading`.
- `Sources/Views/Entries/EntryEditSheet.swift` — Full edit modal for editing time entries.
- `Sources/Views/Navigation/DetailContainerView.swift` — Routing for `.calendar`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DateHelper.combine(...)`, `DateHelper.startOfDay(for:)`, and `DateHelper.formatTimeRange(...)` can be leveraged directly for calendar time calculations.
- `EntryEditSheet` is already implemented and tested, supporting full editing, project/task picker, and deletion.
- `TimerManager.continueEntry(_:)` is available for instantaneous resumption of past sessions.

### Established Patterns
- `@Observable` state with `@Environment(PersistenceStore.self)` and `@Environment(TimerManager.self)`.
- Swift Testing (`import Testing`) with `@MainActor` test suites.
- Geometry calculation for vertical layouts using standard SwiftUI coordinates.
</code_context>
