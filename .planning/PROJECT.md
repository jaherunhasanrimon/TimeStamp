# TimeStamp

## What This Is

TimeStamp is a polished, native macOS desktop time-tracking application inspired by Toggl Track, built specifically for Apple Silicon Macs with Swift and SwiftUI. It combines a distraction-free running timer, menu bar companion, and structured time tracking (projects, tasks, clients) with lightweight local persistence and clear productivity dashboards.

## Core Value

Frictionless, accurate time tracking that stays out of the user's way while providing immediate, reliable visibility into where time goes on macOS.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Native macOS running timer with start, pause, stop, and continue actions
- [ ] Timestamp-based drift-free elapsed time tracking that stays accurate across app minimization and Mac sleep/wake cycles
- [ ] Menu bar status item showing live timer ticker and quick start/stop controls
- [ ] Global keyboard shortcut to toggle or start/stop the active timer from any app
- [ ] Complete Time Entries management (create, edit description/times, delete, group by day/week)
- [ ] Projects management with custom color tagging
- [ ] Tasks support organized hierarchically under projects
- [ ] Clients management with association to projects
- [ ] Today Dashboard featuring today's total time, weekly progress summary, and recent activity log
- [ ] Visual Reports view with productivity statistics, breakdown charts by project and client
- [ ] Calendar view with daily and weekly timeline visualization of tracked entries
- [ ] Preferences and Settings (Dark/Light mode toggles, shortcut customization, default timer behaviors)
- [ ] SwiftData local persistence layer with modular architecture designed for future CloudKit / cloud sync

### Out of Scope

- Cloud sync & user authentication — v1 is local-first via SwiftData; architecture prepared for CloudKit/backend sync in v2
- Multi-user / Team collaboration workspaces — focused on single-user macOS power tracking for v1
- Invoicing and billable rates calculation — keep v1 focused on core time management and productivity insights
- Native Idle Detection prompt — keep timer calculation purely timestamp-driven; idle prompt deferred to v2
- Windows / Linux / Web clients — pure native macOS SwiftUI implementation for maximum performance and OS integration

## Context

- Target platform: macOS 14+ (Sonoma) and macOS 15+ (Sequoia) on Apple Silicon.
- Architecture: Native Swift / SwiftUI application using `@Observable`, SwiftData models, and modular feature separation (Core/Timer, Models, Views/Dashboard, Views/Timeline, Services/MenuBar, Services/Shortcuts).
- Interaction style: Influenced by Toggl Track's sleek desktop client: instantaneous keyboard interactions, fluid animations, minimal cognitive load.
- Reliability: Background accuracy relies on wall-clock reference dates (`startDate`, `pausedIntervals`) rather than naive continuous ticking timers to eliminate sleep/wake drift.

## Constraints

- **Tech Stack**: Pure Swift & SwiftUI with SwiftData — hard constraint for native macOS performance, memory efficiency (<40MB RAM), and Apple Human Interface Guidelines compliance.
- **Platform**: macOS 14.0+ Apple Silicon — leverages modern SwiftUI windowing, SwiftData persistence, and macOS menu bar extras.
- **Persistence**: Native Swift persistence store with clean `@Observable` & `Codable` domain schemas (`TimeEntry`, `Project`, `Task`, `Client`, `Tag`), atomic local storage, and repository pattern ensuring migration readiness for future CloudKit syncing without requiring proprietary Xcode macro toolchains.
- **Design System**: Strict adherence to macOS design patterns, support for both native Light and Dark system appearances, and accessible typography.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Native Swift & SwiftUI | Delivers the lowest memory footprint, instant startup, seamless menu bar extra, and authentic macOS feel | — Adopted |
| Native Swift Persistence Store | Modern `@Observable` & `Codable` models with atomic local repository pattern; compiles cleanly under Apple Command Line Tools without requiring the 14GB Xcode.app bundle | — Adopted |
| Full Productivity MVP Scope | Includes timer, entries, projects, tasks, clients, dashboard, calendar, and reports in v1 to provide a complete, usable daily tool | — Pending |
| Timestamp-based elapsed tracking | Prevents timer drift when macOS sleeps, display is locked, or app is backgrounded | — Pending |
| Menu Bar Status Item + Global Hotkey | Essential for effortless time tracking without having to keep the main window front-and-center | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-11-23 after initialization*
