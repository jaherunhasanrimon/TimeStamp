---
phase: 02
slug: core-drift-free-timer-engine
status: approved
shadcn_initialized: false
preset: macos-native
created: 2026-11-23
---

# Phase 2 — UI Design Contract: Active Timer Bar & Timer Engine

> Visual and interaction contract for Phase 2 Active Timer Bar, duration ticker, and controls. Inherits core tokens from `01-UI-SPEC.md` and locks decisions D-01 through D-16.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Native SwiftUI (macOS 14+) |
| Preset | macOS Native Human Interface Guidelines |
| Component library | Native SwiftUI Views & Modifiers |
| Icon library | SF Symbols 5 (`play.fill`, `pause.fill`, `stop.fill`, `xmark`, `folder`, `circle.fill`) |
| Font | San Francisco (System & Monospaced Digits) |

---

## Spacing Scale

Declared values (conforming to 4pt grid in `AppSpacing`):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-text gaps, inline padding, swatch padding |
| sm | 8px | Button internal padding, pill selector padding, vertical bar padding |
| md | 16px | Timer bar horizontal padding, inter-control spacing |
| lg | 24px | Section separation |
| xl | 32px | Outer container margins |
| 2xl | 48px | Empty states and large breaks |
| 3xl | 64px | Page-level spacing |

Exceptions:
- Active Timer Bar height: fixed 56px height with 1px bottom border stroke (`AppColors.subtleBorder`).

---

## Typography

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Body | 13pt | Regular | 1.3 | Description input text field ("What are you working on?") |
| Label | 12pt | Medium | 1.2 | Project / Task pill text, button labels |
| Heading | 20pt | Semibold | 1.2 | Detail view headers |
| Ticker | 14pt | Semibold | 1.0 (`monospacedDigit()`) | Live running duration (`HH:MM:SS`) |
| Caption | 11pt | Regular | 1.2 | Tooltips, shortcut hint labels |

---

## Color (60-30-10 Rule)

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#1C1C1E` (Dark) / `#FFFFFF` (Light) | Window background, detail container |
| Secondary (30%) | `#2C2C2E` (Dark) / `#F2F2F7` (Light) | Active Timer Bar surface, project selector pill, cards |
| Accent (10%) | `#7B61FF` (Dark) / `#5C3BFE` (Light) | Start/Play button background, active project dot, focused state |
| Destructive | `#FF453A` (Dark) / `#D70015` (Light) | Stop button (`#FF375F` / `#D70015`), Discard active session |

Accent reserved for:
1. Start/Play button background (`AppColors.brandAccent`)
2. Selected project indicator dot and active focus rings
3. Running state pulse indicator

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Description Input Placeholder | "What are you working on?" |
| Project Selector Placeholder | "Add Project" |
| Empty Description In Logs | "(No description)" |
| Start Button Tooltip | "Start timer (Return)" |
| Pause Button Tooltip | "Pause timer" |
| Resume Button Tooltip | "Resume timer" |
| Stop Button Tooltip | "Stop & save entry (Return)" |
| Discard Button Tooltip | "Discard timer without saving" |
| Idle Duration Placeholder | "00:00:00" |

---

## Component Specifications: ActiveTimerBar

### Layout Hierarchy
```
HStack(spacing: AppSpacing.md) {
  // Left: Description Input
  TextField("What are you working on?", text: $description)
    .font(AppTypography.body)

  // Middle-Left: Project & Task Pill Selector
  ProjectTaskPickerButton(selectedProject: $project, selectedTask: $task)

  Spacer()

  // Middle-Right: Monospaced Live Duration Ticker
  Text(formattedDuration)
    .font(AppTypography.ticker)

  // Right: Controls
  if isRunning {
    Button(action: togglePause) { ... } // Pause/Resume
    Button(action: stop) { ... }        // Stop (Square)
    Button(action: discard) { ... }     // Discard (X)
  } else {
    Button(action: start) { ... }       // Start (Play)
  }
}
.frame(height: 56)
.padding(.horizontal, AppSpacing.md)
.background(AppColors.cardBackground)
.overlay(alignment: .bottom) { Divider() }
```

### Visual & Interactive States
1. **Idle State**:
   - Description input is empty with placeholder.
   - Project selector shows "+ Add Project" or last retained project (D-06).
   - Ticker displays "00:00:00" in secondary color.
   - Large Play button with `AppColors.brandAccent` tint.
2. **Running State**:
   - Description input editable live.
   - Ticker updates every 1 second in `primary` text color.
   - Pause button with `pause.fill` icon.
   - Stop button with `stop.fill` icon on `#FF375F` / `#D70015` rounded rectangle.
   - Subtle discard button ('xmark') with secondary tint.
3. **Paused State**:
   - Ticker pauses at current accrued duration in `secondary` text color.
   - Pause button toggles to `play.fill` ("Resume").
   - Stop button remains active to save paused duration as completed session.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| Pure Native SwiftUI | None | Built-in Apple framework |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-11-23
