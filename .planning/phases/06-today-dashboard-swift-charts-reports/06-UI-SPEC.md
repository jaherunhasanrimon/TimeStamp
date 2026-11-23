---
phase: 06
slug: today-dashboard-swift-charts-reports
status: approved
shadcn_initialized: false
preset: macos-native
created: 2026-11-23
---

# Phase 6 — UI Design Contract: Today Dashboard & Swift Charts Reports

> Visual and interaction design contract for Phase 6 Today Dashboard, Swift Charts weekly stacked bars, interactive Donut/Sector distribution reports, date range filters, and native CSV/JSON export. Inherits core tokens from `01-UI-SPEC.md` and locks decisions D-01 through D-08.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Native SwiftUI & Swift Charts (macOS 14+) |
| Preset | macOS Native Human Interface Guidelines |
| Component library | Native SwiftUI Views & Modifiers + Swift Charts (`BarMark`, `SectorMark`, `RuleMark`) |
| Icon library | SF Symbols 5 (`chart.pie`, `chart.bar`, `clock`, `calendar`, `target`, `checkmark.circle.fill`, `play.fill`, `square.and.arrow.up`, `chevron.down`, `arrow.clockwise`, `doc.text`, `folder.fill`, `person.2.fill`) |
| Font | San Francisco (System & Monospaced Digits) |

---

## Spacing Scale

Declared values (conforming to 4pt grid in `AppSpacing`):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline icon gaps, badge padding, legend swatch spacing |
| sm | 8px | Button padding, row gaps, target selector padding |
| md | 16px | Card internal padding, grid spacing, list padding |
| lg | 24px | Section separation, dashboard column gap |
| xl | 32px | Outer container margins, major view padding |
| 2xl | 48px | Empty state layout spacing |

Exceptions:
- Circular Progress Ring diameter: 140px (stroke width: 12px)
- Weekly Bar Chart height: fixed 220px
- Donut Chart diameter: 220px (inner radius ratio: 0.65)
- Summary Metric Cards: minimum height 120px, corner radius 10px (`AppSpacing.radiusCard`)

---

## Typography

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Dashboard Hero Value | 32pt | Bold | 1.0 (`monospacedDigit()`) | Today total tracked time ("5h 20m") (`D-01`) |
| Donut Center Total | 22pt | Bold | 1.0 (`monospacedDigit()`) | Center total duration in Reports Donut chart (`D-06`) |
| Section Heading | 16pt | Semibold | 1.2 | "Today's Progress", "Weekly Activity", "Recent Activity" |
| Card Metric Value | 18pt | Semibold | 1.1 (`monospacedDigit()`) | Secondary metric values ("38h 15m", "78%") |
| Body | 13pt | Regular | 1.3 | Entry descriptions, project names in breakdown table |
| Label | 12pt | Medium | 1.2 | Target selector pill, chart axis labels, breakdown percentages |
| Caption | 11pt | Regular | 1.2 | Overtime badge ("+35m over goal"), date ranges, chart footnotes |

---

## Color (60-30-10 Rule)

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#1C1C1E` (Dark) / `#FFFFFF` (Light) | Scroll background canvas (`AppColors.background`) |
| Secondary (30%) | `#2C2C2E` (Dark) / `#F2F2F7` (Light) | Dashboard cards, chart backgrounds, breakdown tables |
| Accent (10%) | `#7B61FF` (Dark) / `#5C3BFE` (Light) | Circular progress ring, primary buttons, continue play buttons |
| Success | `#30D158` (Dark) / `#34C759` (Light) | Target exceeded ring, overtime badge (`D-04`) |
| Destructive | `#FF453A` (Dark) / `#D70015` (Light) | Deletion and alert destructive actions |

### Swift Charts Project Palette (`D-05`, `D-06`)
- Slices and bars dynamically styled using project hex codes (`Color(hex: project.colorHex)`).
- Fallback for unassigned time: `Color.secondary.opacity(0.4)`.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Dashboard Toolbar Title | "Dashboard" |
| Reports Toolbar Title | "Reports" |
| Daily Goal Target Label | "Daily Target: {hours}h" |
| Goal Completed Status | "Goal Reached!" |
| Goal Overtime Badge | "+{minutes}m over goal" (`D-04`) |
| Weekly Chart Title | "Weekly Activity (Mon – Sun)" |
| Daily Goal Guideline Label | "Target ({hours}h)" |
| Recent Activity Title | "Recent Activity" |
| Breakdown Mode Toggle | "[By Project | By Client]" |
| Date Range Presets | "Today", "This Week", "This Month", "Custom Range" |
| Export Button Label | "Export" |
| Export CSV Option | "Export as CSV..." |
| Export JSON Option | "Export as JSON..." |
| Empty Dashboard State | "No activity tracked today. Start a timer or log past time to view productivity metrics." |
| Empty Reports State | "No time entries recorded for the selected date range." |

---

## Component Specifications

### 1. `DashboardView` & Layout (`D-01`, `D-02`, `D-03`, `D-04`)
- Scrollable view structured as a 2-column or fluid grid:
  - **Left / Top Hero Card**:
    - Circular Progress Ring: 140px diameter.
      - Center: Large duration ("5h 20m"), percentage badge ("67%").
      - Ring Color: Brand accent if < 100%; Success green if >= 100% (`D-04`).
    - Details:
      - Daily Target dropdown button ("Target: 8h ▾") with presets: 4h, 6h, 7.5h, 8h, or custom stepper (`D-02`).
      - Overtime badge if goal exceeded (`+35m over goal`).
      - Remaining time to target.
  - **Right / Bottom Weekly Activity Card (`D-05`)**:
    - Stacked bar chart of Monday to Sunday tracked hours using Swift Charts.
    - Each bar colored by project swatches.
    - Dashed target line (`RuleMark`) representing the daily goal.
  - **Full-Width Recent Activity Section (`D-03`)**:
    - List of last 5 entries with project swatch dot, task name, description, duration badge, and hover "Continue" (`play.fill`) button.

### 2. `ReportsView` & Layout (`D-06`, `D-07`, `D-08`)
- **Toolbar**:
  - Segmented control / dropdown for Date Range: `[Today | This Week | This Month | Custom Range]` (`D-07`).
  - When `Custom Range` selected: Start Date and End Date pickers inline.
  - Segmented picker for breakdown dimension: `[By Project | By Client]`.
  - "Export" menu button: `Export as CSV...` and `Export as JSON...` (`D-08`).
- **Main Analytics Card**:
  - Left: Interactive Donut Chart (`SectorMark(angle: ..., innerRadius: .ratio(0.65))`) with center total duration (`D-06`).
  - Right: Ranked breakdown list:
    - Color swatch dot, Project/Client Name, Total duration ("14h 25m"), Percentage share ("42%"), Progress bar fill.
- **Summary Metrics Strip**:
  - Total Tracked Time, Daily Average, Top Project, and Total Sessions.

### 3. `ExportService` (`D-08`)
- Native macOS `NSSavePanel` trigger.
- **CSV Format**:
  `Date,Start Time,End Time,Duration (Seconds),Duration (Formatted),Description,Project,Client,Task`
- **JSON Format**:
  Structured JSON array with ISO dates, duration seconds, and metadata objects.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-11-23
