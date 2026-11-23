---
phase: 07
slug: interactive-calendar-timeline-view
status: approved
shadcn_initialized: false
preset: macos-native
created: 2026-11-23
---

# Phase 7 — UI Design Contract: Interactive Calendar Timeline View

> Visual and interaction design contract for Phase 7 Interactive Calendar Timeline View, 24-hour vertical time grid, side-by-side overlap partitioning, multi-column week timeline, live current-time indicator line, and calendar block inspector popover. Inherits core tokens from `01-UI-SPEC.md` and locks decisions D-01 through D-06.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Native SwiftUI (macOS 14+) |
| Preset | macOS Native Human Interface Guidelines |
| Component library | Native SwiftUI Views & Modifiers (`ScrollViewReader`, `GeometryReader`, `.popover`) |
| Icon library | SF Symbols 5 (`calendar`, `calendar.day.timeline.left`, `chevron.left`, `chevron.right`, `clock`, `play.fill`, `pencil`, `trash`, `circle.fill`) |
| Font | San Francisco (System & Monospaced Digits) |

---

## Spacing Scale

Declared values (conforming to 4pt grid in `AppSpacing`):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Gaps between sub-column blocks, icon gaps in popover |
| sm | 8px | Button padding, popover content spacing, block corner radius |
| md | 16px | Section padding, toolbar controls gap, column header padding |
| lg | 24px | Date navigation cluster spacing |
| xl | 32px | Outer container margins |
| 2xl | 48px | Empty state layout spacing |

### Geometric Exceptions
- **Hour Row Height:** 60px (1px per minute scale, 1440px total vertical grid height) (`D-01`).
- **Left Time Gutter Width:** 56px (for hour labels `00:00` – `23:00`).
- **Minimum Block Height:** 24px (ensures text readability for short entries < 15 min).
- **Sub-column Spacing:** 2px gap between adjacent overlapping entry blocks.
- **Current Time Marker:** 2px stroke line with 8px circular indicator dot.
- **Popover Inspector:** Fixed width 280px, corner radius 10px (`AppSpacing.radiusCard`).

---

## Typography

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Calendar Header Title | 18pt | Bold | 1.2 | "Monday, Nov 23, 2026" or "Nov 17 – Nov 23, 2026" (`D-02`) |
| Column Day Label | 12pt | Medium | 1.1 | "Mon 23", "Tue 24" in Week view headers |
| Column Total Duration | 11pt | Regular | 1.1 (`monospacedDigit()`) | Day summary duration in week header ("5h 20m") |
| Hour Gutter Label | 11pt | Regular | 1.0 (`monospacedDigit()`) | "08:00", "09:00", "10:00" in left gutter |
| Time Block Title | 12pt | Semibold | 1.2 | Entry description / Project name inside time block |
| Time Block Time Range | 10pt | Regular | 1.1 (`monospacedDigit()`) | "10:00 – 11:30" inside time block |
| Popover Title | 15pt | Semibold | 1.2 | Entry description in inspector popover |
| Popover Duration | 16pt | Bold | 1.1 (`monospacedDigit()`) | Total duration ticker in inspector |

---

## Color (60-30-10 Rule)

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#1C1C1E` (Dark) / `#FFFFFF` (Light) | Calendar scroll canvas (`AppColors.background`) |
| Secondary (30%) | `#2C2C2E` (Dark) / `#F2F2F7` (Light) | Week header background, hour grid lines, gutter background |
| Accent (10%) | `#7B61FF` (Dark) / `#5C3BFE` (Light) | Active timer pulse, "Today" button, primary buttons |
| Current Time Line | `#FF3B30` (Red) / `#7B61FF` | Live horizontal minute marker and dot (`D-04`) |
| Time Blocks | Dynamic Hex | Project swatch color (`Color(hex: project.colorHex)`) with 85% opacity fill and solid border |

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Calendar Toolbar Title | "Calendar" |
| View Mode Picker | `[Day | Week]` |
| Today Quick-Jump Button | "Today" |
| Previous Date Tooltip | "Previous Day" / "Previous Week" |
| Next Date Tooltip | "Next Day" / "Next Week" |
| Empty Day State | "No time entries recorded for this day." |
| Empty Week State | "No time entries recorded for this week." |
| Popover Continue Button | "Continue" |
| Popover Edit Button | "Edit Details..." |
| Popover Delete Button | "Delete Entry" |
| Active Timer Status | "Tracking Now" |

---

## Component Specifications

### 1. `CalendarTimelineView` (Root Calendar Screen)
- **Toolbar**:
  - Segmented control: `[Day | Week]` (`D-02`).
  - Navigation Cluster:
    - `<` Previous and `>` Next buttons.
    - "Today" button.
    - Dynamic date title (`Monday, Nov 23, 2026` or `Nov 17 – Nov 23, 2026`).
- **Body**:
  - If mode == `.day`: renders `DayTimelineGridView`.
  - If mode == `.week`: renders `WeekTimelineGridView`.

### 2. `DayTimelineGridView` (`CAL-01`)
- Scrollable vertical 24-hour canvas (1440px height).
- Hour grid: 24 horizontal rows at 60px height.
- Left gutter (56px) displaying hour labels (`00:00` to `23:00`).
- Auto-scrolls on appear to `max(0, currentHour - 1)` via `ScrollViewReader` (`D-01`).
- Side-by-side sub-columns algorithm partitioning overlapping entries across the full column width (`D-03`).
- Current time line with circular marker on today (`D-04`).
- Active running timer dynamically pinned to current time (`D-05`).

### 3. `WeekTimelineGridView` (`CAL-02`)
- Top sticky header bar displaying 7 day columns (Monday to Sunday) with day abbreviation, date number, and total tracked time.
- Synchronized vertical scrollable 24-hour grid divided into 7 equal-width columns.
- Each column executes the sub-column overlap layout algorithm for that day's entries.
- Current-time indicator displays only on today's column.

### 4. `CalendarBlockView` & Popover Inspector (`CAL-03`)
- Time block positioned with `GeometryReader`:
  - `y = startMinutes * (60.0 / 60.0)`
  - `height = max(24.0, durationMinutes * (60.0 / 60.0))`
  - `x = subColumnIndex * subColumnWidth`
  - `width = subColumnWidth - 2px`
- Rounded rectangle (radius: 6px) with project color background, border, description, and time range.
- Click gesture opens macOS popover (`.popover(item: ...)`):
  - Project color dot & name.
  - Task name if present.
  - Formatted time range ("10:00 AM – 11:30 AM") & duration ("1h 30m").
  - Description.
  - Actions: "Continue" (`play.fill`) and "Edit Details..." (`pencil`).

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-11-23
