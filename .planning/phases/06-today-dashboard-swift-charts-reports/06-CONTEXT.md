# Phase 6: Today Dashboard & Swift Charts Reports - Context

**Gathered:** 2026-11-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 6 implements the visual analytics, daily productivity dashboard, and data reporting layer using Apple's native Swift Charts framework:
- Today Dashboard with daily progress hero card, circular progress ring against target, and recent activity list (`DASH-01`, `DASH-03`).
- Weekly activity stacked bar chart (Mon–Sun) segmented by project color with daily target threshold line (`DASH-02`).
- Reports view with interactive Swift Charts Donut/Sector chart displaying time distribution by project and client (`REPT-01`, `REPT-02`).
- Date range filtering presets (`Today`, `This Week`, `This Month`, `Custom Range`) (`REPT-03`).
- Formatted CSV and JSON report export service triggered via native macOS `NSSavePanel` (`REPT-04`).
- Routing integration into `SidebarDestination.dashboard` and `SidebarDestination.reports`.

Out of scope for Phase 6:
- Interactive 24-hour visual calendar timeline grid (Phase 7).
- Persistent user preference settings for default billable rates and app theme (Phase 8).
</domain>

<decisions>
## Implementation Decisions

### Today Dashboard Layout & Daily Target Metric
- **D-01 (Today Progress Presentation):** Hero card featuring a circular progress ring (`Circle().trim(...)` or Swift Charts angular gauge) displaying large formatted today's duration (e.g. `5h 20m`), percentage of goal achieved, and remaining time.
- **D-02 (Daily Target Configuration):** Default 8.0 hours target with inline click-to-edit target picker (dropdown with presets: 4h, 6h, 7.5h, 8h, or custom stepper/field). Target value stored in `UserDefaults` (`dailyTargetHoursKey`).
- **D-03 (Recent Activity Section):** Card displaying the top 5 recent time entries with project color swatch, description, duration badge, and hover "Continue" (`play.fill`) button to immediately restart tracking on recent tasks.
- **D-04 (Target Exceeded Visual State):** When today's tracked time exceeds the daily target, the ring transitions to green success accent (`AppColors.success`) and shows an overtime celebration badge (e.g. `+35m over goal`).

### Weekly Activity Bar Chart Presentation
- **D-05 (Weekly Stacked Bar Chart):** Swift Charts `Chart` rendering Monday through Sunday columns (`BarMark`). Each bar is stacked and colored by individual project swatches (`project.colorHex`). Includes a subtle horizontal dashed `RuleMark` representing the daily target threshold.

### Reports Analytics & Visualization Style
- **D-06 (Reports Distribution Visuals):** Interactive Donut Chart using Swift Charts `SectorMark(angle: ..., innerRadius: .ratio(0.65))` with central total duration label. Accompanied by a ranked breakdown table showing project/client name, color dot, total duration, and percentage share. Supports toggling between "By Project" and "By Client".
- **D-07 (Date Range Filtering):** Toolbar segmented control / dropdown supporting presets: `Today`, `This Week`, `This Month`, and `Custom Range` (which reveals standard macOS start and end `DatePicker` controls).

### Export Service & File Delivery UX
- **D-08 (Export Delivery UX):** Toolbar "Export" menu button with options "Export CSV" and "Export JSON". Prompts user with native macOS `NSSavePanel` pre-populated with a standardized filename (e.g. `TimeStamp-Report-YYYY-MM-DD.csv` / `.json`).
  - **CSV Schema:** `Date,Start Time,End Time,Duration (Seconds),Duration (Formatted),Description,Project,Client,Task`
  - **JSON Schema:** Structured array of entry objects with ISO-8601 timestamps, duration seconds, project metadata, and client name.

### the agent's Discretion
- Micro-spacing, padding, and corner radii of dashboard summary metric cards.
- Swift Charts animations and tooltips when hovering over chart sectors and bar segments.
- Empty state designs for dashboard and reports when no entries exist in the selected period.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing:**

### Domain Models & Persistence
- `Sources/Models/TimeEntry.swift` — Time entry entity (`startDate`, `endDate`, `effectiveDuration`, `projectId`, `taskId`).
- `Sources/Models/Project.swift` — Project entity (`name`, `colorHex`, `clientId`).
- `Sources/Models/Client.swift` — Client entity (`name`).
- `Sources/Models/PersistenceStore.swift` — Reactive store providing `timeEntries`, `projects`, and `clients`.
- `Sources/Core/Date/DateHelper.swift` — Calendar math, relative days, and duration formatting (`formatHumanDuration`).

### Design System & Existing Views
- `Sources/DesignSystem/Colors.swift` — `AppColors.brandAccent`, `AppColors.projectColors`, `AppColors.success`.
- `Sources/DesignSystem/Typography.swift` — Type scale and monospaced tickers (`AppTypography.ticker`).
- `Sources/Views/Navigation/DetailContainerView.swift` — Routing for `.dashboard` and `.reports`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DateHelper`: `startOfDay(for:)`, `combine(...)`, and `formatHumanDuration(...)` ready for date range calculations and metric formatting.
- `AppColors.projectColors`: Hex color swatches already used across views and compatible with Swift Charts `.foregroundStyle(by:)` or custom color mapping.
- `TimeCalculator.calculateDuration(...)`: Available for computing durations of running or completed sessions.

### Established Patterns
- Native SwiftUI views with `@Environment(PersistenceStore.self)` and `@Environment(TimerManager.self)`.
- Swift Charts native integration (`import Charts`) requiring zero external dependencies on macOS 14+.
- Swift Testing (`import Testing`) with `@MainActor` test suites.
</code_context>
