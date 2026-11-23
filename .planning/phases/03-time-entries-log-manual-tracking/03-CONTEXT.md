# Phase 3: Time Entries Log & Manual Tracking - Context

**Gathered:** 2026-11-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 3 implements the core time entries log, daily chronological grouping, daily total duration calculations, inline/sheet editing, manual time logging, and deletion safety:
- Daily grouped chronological entry list with relative day headers ("Today", "Yesterday", "Mon, Nov 21") (`ENTRY-01`).
- Accurate daily total tracked time calculation in day group headers formatted as compact human-readable duration (e.g. `4h 15m`) (`ENTRY-02`).
- Detailed entry editing sheet (`EntryEditSheet`) for description, project, task, start/stop timestamps, and duration with synchronized recalculation (`ENTRY-03`).
- Deletion safety with native macOS confirmation alert, swipe-to-delete trackpad support, and rich context menu (`ENTRY-04`).
- Manual past entry logging with `+ Log Time` toolbar button, `Cmd+N` keyboard shortcut, and pre-filled 1-hour window (`ENTRY-05`).
- Replacing the placeholder in `SidebarDestination.timer` with `EntriesListView`.

Out of scope for Phase 3:
- Dedicated project/client creation modals and color-tagging management (Phase 4).
- Calendar timeline 24-hour visual block grid (Phase 7).
- Menu bar status item companion (Phase 5).
- Charts and summary dashboards (Phase 6).
</domain>

<decisions>
## Implementation Decisions

### Daily Grouping & Day Header Format
- **D-01 (Date Format):** Relative with Weekday — Displays 'Today', 'Yesterday', and 'Mon, Nov 21' for earlier dates.
- **D-02 (Daily Total Format):** Compact Human-Readable — Formatted as '4h 15m' (or '45m' if under 1 hour) in headers, keeping full monospaced `HH:MM:SS` duration on individual row badges.
- **D-03 (Time Range Format):** System Locale Time — Formatted as `09:30 - 11:15` or `9:30 AM - 11:15 AM` adhering to user macOS regional settings.
- **D-04 (Hover & Actions):** Show on Hover + Context Menu — Row action buttons (Continue tracking, Delete) remain hidden until cursor hovers over the row, with full right-click context menu available.

### Entry Editing Interaction
- **D-05 (Presentation):** Dedicated Edit Sheet — Clicking or double-clicking an entry row opens a native modal `EntryEditSheet` with date/time pickers and project selector.
- **D-06 (Auto-Adjusting End Time):** Preserves Duration — Changing the start time automatically shifts the end time forward by the current duration.
- **D-07 (Save Pattern):** Explicit Save / Cancel — Sheet features clear 'Save' and 'Cancel' buttons with Escape key dismissal.
- **D-08 (Synchronized Duration):** Bidirectional Sync — Adjusting start/end date pickers recalculates duration, and editing duration directly adjusts the end time.

### Manual Time Logging Workflow
- **D-09 (Trigger):** Dual Access — A '+ Log Time' button in the entries list toolbar alongside a system-wide `Cmd+N` keyboard shortcut when viewing entries.
- **D-10 (Default Time Window):** Pre-fill Past 1 Hour — Default start time = `Now - 1 hour`, end time = `Now`.
- **D-11 (Default Context):** Retain Project & Task — Pre-selects the last active/retained project and task context.
- **D-12 (Form UI):** Unified Sheet — Reuses the `EntryEditSheet` layout with title 'Log Time Entry' and primary button 'Add Entry'.

### Deletion Safety & Confirmation
- **D-13 (Confirmation Dialog):** Native macOS Confirmation Alert — Presents alert sheet asking 'Delete Time Entry?' with destructive 'Delete' and 'Cancel' options.
- **D-14 (Trackpad Swipe):** Swipe-to-Delete — Supports native macOS two-finger trackpad swipe left to reveal red delete action.
- **D-15 (Context Menu):** Full Action Set — Right-click context menu includes 'Continue Timer', 'Edit...', 'Duplicate Entry', and 'Delete...'.
- **D-16 (Empty State):** Illustrated Empty State — Displays stopwatch icon, 'No time entries yet', and guidance to start the timer or press `Cmd+N`.

### the agent's Discretion
- Visual divider styling between day groups and spacing between rows.
- Duplicate entry logic (creates a clone starting right after the original or at current timestamp).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing:**
- `.planning/REQUIREMENTS.md` — ENTRY-01 through ENTRY-05 requirements.
- `.planning/phases/01-project-scaffolding-swiftdata-models-app-shell/01-UI-SPEC.md` — Color palette, typography scale, spacing tokens.
- `Sources/Models/TimeEntry.swift` — `TimeEntry` model, `effectiveDuration`, and `Equatable` conformance.
- `Sources/Models/PersistenceStore.swift` — CRUD methods (`saveTimeEntry`, `deleteTimeEntry`, `timeEntries` collection).
- `Sources/Core/Timer/TimerManager.swift` — `continueEntry(_:)` and active timer coordination.
- `Sources/Core/Timer/TimeCalculator.swift` — `formatDuration(_:)` and duration math.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TimeCalculator.formatDuration(_:)`: Formats intervals into `HH:MM:SS`.
- `PersistenceStore.timeEntries`: Reactive array of all persisted time entries.
- `TimerManager.continueEntry(_:)`: Clones entry attributes and starts a new timer seamlessly.
- `ProjectTaskPickerButton`: Compact project/task selector ready to embed in `EntryEditSheet`.
- `AppColors.brandAccent`, `AppColors.cardBackground`, `AppColors.subtleBorder`: Design system tokens.
- `AppTypography.ticker`, `AppTypography.body`, `AppTypography.caption`: Type scale.

### Integration Points
- `SidebarDestination.timer`: Currently renders a placeholder in `DetailContainerView`. Will be replaced with `EntriesListView`.
- `DetailContainerView`: Displays `ActiveTimerBar()` at the top, with `EntriesListView` below it.

</code_context>

<specifics>
## Specific Ideas
- Toggl Track style daily grouping: entries for today grouped under "Today", yesterday under "Yesterday", each with a clean sum of total tracked hours/minutes on the right.
- Pressing `Cmd+N` opens the manual time logging modal instantly.

</specifics>

<deferred>
## Deferred Ideas
- Multi-day range bulk editing / batch deletion — deferred to v2.
- Billable rate and currency toggles — explicitly out of scope for v1.
- In-place spreadsheet-style grid table editing — keep to native macOS list + sheet pattern for v1.

</deferred>

---

*Phase: 03-time-entries-log-manual-tracking*
*Context gathered: 2026-11-23*
