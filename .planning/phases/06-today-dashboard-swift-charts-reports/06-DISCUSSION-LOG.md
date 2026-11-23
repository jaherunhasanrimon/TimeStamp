# Phase 6: Today Dashboard & Swift Charts Reports - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-23
**Phase:** 06-today-dashboard-swift-charts-reports
**Areas discussed:** Today Dashboard Layout & Daily Target, Weekly Activity Bar Chart Presentation, Reports Analytics & Distribution Visuals, Export Service & File Delivery UX

---

## Today Dashboard Layout & Daily Target

| Option | Description | Selected |
|--------|-------------|----------|
| Hero card with circular progress ring | Large duration (5h 20m), percentage badge, and smooth circular ring with high visual impact | ✓ |
| Horizontal progress bar | Compact bar spanning top with target label ('5h 20m of 8h 00m') | |
| Multi-stat grid card | Four-square grid: Today total, Weekly total, Remaining, and Streak | |

**User's choice:** Hero card with circular progress ring.
**Notes:** Provides an engaging, glanceable daily summary consistent with modern macOS productivity software.

---

## Daily Target Configuration

| Option | Description | Selected |
|--------|-------------|----------|
| 8 hours default with inline click-to-edit target | Dropdown presets: 4h, 6h, 7.5h, 8h, or custom value | ✓ |
| Fixed 8 hours default without inline editing | Reserved for Phase 8 Settings only | |
| Dynamic average based on past 7 days | Auto-adjusting goal | |

**User's choice:** 8 hours default with inline click-to-edit target.
**Notes:** Immediate flexibility for users with part-time or non-standard workday lengths.

---

## Recent Activity Presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Top 5 recent entries with hover 'Continue' button | Project swatch, duration badge, and play button for instant resumption | ✓ |
| Full scrollable list of all today's entries | Comprehensive table with inline editing | |
| Compact project breakdown summary | Summary pills with hours per project | |

**User's choice:** Top 5 recent entries with hover 'Continue' button.
**Notes:** Enables frictionless re-tracking directly from the dashboard.

---

## Target Exceeded Visual State

| Option | Description | Selected |
|--------|-------------|----------|
| Success celebration state | Green success accent ring and '+Xm over goal' badge | ✓ |
| Ring wraps around with overlapping accent color | Multi-layer ring | |
| Cap progress at 100% | No overtime indication | |

**User's choice:** Success celebration state with green accent and overtime badge.
**Notes:** Encouraging visual feedback for productive days.

---

## Weekly Activity Bar Chart

| Option | Description | Selected |
|--------|-------------|----------|
| Stacked bar chart by project color (Mon–Sun) with dashed goal line | Instant visual attribution of time across projects with target comparison | ✓ |
| Monochrome brand accent bars | Single-color bars with duration labels | |
| Grouped side-by-side bars | Comparing current week vs previous week | |

**User's choice:** Stacked bar chart by project color with dashed daily goal line.
**Notes:** Swift Charts `BarMark` with `foregroundStyle(by:)` project mapping.

---

## Reports Analytics & Distribution Visuals

| Option | Description | Selected |
|--------|-------------|----------|
| Donut Chart (SectorMark) with center total + ranked breakdown list | Interactive, clean Toggl-style visual analytics with project/client toggling | ✓ |
| Horizontal ranked bar chart | Simple bar list | |
| Separate tabbed views | Separate pages for project and client breakdowns | |

**User's choice:** Donut Chart with center total and ranked breakdown list.
**Notes:** Standard modern analytics pattern with slice hover tooltips.

---

## Reports Date Range Filters

| Option | Description | Selected |
|--------|-------------|----------|
| Presets + Custom Range | [Today \| This Week \| This Month \| Custom Range] with date pickers | ✓ |
| Rolling presets | [Last 7 Days \| Last 30 Days \| Last 90 Days \| YTD] | |
| Monthly calendar picker only | Month-by-month navigation | |

**User's choice:** Presets + Custom Range (`[Today | This Week | This Month | Custom Range]`).
**Notes:** Covers 99% of reporting workflows with full custom date flexibility.

---

## Export Service & File Delivery UX

| Option | Description | Selected |
|--------|-------------|----------|
| Export dropdown in Reports toolbar via NSSavePanel | 'Export CSV' and 'Export JSON' with formatted date filename | ✓ |
| Automatic save to ~/Downloads folder | Direct download with banner | |
| Export preview sheet | Pre-export modal review | |

**User's choice:** Export dropdown in Reports toolbar via native `NSSavePanel`.
**Notes:** Native macOS file save experience allowing user to select save location.

---

## the agent's Discretion

- Micro-spacing, card corner radii, and drop shadows on dashboard cards.
- Chart hover tooltips and selection highlight styles in Swift Charts.
- Date formatting helpers for CSV/JSON export serialization.

## Deferred Ideas

- Scheduled automated email or PDF reports export (deferred to future backlog).
- Team member time comparison analytics (v2 requirement).
