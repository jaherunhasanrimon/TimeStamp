---
phase: 03
slug: time-entries-log-manual-tracking
status: approved
shadcn_initialized: false
preset: macos-native
created: 2026-11-23
---

# Phase 3 — UI Design Contract: Time Entries Log & Manual Tracking

> Visual and interaction contract for Phase 3 Time Entries list, daily grouped headers, entry rows, and the modal edit/manual logging sheet. Inherits core tokens from `01-UI-SPEC.md` and locks decisions D-01 through D-16.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Native SwiftUI (macOS 14+) |
| Preset | macOS Native Human Interface Guidelines |
| Component library | Native SwiftUI Views & Modifiers |
| Icon library | SF Symbols 5 (`play.fill`, `trash`, `pencil`, `calendar`, `clock`, `folder`, `tag`) |
| Font | San Francisco (System & Monospaced Digits) |

---

## Spacing Scale

Declared values (conforming to 4pt grid in `AppSpacing`):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Swatch-to-text gaps, tag pill padding, inline icons |
| sm | 8px | Button padding, row vertical padding, time range gap |
| md | 16px | List horizontal padding, day header padding, modal padding |
| lg | 24px | Section separation between day groups |
| xl | 32px | Empty state layout spacing, modal outer margins |
| 2xl | 48px | Major view padding |
| 3xl | 64px | Page-level spacing |

Exceptions:
- Entry Row height: minimum 44px
- Day Group Header height: 36px
- Edit/Log Modal Sheet size: fixed width 460px, height ~420px

---

## Typography

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Day Header Date | 14pt | Semibold | 1.2 | "Today", "Yesterday", "Mon, Nov 21" (`D-01`) |
| Day Header Total | 13pt | Medium | 1.2 | Total time e.g. "4h 15m" (`D-02`) |
| Entry Description | 13pt | Regular | 1.3 | Entry description or "(No description)" placeholder |
| Project Badge | 12pt | Medium | 1.2 | Project name and Task indicator badge |
| Time Range | 11pt | Regular | 1.2 | Start - End timestamp e.g. "09:30 - 11:15" (`D-03`) |
| Row Duration | 13pt | Medium | 1.0 (`monospacedDigit()`) | Elapsed session duration "01:45:00" |
| Caption | 11pt | Regular | 1.2 | Form hints, keyboard shortcuts ("⌘N") |

---

## Color (60-30-10 Rule)

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#1C1C1E` (Dark) / `#FFFFFF` (Light) | Window background, entries scroll area |
| Secondary (30%) | `#2C2C2E` (Dark) / `#F2F2F7` (Light) | Day group cards, entry row backgrounds, edit sheet background |
| Accent (10%) | `#7B61FF` (Dark) / `#5C3BFE` (Light) | "+ Log Time" button, Continue hover button, Save button |
| Destructive | `#FF453A` (Dark) / `#D70015` (Light) | Delete button, Confirmation alert destructive action |

Accent reserved for:
1. Primary "+ Log Time" button in entries header
2. Save / Add Entry button in modal sheet
3. Continue icon button on row hover
4. Selected project swatch ring

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary List Action | "+ Log Time" |
| Day Group Date Today | "Today" |
| Day Group Date Yesterday | "Yesterday" |
| Empty State Heading | "No time entries yet" |
| Empty State Body | "Start the timer in the top bar or press ⌘N to log past work." |
| Edit Modal Title | "Edit Time Entry" |
| Log Modal Title | "Log Time Entry" |
| Modal Primary CTA (Edit) | "Save Changes" |
| Modal Primary CTA (Log) | "Add Entry" |
| Modal Secondary CTA | "Cancel" |
| Delete Confirmation Title | "Delete Time Entry?" |
| Delete Confirmation Message | "Are you sure you want to delete this time entry? This action cannot be undone." |
| Delete Confirmation CTA | "Delete" |

---

## Component Specifications

### 1. `DayGroupView` & `DayGroupHeaderView`
- Sticky or section header with subtle divider:
  - Left: Relative date ("Today", "Yesterday", "Mon, Nov 21") in `AppTypography.heading` (14pt semibold).
  - Right: Total tracked time ("4h 15m") in `secondary` text color.
- Contains child `TimeEntryRowView` items.

### 2. `TimeEntryRowView`
- Row height: 44px min with rounded corners (`AppSpacing.radiusSmall`) and subtle hover effect.
- Left:
  - If project assigned: Color dot circle (8px) + Project Name in `AppTypography.label`.
  - If task assigned: "•" + Task Name in `AppTypography.caption`.
  - Description text in `AppTypography.body`.
- Right:
  - Time range: `09:30 - 11:15` in `AppTypography.caption` (`.secondary`).
  - Duration: `01:45:00` in `AppTypography.subTicker`.
  - Hover Action Container:
    - Continue button (`play.fill` circle, starts new timer via `timerManager.continueEntry`).
    - More options / Delete button (`trash` icon, triggers confirmation alert).
- Context Menu:
  - "Continue Timer"
  - "Edit..."
  - "Duplicate Entry"
  - Divider
  - "Delete..." (with destructive role)

### 3. `EntryEditSheet` (Used for both Edit and Manual Log)
- Sheet size: 460px width, ~420px height.
- Form fields:
  - Description field ("What did you work on?").
  - Project & Task picker (`ProjectTaskPickerButton`).
  - Date picker (Calendar Date).
  - Start Time picker (Hour : Minute).
  - End Time picker (Hour : Minute).
  - Duration field (Synchronized with start/end time pickers).
- Validation:
  - If start time > end time, end time automatically adjusts to `startDate + duration` (`D-06`).
- Actions:
  - Cancel button (dismisses sheet without saving).
  - Primary button ("Save Changes" for edit, "Add Entry" for manual log).

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-11-23
