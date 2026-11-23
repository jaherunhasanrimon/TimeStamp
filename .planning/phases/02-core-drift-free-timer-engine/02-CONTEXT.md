# Phase 2: Core Drift-Free Timer Engine - Context

**Gathered:** 2026-11-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 implements the core running timer engine and top active timer bar for TimeStamp:
- Wall-clock reference calculation (`Date().timeIntervalSince(startDate) + accumulatedDuration`) ensuring 0% drift across sleep, wake, and minimization (`TIMER-05`).
- Starting a timer with optional description, project, and task (`TIMER-01`).
- Pausing and resuming without losing accumulated duration (`TIMER-02`).
- Stopping a timer and immediately persisting a completed `TimeEntry` to `PersistenceStore` (`TIMER-03`).
- Continuing previous time entries with seamless auto-switching (`TIMER-04`).
- System sleep/wake notification listeners via `NSWorkspace` with instant ticker refresh.
- Auto-restoration of running session on app launch/restart.
- Reusable `ActiveTimerBar` component placed as a global sticky header across all views.

Out of scope for Phase 2:
- Time entries log grouping and list editing (Phase 3).
- Menu bar extra companion and global keyboard shortcut registration (Phase 5).
- Project and Client management CRUD modals (Phase 4).
</domain>

<decisions>
## Implementation Decisions

### Active Timer Bar UI & Placement
- **D-01 (Placement):** Global Sticky Bar — Placed permanently at the top of the main window detail pane across all views (Timer, Calendar, Dashboard, Reports, Settings) so the active timer is always visible and controllable.
- **D-02 (Controls):** Dual Controls — Features a distinct Pause/Resume icon button alongside a prominent Stop button (`#FF375F` / `#D70015`) while running.
- **D-03 (Empty Description):** Starts allowed without description. Saved with empty description `""` in data model, rendered as `(No description)` placeholder in UI displays.
- **D-04 (Project/Task Selector):** Inline Pill Selectors — Compact project color dot + dropdown selector menu inside the timer bar next to the description text field.

### Start/Stop UX & Keyboard Interactions
- **D-05 (Return Key):** Pressing Enter/Return while focused in the description field starts the timer immediately (or stops if currently running).
- **D-06 (Post-Stop Retention):** Clear description text, but retain the last selected Project and Task so users can easily chain sessions within the same project.
- **D-07 (Duration Ticker Format):** Always display full `HH:MM:SS` (e.g. `00:04:12`) in monospaced digits (`AppTypography.ticker`) to prevent layout jitter.
- **D-08 (Discard Action):** Provide a subtle discard button ('X' / trash) next to Stop that aborts the active session without creating a `TimeEntry` in storage.

### Continue Tracking Workflow
- **D-09 (Continue Action):** Clicking 'Continue' immediately starts a brand-new running timer at the current timestamp (`Date()`).
- **D-10 (Running Timer Collision):** Auto-Stop & Switch — If a timer is already running when Continue is clicked, automatically stop and persist the active timer first, then immediately start the continued session seamlessly.
- **D-11 (Session Identity):** Distinct New Entry — Each continuation creates an independent `TimeEntry` to preserve chronological accuracy on timelines and calendars.
- **D-12 (Attribute Cloning):** Full Clone — Copies description, project ID, task ID, and all tag IDs into the newly started session.

### Sleep/Wake & Background Timing Engine
- **D-13 (Sleep Handling):** Continuous Wall-Clock — Tracking runs through sleep without interruption; duration equals exact wall-clock difference (`Date().timeIntervalSince(startDate)`).
- **D-14 (App Quit / Restore):** Auto-Restore Active Session — Persists active timer state to disk; upon app restart, automatically rehydrates the running timer with its original `startDate`.
- **D-15 (Tick Rate):** 1 Hz Cadence — Timer UI publishes on a 1-second cadence on `.common` RunLoop (`<0.1%` CPU consumption on Apple Silicon).
- **D-16 (Sleep/Wake Listener):** `NSWorkspace.willSleepNotification` and `NSWorkspace.didWakeNotification` listeners trigger an immediate timestamp recalculation and UI refresh on wake.

### the agent's Discretion
- Exact layout padding and visual animations when transitioning between idle and running states in `ActiveTimerBar`.
- Design of project dropdown menu items using `AppColors.projectColors`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing:**
- `.planning/REQUIREMENTS.md` — TIMER-01 through TIMER-05 requirements.
- `.planning/research/STACK.md` — Wall-clock delta formula and Timer pitfall avoidance.
- `.planning/research/PITFALLS.md` — Pitfall 1 (Naive `Timer.scheduledTimer` pause on sleep) and Pitfall 5 (Timer Jitter & Monospaced Digits).
- `.planning/phases/01-project-scaffolding-swiftdata-models-app-shell/01-UI-SPEC.md` — Color palette, typography scale (`AppTypography.ticker`), and button dimensions.
- `Sources/Models/TimeEntry.swift` — `TimeEntry` model properties, `effectiveDuration`, and running state flags.
- `Sources/Models/PersistenceStore.swift` — Local storage CRUD methods (`saveTimeEntry`, `deleteTimeEntry`).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PersistenceStore`: In-memory and atomic disk persistence engine ready for saving/deleting completed time entries.
- `TimeEntry`: Model already has `startDate`, `endDate`, `accumulatedDuration`, `isPaused`, and `effectiveDuration`.
- `AppColors.brandAccent`, `AppColors.destructive`: Button tint and styling tokens.
- `AppTypography.ticker`: Monospaced font token (`.system(size: 14, weight: .semibold).monospacedDigit()`).
- `AppSpacing`: Spacing and corner radius tokens (`radiusButton: 8`, `radiusCard: 10`).

### Established Patterns
- `@Observable @MainActor` for reactive state stores.
- Environment injection: `@Environment(PersistenceStore.self)`.
- macOS native view styling with unified toolbar and hidden title bar.

### Integration Points
- `TimerManager`: New `@Observable @MainActor` service managing the active timer state, countdown/countup ticker, and sleep/wake listeners.
- `ActiveTimerBar`: Injected at the top of `DetailContainerView` or window root layout.
- `SkeletonRootView` / `DetailContainerView`: Updated to display the active timer bar above destination content.

</code_context>

<specifics>
## Specific Ideas
- Toggl Track desktop interaction pattern: pressing Enter in the description bar starts the session immediately without requiring mouse clicks.
- Switching between tasks is instantaneous: clicking continue on another item stops current and starts new immediately.

</specifics>

<deferred>
## Deferred Ideas
- Idle Detection prompt ("You were inactive for 15 minutes, keep or discard?") — explicitly deferred to v2.
- Menu Bar item companion — scoped for Phase 5.
- Global system hotkey to toggle timer — scoped for Phase 5.

</deferred>

---

*Phase: 02-core-drift-free-timer-engine*
*Context gathered: 2026-11-23*
