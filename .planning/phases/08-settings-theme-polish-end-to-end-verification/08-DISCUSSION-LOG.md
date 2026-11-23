# Phase 8: Settings, Theme Polish & End-to-End Verification - Discussion Log

**Date:** 2026-11-23  
**Status:** Decisions Locked  
**Phase:** 08-settings-theme-polish-end-to-end-verification  

---

## Discussion Topics & User Selections

### Topic 1: Appearance & Theme Switcher (`SET-01`)
- **Question:** How should the Appearance theme switcher be presented in Settings (SET-01)?
- **Options Presented:**
  1. *(Recommended)* Visual 3-card theme picker (System, Light, Dark) with preview icons, immediately updating the window color scheme via `.preferredColorScheme`.
  2. Standard segmented control `[System | Light | Dark]` in the Appearance settings section.
  3. Dropdown menu in a standard macOS Settings Form.
- **User Selection:** Visual 3-card theme picker (System, Light, Dark) with preview icons, immediately updating the window color scheme via `.preferredColorScheme`.
- **Decision:** **D-01** locked.

### Topic 2: Global Keyboard Shortcut Configuration (`SET-02`)
- **Question:** How should the global keyboard shortcut configuration work in Settings (SET-02)?
- **Options Presented:**
  1. *(Recommended)* Interactive shortcut recorder button (click to record key combination) with preset quick-picks (`⌥⇧T`, `⌃⌥T`, `⌘⇧T`) and conflict validation.
  2. Dropdown list of curated macOS hotkey presets (`⌥⇧T`, `⌃⌥T`, `⌘⌥T`, `⌥Space`).
  3. Display current shortcut (`⌥⇧T`) with enable/disable toggle.
- **User Selection:** Interactive shortcut recorder button with preset quick-picks and conflict validation.
- **Decision:** **D-02** locked.

### Topic 3: Timer & Menu Bar Preferences (`SET-03`)
- **Question:** What timer behaviors and defaults should be configurable in Timer Preferences (SET-03)?
- **Options Presented:**
  1. *(Recommended)* Default Project selector (None or select a project), Menu Bar format picker (Icon + Duration, Duration Only, Icon Only), and sound effect toggles.
  2. Simple Default Project dropdown and confirmation prompt on timer discard.
  3. Advanced timer options including idle timeout reminder and daily goal reminder.
- **User Selection:** Default Project selector, Menu Bar format picker, and sound effect toggles.
- **Decision:** **D-03** locked.

### Topic 4: Data Management Utilities (`SET-03`)
- **Question:** Should Settings include Data Management utilities (Load Sample Data / Reset All Data)?
- **Options Presented:**
  1. *(Recommended)* Yes, include a Data Management section with "Load Sample Data" for testing and "Reset All Data" with a destructive confirmation dialog.
  2. Include only "Clear All Data" with confirmation, without sample data loading.
  3. Omit Data Management from Settings; keep it strictly for preferences.
- **User Selection:** Yes, include a Data Management section with "Load Sample Data" for testing and "Reset All Data" with a destructive confirmation dialog.
- **Decision:** **D-04** locked.

---

## Downstream Impact
- Research & Planning will focus on:
  - Theme preference storage and window-level `.preferredColorScheme` resolution in `TimeStampApp.swift`.
  - Enhancing `GlobalHotkeyManager` to support dynamic modifier/keycode re-registration.
  - Interactive shortcut recorder SwiftUI component.
  - Settings sections and routing in `DetailContainerView`.
  - End-to-end regression test suite verifying all 35 v1 requirements.
