---
phase: 08
slug: settings-theme-polish-end-to-end-verification
status: approved
shadcn_initialized: false
preset: macos-native
created: 2026-11-23
---

# Phase 8 — UI Design Contract: Settings, Theme Polish & End-to-End Verification

> Visual and interaction design contract for Phase 8 Settings Screen, visual 3-card Theme Picker, interactive Keyboard Shortcut Recorder, Timer & Menu Bar Preferences, Data Management utilities, and End-to-End Verification. Inherits core tokens from `01-UI-SPEC.md` and locks decisions D-01 through D-06.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Native SwiftUI (macOS 14+) |
| Preset | macOS Native Human Interface Guidelines |
| Component library | Native SwiftUI Form & Section Cards (`RoundedRectangle`, `@AppStorage`, `.preferredColorScheme`, `.alert`) |
| Icon library | SF Symbols 5 (`gearshape`, `circle.lefthalf.filled`, `sun.max.fill`, `moon.stars.fill`, `keyboard`, `timer`, `menubar.rectangle`, `speaker.wave.2`, `cylinder.split.1x2`, `arrow.triangle.2.circlepath`, `trash.fill`) |
| Font | San Francisco (System & Monospaced Digits) |

---

## Spacing Scale

Declared values (conforming to 4pt grid in `AppSpacing`):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Gaps inside shortcut chips, icon gaps |
| sm | 8px | Button padding, preset chip spacing, form row padding |
| md | 16px | Card internal padding, spacing between preference rows |
| lg | 24px | Section separation gap between cards |
| xl | 32px | Outer scroll margins and canvas padding |
| 2xl | 48px | Empty/alert layout spacing |

### Geometric Exceptions
- **Theme Card:** Width 110px, Height 80px, Corner Radius 8px (`AppSpacing.radiusSmall`).
- **Shortcut Chip:** Height 28px, Horizontal padding 10px, Corner Radius 6px.
- **Section Card Container:** Full width (max 680px), Corner Radius 10px (`AppSpacing.radiusCard`).
- **Destructive Button:** Red tinted button styling for Reset All Data.

---

## Typography

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Settings Section Title | 16pt | Semibold | 1.2 | "Appearance", "Keyboard Shortcuts", "Timer & Menu Bar", "Data Management" |
| Preference Label | 13pt | Medium | 1.3 | "Default Project", "Menu Bar Ticker Format", "Play Timer Sounds" |
| Preference Description | 11pt | Regular | 1.2 | Explanatory helper text beneath preference labels |
| Theme Card Label | 12pt | Medium | 1.2 | "System", "Light", "Dark" |
| Shortcut Ticker | 13pt | Semibold | 1.0 (`monospacedDigit()`) | "⌥⇧T", "⌃⌥T", "⌘⇧T" |
| Destructive Button Title | 13pt | Semibold | 1.2 | "Reset All Data..." |

---

## Color (60-30-10 Rule)

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#1C1C1E` (Dark) / `#FFFFFF` (Light) | Settings scroll canvas (`AppColors.background`) |
| Secondary (30%) | `#2C2C2E` (Dark) / `#F2F2F7` (Light) | Section cards, theme card inactive fill, chip background (`AppColors.cardBackground`) |
| Accent (10%) | `#7B61FF` (Dark) / `#5C3BFE` (Light) | Active theme card border, selected preset chip, recording state highlight (`AppColors.brandAccent`) |
| Destructive | `#FF453A` (Dark) / `#D70015` (Light) | Reset all data button and destructive alert confirmations |
| Success | `#30D158` (Dark) / `#34C759` (Light) | Sample data loaded notification badge |

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Settings Toolbar Title | "Settings" |
| Appearance Section Header | "Appearance" |
| Appearance Section Subtitle | "Choose how TimeStamp looks on your Mac." |
| Theme Labels | "System", "Light", "Dark" |
| Shortcuts Section Header | "Keyboard Shortcuts" |
| Shortcuts Section Subtitle | "Control the timer from any application across macOS." |
| Global Hotkey Label | "Global Timer Toggle" |
| Shortcut Recorder Idle | "⌥⇧T" (or user key) |
| Shortcut Recorder Active | "Type Shortcut..." |
| Preset Chips Label | "Quick Presets:" |
| Timer Preferences Header | "Timer & Menu Bar" |
| Default Project Label | "Default Project" |
| Default Project Description | "Automatically assign this project to newly started timers." |
| Menu Bar Format Label | "Menu Bar Display" |
| Menu Bar Format Description | "Choose what information appears in your macOS menu bar." |
| Menu Bar Format Options | "Icon & Duration", "Duration Only", "Icon Only" |
| Timer Sounds Label | "Play Timer Sounds" |
| Timer Sounds Description | "Play a subtle audio confirmation when starting or stopping a timer." |
| Data Management Header | "Data Management" |
| Load Sample Data Button | "Load Sample Data" |
| Load Sample Data Description | "Populates your workspace with example projects, tasks, and time entries for testing." |
| Reset Data Button | "Reset All Data..." |
| Reset Confirmation Title | "Reset All Data?" |
| Reset Confirmation Message | "This will permanently delete all projects, clients, tasks, and time entries. This action cannot be undone." |
| Reset Cancel Action | "Cancel" |
| Reset Confirm Action | "Reset Everything" |

---

## Component Specifications

### 1. `SettingsView` (Root Screen)
- Scrollable canvas with maximum content width of 680px centered.
- Padded with `AppSpacing.xl` margins.
- Stacks four modular sections:
  1. `AppearanceSectionView`
  2. `ShortcutsSectionView`
  3. `TimerPreferencesSectionView`
  4. `DataManagementSectionView`

### 2. `AppearanceSectionView` (`SET-01`, `D-01`)
- Visual 3-card picker (`System`, `Light`, `Dark`).
- Each card:
  - SF Symbol icon (`circle.lefthalf.filled` for System, `sun.max.fill` for Light, `moon.stars.fill` for Dark).
  - Title text.
  - Active selection highlighted with `AppColors.brandAccent` 2px border and subtle accent background tint.
- Stored in `@AppStorage("appTheme")` and applied to `WindowGroup` in `TimeStampApp.swift`.

### 3. `ShortcutsSectionView` (`SET-02`, `D-02`)
- Global Timer Toggle row with interactive recorder button:
  - Default: `⌥⇧T`.
  - Clicking enters recording mode with pulsing accent border and prompt "Type Shortcut...".
  - Pressing a modifier + key combination saves the shortcut and updates `GlobalHotkeyManager.shared`.
  - Pressing Escape cancels recording.
- Preset chips row: `⌥⇧T`, `⌃⌥T`, `⌘⇧T`. Clicking instantly applies the preset.

### 4. `TimerPreferencesSectionView` (`SET-03`, `D-03`)
- Default Project dropdown:
  - Options: "None (Select on start)" + list of active projects from `store.projects`.
  - Persisted in `@AppStorage("defaultProjectId")`.
- Menu Bar Display segmented picker:
  - `[Icon & Duration | Duration Only | Icon Only]`.
  - Persisted in `@AppStorage("menuBarDisplayFormat")`.
- Play Timer Sounds toggle:
  - Persisted in `@AppStorage("playTimerSounds")`.

### 5. `DataManagementSectionView` (`SET-03`, `D-04`)
- Load Sample Data button calling `PreviewContainer.seedSampleData(store: store)` with feedback banner.
- Reset All Data destructive button:
  - Shows `.alert("Reset All Data?", isPresented: $showResetAlert)` with role: `.destructive`.
  - Wipes all storage via `store.clearAll()`.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-11-23
