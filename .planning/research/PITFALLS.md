# Pitfalls Research

**Domain:** Native macOS Desktop Time Tracking (Swift & SwiftUI)
**Researched:** 2026-11-23
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Timer Drift Across Sleep, Wake, and App Nap

**What goes wrong:**
When a Mac laptop closes its lid or enters low-power sleep/App Nap, scheduled timers (`Timer.publish` or `DispatchSourceTimer`) cease firing. If the timer logic naively relies on incrementing `elapsedSeconds += 1` on each tick, hours of tracked time will be silently lost when waking up.

**Why it happens:**
Developers assume `Timer` is an accurate clock rather than an execution trigger.

**How to avoid:**
1. Record an absolute wall-clock `startDate = Date()` when starting/resuming.
2. During pauses, calculate the delta and store in `accumulatedDuration`, setting `startDate = nil`.
3. In the UI tick (which only runs when the UI is visible), calculate `currentDuration = accumulatedDuration + Date.now.timeIntervalSince(startDate)`.
4. Register for `NSWorkspace.willSleepNotification` and `didWakeNotification` to reconcile state on wake.

**Phase to address:** Phase 2 (Core Timer Engine).

---

### Pitfall 2: SwiftData MainActor / Multi-Threading Crashes

**What goes wrong:**
Attempting to access, modify, or save SwiftData models from a background thread or menu bar event loop causes runtime assertions (`EXC_BAD_INSTRUCTION`) or data corruption.

**Why it happens:**
SwiftData's default `ModelContext` is bound to `@MainActor`. Accessing it from background tasks or notification callbacks without proper actor isolation violates Swift's memory model.

**How to avoid:**
1. Annotate `TimerManager` as `@MainActor`.
2. Perform all UI and MenuBarExtra mutations on `@MainActor`.
3. For any background batch computations, create a dedicated background `ModelContext` using `ModelContainer.mainContext` parent container.

**Phase to address:** Phase 1 (Data Layer & Scaffolding) & Phase 2 (Timer Engine).

---

### Pitfall 3: MenuBarExtra and Main Window Synchronization Conflicts

**What goes wrong:**
The menu bar status item and the main window show conflicting timer states (e.g., timer running in menu bar, stopped in window), or starting the timer in one place doesn't immediately reflect in the other.

**Why it happens:**
Instantiating separate timer state objects in `WindowGroup` and `MenuBarExtra`.

**How to avoid:**
Instantiate a single `@Observable class TimerManager` in `TimeStampApp` and pass it down via `.environment(timerManager)` to both the `WindowGroup` scene and the `MenuBarExtra` scene.

**Phase to address:** Phase 5 (Menu Bar Companion).

---

### Pitfall 4: Calendar Date Boundary & Timezone Bugs

**What goes wrong:**
Time entries logged around midnight appear on the wrong day, or duration totals for "Today" show inaccurate sums when crossing midnight or daylight saving boundaries.

**Why it happens:**
Using naive timestamp arithmetic (e.g. `entry.startDate > Date() - 86400`) instead of `Calendar.current.startOfDay(for:)`.

**How to avoid:**
Always use `Calendar.current` to evaluate start-of-day, start-of-week, and day components. Group entries using `Calendar.current.dateInterval(of: .day, for: Date())`.

**Phase to address:** Phase 3 (Time Entries Management) & Phase 6 (Dashboard & Reports).

## "Looks Done But Isn't" Checklist

- [ ] **Timer accuracy:** Let Mac sleep for 15 minutes with timer running; upon waking, verify elapsed time includes the 15 minutes.
- [ ] **Midnight rollover:** Keep timer running across midnight; verify the dashboard properly splits or attributes the duration.
- [ ] **Menu bar item update:** Start timer via hotkey; verify menu bar ticker updates within 1 second without opening the main window.
- [ ] **Theme switching:** Switch macOS appearance from Light to Dark in System Settings; verify all custom cards, timeline blocks, and text remain legible without glitches.
- [ ] **Empty states:** Launch with zero projects, tasks, or entries; verify UI shows elegant empty state graphics rather than blank screens or errors.

---
*Pitfalls research for: Native macOS Desktop Time Tracking*
*Researched: 2026-11-23*
