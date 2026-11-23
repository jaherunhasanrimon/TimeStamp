# Phase 8: Settings, Theme Polish & End-to-End Verification - Context

**Gathered:** 2026-11-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 8 is the final milestone phase for TimeStamp v1.0:
- Settings screen with modular sections: Appearance, Shortcuts, Timer & Menu Bar, and Data Management (`SET-01`, `SET-02`, `SET-03`).
- Theme switching across System, Light, and Dark modes with visual cards, updating the app window live via `.preferredColorScheme` and persisting across app restarts (`SET-01`).
- Global keyboard shortcut configuration with interactive shortcut recorder button, curated presets (`⌥⇧T`, `⌃⌥T`, `⌘⇧T`), and dynamic `GlobalHotkeyManager` re-registration (`SET-02`).
- Timer preferences including Default Project assignment, Menu Bar ticker display format (`Icon + Duration`, `Duration Only`, `Icon Only`), and timer sound effect toggles (`SET-03`).
- Data Management utilities featuring "Load Sample Data" (seeding test data via `PreviewContainer`) and "Reset All Data" with a destructive macOS confirmation alert dialog (`SET-03`).
- Routing integration into `SidebarDestination.settings` in `DetailContainerView`.
- End-to-end verification pass ensuring all 35 v1 requirements operate without regression.

Out of scope for Phase 8:
- CloudKit / iCloud cross-device sync (v2).
- Google Calendar / Apple Calendar API event sync (v2).
- User authentication and team billing roles (v2).
</domain>

<decisions>
## Implementation Decisions

### 1. Appearance & Theme Switching (`SET-01`)
- **D-01 (Visual Theme Picker):** Visual 3-card theme picker (`System`, `Light`, `Dark`) featuring SF Symbol icons (`circle.lefthalf.filled`, `sun.max.fill`, `moon.stars.fill`).
  - Stored in `@AppStorage("appTheme") private var appTheme: String = "system"`.
  - Applied to the root window view via `.preferredColorScheme(resolvedColorScheme)`.
  - Persists across app launches and respects macOS system appearance when "System" is selected.

### 2. Global Keyboard Shortcut Configuration (`SET-02`)
- **D-02 (Interactive Shortcut Recorder & Presets):**
  - Interactive recorder button: clicking enters recording mode ("Type shortcut..."), capturing pressed modifiers (`⌥`, `⇧`, `⌃`, `⌘`) and keycode.
  - Quick-pick preset chips: `⌥⇧T` (default), `⌃⌥T`, `⌘⇧T`.
  - Updates `GlobalHotkeyManager.shared` by unregistering the existing Carbon hotkey and registering the new configuration.
  - Persists hotkey modifiers and keycode in `@AppStorage`.

### 3. Timer & Menu Bar Preferences (`SET-03`)
- **D-03 (Timer Behavior & Menu Bar Format):**
  - **Default Project:** Picker allowing selection of "None (Select on start)" or any user project from `store.projects`. New timer sessions pre-fill this project.
  - **Menu Bar Ticker Format:** Segmented picker for `[Icon + Duration | Duration Only | Icon Only]`, dynamically updating `MenuBarLabelView`.
  - **Timer Sounds:** Toggle for audio feedback on timer start/stop (`NSSound.beep()` or subtle native system sound), stored in `@AppStorage("playTimerSounds")`.

### 4. Data Management & Utilities (`SET-03`)
- **D-04 (Sample Data & Factory Reset):**
  - "Load Sample Data" button calling `PreviewContainer.seedSampleData(store: store)` with confirmation notice.
  - "Reset All Data" destructive red button presenting a macOS modal alert dialog ("Are you sure you want to delete all projects, clients, and time entries? This cannot be undone."). On confirmation, clears persistence store via `store.clearAll()`.

### 5. Settings Layout & Organization
- **D-05 (Settings Presentation):** Clean macOS Settings canvas organized with rounded card sections (`AppColors.cardBackground`, `AppSpacing.radiusCard`), standard 16pt headings, and informative caption descriptions for each preference option.

### 6. Full End-to-End Verification
- **D-06 (35/35 Requirements Sign-Off):** Comprehensive automated test pass across all 12+ test suites verifying 100% compliance with every requirement from `TIMER-01` through `SET-03`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing:**

### Domain Models & Persistence
- `Sources/Models/PersistenceStore.swift` — `clearAll()`, `projects`, `clients`, `timeEntries`.
- `Sources/Models/PreviewContainer.swift` — `seedSampleData(store:)`.
- `Sources/Core/Hotkeys/GlobalHotkeyManager.swift` — Dynamic hotkey registration and key event handling.
- `Sources/Core/Timer/TimerManager.swift` — Timer controls and active session.

### Design System & Layout
- `Sources/DesignSystem/Colors.swift` — Semantic colors, card backgrounds, and brand accents.
- `Sources/DesignSystem/Typography.swift` — Type scale.
- `Sources/Views/Navigation/DetailContainerView.swift` — Routing for `.settings`.
- `Sources/Views/MenuBar/MenuBarLabelView.swift` — Menu bar ticker appearance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PreviewContainer.seedSampleData(store:)` already exists and can be invoked directly by the "Load Sample Data" action.
- `GlobalHotkeyManager.shared` has `register()` and `unregister()` methods; we can parameterize it to accept custom modifiers and keycodes.
- `store.clearAll()` already wipes clients, projects, tasks, tags, and time entries safely.

### Established Patterns
- `@AppStorage` for lightweight user preferences.
- Native SwiftUI `.preferredColorScheme(...)`.
- Modern Swift Testing (`import Testing`) with `@MainActor` suites.
</code_context>
