# Phase 2: Core Drift-Free Timer Engine - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-23
**Phase:** 02-core-drift-free-timer-engine
**Areas discussed:** Active Timer Bar UI Placement, Start/Stop Interactions & Field Retention, Continue Tracking Workflow, System Sleep & Long Inactivity Policy

---

## Active Timer Bar UI & Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Global Sticky Bar | Always visible at the top of the main window detail pane across all views (Timer, Calendar, Dashboard, etc.) | ✓ |
| View-Specific Bar | Only visible at the top of the "Timer & Entries" screen | |

**User's choice:** Global Sticky Bar (D-01).
**Controls choice:** Dual Controls — distinct Pause/Resume icon button alongside prominent Stop button while running (D-02).
**Empty description choice:** Default to `(No description)` in displays, allow start without typing (D-03).
**Project selection choice:** Inline Pill Selectors — compact color dot and dropdown inside the bar (D-04).

---

## Start/Stop Interactions & Field Retention

| Option | Description | Selected |
|--------|-------------|----------|
| Pressing Enter Starts | Return/Enter key inside description field starts timer immediately (or stops if running) | ✓ |
| Click Only | Enter confirms text only; user must click Start or press hotkey | |

**User's choice:** Pressing Enter starts the timer immediately (D-05).
**Post-stop field retention:** Clear description text, retain last selected Project & Task (D-06).
**Duration ticker format:** Always full `HH:MM:SS` in monospaced digits to prevent jitter (D-07).
**Discard action:** Include subtle discard 'X' / trash button to cancel without creating a TimeEntry (D-08).

---

## Continue Past Entry Workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Immediate New Session | Instantly starts a fresh running timer starting now with identical description, project, and task | ✓ |
| Prefill Only | Populates top bar inputs and waits for user to click Start | |

**User's choice:** Immediate New Session (D-09).
**Active collision choice:** Auto-Stop & Switch — automatically stop and save the active timer, then start the continued one seamlessly (D-10).
**Entry creation choice:** Distinct New Entry — separate record starting at current timestamp (D-11).
**Attribute cloning choice:** Full Clone — copy description, project, task, and all tags (D-12).

---

## System Sleep & Long Inactivity Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Continuous Wall-Clock | Timer keeps running through sleep; duration equals wall-clock delta without interruption | ✓ |
| Sleep Detection Banner | Show non-blocking toast upon wake if sleep > 15m offering to subtract sleep time | |

**User's choice:** Continuous Wall-Clock (D-13).
**App quit / restart:** Auto-Restore Active Session on launch with zero data loss (D-14).
**Tick rate:** Efficient 1-second cadence (1 Hz) on `.common` RunLoop (<0.1% CPU) (D-15).
**Sleep/wake listeners:** NSWorkspace sleep/wake listeners with instant ticker refresh upon wake (D-16).

---

## the agent's Discretion

- Exact layout padding and visual animations when transitioning between idle and running states in `ActiveTimerBar`.
- Design of project dropdown menu items using `AppColors.projectColors`.

## Deferred Ideas

- Idle Detection prompt ("You were away for 15 minutes, keep or discard?") — deferred to v2.
- Menu Bar status companion — deferred to Phase 5.
- Global keyboard shortcut — deferred to Phase 5.
