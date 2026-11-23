# Phase 3: Time Entries Log & Manual Tracking - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-23
**Phase:** 03-time-entries-log-manual-tracking
**Areas discussed:** Daily Grouping & Day Header Format, Entry Editing Interaction, Manual Time Logging Workflow, Deletion Safety & Confirmation

---

## Daily Grouping & Day Header Format

| Option | Description | Selected |
|--------|-------------|----------|
| Relative with Weekday | 'Today', 'Yesterday', and 'Mon, Nov 21' for older days | ✓ |
| Explicit Dates Always | Full formatted calendar date for all sections | |

**User's choice:** Relative with Weekday (D-01).
**Header total duration format:** Compact Human-Readable — '4h 15m' (or '45m' if under 1 hour) in header, with full monospaced duration on rows (D-02).
**Time range format:** System Locale Time (e.g. '09:30 - 11:15' or '9:30 AM - 11:15 AM' following user Mac preferences) (D-03).
**Action button visibility:** Show on Hover + Right-Click Context Menu to keep rows clean (D-04).

---

## Entry Editing Interaction

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated Edit Sheet | Clicking/double-clicking a row opens an EntryEditSheet with date/time pickers and project selector | ✓ |
| Inline Click-to-Edit | Description and project editable directly in list row | |

**User's choice:** Dedicated Edit Sheet (D-05).
**Start/End time adjustment:** Auto-Adjusting End Time — changing start time shifts end time forward to preserve duration (D-06).
**Save pattern:** Explicit Save / Cancel buttons with Escape key dismissal (D-07).
**Duration handling:** Synchronized — editing start/stop times or typing duration recalculates the other automatically (D-08).

---

## Manual Time Logging Workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Dual Access | '+ Log Time' button in the Entries view toolbar plus keyboard shortcut (Cmd+N) | ✓ |
| Timer Bar Toggle | Switch icon in the top bar to toggle between live timer and manual input | |

**User's choice:** Dual Access (D-09).
**Default time window:** Pre-fill with the past 1 hour (Start = Now - 1h, End = Now) (D-10).
**Project prefill:** Pre-fill with last retained Project & Task (D-11).
**Modal UI presentation:** Unified Modal Sheet using EntryEditSheet layout with 'Log Time Entry' title (D-12).

---

## Deletion Safety & Confirmation

| Option | Description | Selected |
|--------|-------------|----------|
| Native Confirmation Alert | Sheet/dialog asking 'Delete Time Entry?' with destructive 'Delete' and 'Cancel' | ✓ |
| Immediate Delete with Undo | Instantly remove row with temporary toast | |

**User's choice:** Native Confirmation Alert (D-13).
**Swipe-to-delete:** Yes — support native macOS trackpad swipe-to-delete (D-14).
**Context menu actions:** Full Action Set — 'Continue Timer', 'Edit...', 'Duplicate Entry', and 'Delete...' (D-15).
**Empty state:** Illustrated Empty State — stopwatch icon, 'No time entries yet', and prompt to start timer or press Cmd+N (D-16).

---

## the agent's Discretion

- Visual divider styling between day groups and spacing between rows.
- Duplicate entry logic (creates a clone starting right after the original or at current timestamp).

## Deferred Ideas

- Multi-day range bulk editing / batch deletion — deferred to v2.
- Billable rate and currency toggles — explicitly out of scope for v1.
