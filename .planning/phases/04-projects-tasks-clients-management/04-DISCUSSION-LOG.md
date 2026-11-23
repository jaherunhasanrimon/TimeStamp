# Phase 4: Projects, Tasks, and Clients Management - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-23
**Phase:** 04-projects-tasks-clients-management
**Areas discussed:** Projects & Tasks View Layout, Task Creation & Completion UX, Color Palette & Styling, Client Management & Association

---

## Projects & Tasks View Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Expandable List (`DisclosureGroup`) | Each project is a clean row with color dot, client badge, and total time; clicking chevron expands task sub-rows inline | ✓ |
| Master-Detail Split View | Projects column on the left, full task management and project statistics inspector in detail view on the right | |
| Table with Modal Inspector | Flat table listing projects with double-click or edit button opening a dedicated Project Inspector sheet for tasks and settings | |

**User's choice:** Expandable List (`DisclosureGroup`)  
**Notes:** Authentic Toggl desktop pattern providing a clean single-pane scrollable view.

---

## Project Row Actions & Surfacing

| Option | Description | Selected |
|--------|-------------|----------|
| Hover Actions + Context Menu | Clean row showing client badge, task count, and total tracked time; hovering reveals quick "+ Task" and "Edit" buttons, with full right-click context menu | ✓ |
| Trailing Action Menu (•••) | An explicit 3-dots menu button on the right side of each project row with all actions | |
| Inline Action Bar | Always-visible action icons (+ Task, Edit, Archive, Delete) on every project row | |

**User's choice:** Hover Actions + Context Menu  
**Notes:** Consistent with the Phase 3 `TimeEntryRowView` hover and context menu pattern.

---

## Task Row Representation

| Option | Description | Selected |
|--------|-------------|----------|
| Rich Task Row | Checkbox to mark complete/active, task name, tracked time badge, and hover "Start Timer" (play) button to immediately track time on this task | ✓ |
| Simple Checklist Row | Checkbox, task name, and inline edit/delete only | |
| You decide | Builder chooses the cleanest macOS pattern | |

**User's choice:** Rich Task Row  
**Notes:** Allows immediate one-click tracking against specific tasks directly from the project hierarchy.

---

## Projects Toolbar & Filtering

| Option | Description | Selected |
|--------|-------------|----------|
| Unified Top Filter Bar | Search field ("Search projects..."), segmented picker `[Active | Archived]`, and prominent "+ New Project" button | ✓ |
| Inline Filter Pills | Search bar with filter chips (Client, Active/Archived status) and "+ New Project" in sidebar header | |
| You decide | Builder chooses the cleanest macOS pattern | |

**User's choice:** Unified Top Filter Bar  
**Notes:** Clean macOS top toolbar layout.

---

## Task Creation UX

| Option | Description | Selected |
|--------|-------------|----------|
| Inline Quick-Add Row | An inline text field at the bottom of the expanded project ("+ Add task...", Return to save, Esc to cancel) for instant, rapid task entry | ✓ |
| Focused Popover or Sheet | Clicking "+ Task" opens a compact modal sheet or popover to name the task | |
| You decide | Builder chooses the cleanest macOS pattern | |

**User's choice:** Inline Quick-Add Row  
**Notes:** Enables frictionless, rapid task creation without modal dialog interruptions.

---

## Completed Tasks Display

| Option | Description | Selected |
|--------|-------------|----------|
| Collapsible "Completed (N)" Group | Completed tasks get strike-through styling and tuck into a collapsible sub-group at the bottom of the project tasks | ✓ |
| Dimmed In-Place | Completed tasks remain in their exact spot with strike-through and dimmed opacity (50%) | |
| Global Toggle | A "Hide Completed Tasks" toggle button in the toolbar filters them out across all projects | |

**User's choice:** Collapsible "Completed (N)" Group  
**Notes:** Keeps the active task workspace clean while preserving historical visibility.

---

## Tracking Time on Completed Tasks

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-Reopen Task | Starting the timer on a completed task automatically marks it active (`isCompleted = false`) and moves it back to active tasks | ✓ |
| Track Without Reopening | Starts timer and records time entry against the task, leaving its completion status unchanged | |
| You decide | Builder chooses the cleanest macOS pattern | |

**User's choice:** Auto-Reopen Task  
**Notes:** Intuitive workflow ensuring actively worked tasks are surfaced in the active list.

---

## Task Deletion Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Unlink Entries & Confirm | Deleting a task with tracked entries shows a confirmation dialog and unlinks entries (`taskId = nil`), preserving all logged time | ✓ |
| Block Deletion if Tracked | Prevent deleting tasks that have logged hours | |
| Cascade Delete with Warning | Delete the task and permanently delete all its associated time entries | |

**User's choice:** Unlink Entries & Confirm  
**Notes:** Guarantees zero historical time entry data loss.

---

## Color Selection UX

| Option | Description | Selected |
|--------|-------------|----------|
| Curated Swatches + Custom ColorPicker | Row of 8 curated high-contrast swatches plus a "Custom..." color wheel for any custom hex | ✓ |
| Fixed 8 Curated Colors Only | Clean 8-swatch circle row | |
| You decide | Builder chooses the cleanest macOS pattern | |

**User's choice:** Curated Swatches + Custom ColorPicker  
**Notes:** Best of both worlds: convenient curated defaults and full customization freedom.

---

## Project Color Application

| Option | Description | Selected |
|--------|-------------|----------|
| Color Dot + Low-Opacity Tint | 8px color dot in rows and pickers, with a subtle 10% opacity pill background for badges | ✓ |
| Color Dot Only | Strict neutral UI with 8px colored circular swatches only | |
| You decide | Builder chooses the cleanest macOS pattern | |

**User's choice:** Color Dot + Low-Opacity Tint  
**Notes:** Provides instant visual recognition without visual clutter.

---

## Archived Project Styling & Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Grayscale Dot & Archived Badge | Desaturates color dot to gray, dims text to secondary, displays "Archived" pill, and automatically excludes archived projects from timer pickers | ✓ |
| Retain Color with Dimmed Opacity | Keeps original color dot at 50% opacity with an "Archived" tag | |
| You decide | Builder chooses the cleanest macOS pattern | |

**User's choice:** Grayscale Dot & Archived Badge  
**Notes:** Clear visual feedback and declutters active timer selection.

---

## Project Editor Modal Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated Project Sheet (420px) | Project Name field, Client selector (with inline "+ New Client" option), Color swatches, and Archive toggle (when editing) | ✓ |
| Compact Popover | Lightweight popover anchored to the "+ New Project" button | |
| You decide | Builder chooses the cleanest macOS pattern | |

**User's choice:** Dedicated Project Sheet (420px)  
**Notes:** Matches the established macOS modal dialog design system.

---

## Clients View Presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Expandable Client Cards/Rows | Each client is a row showing name, notes, project count, and total tracked time, expandable to reveal assigned projects | ✓ |
| Table with Action Columns | Standard macOS Table with Name, Associated Projects, Total Hours, and Edit/Delete menu buttons | |
| Master-Detail Inspector | Sidebar-like client list on the left, full client profile and project list in detail view on the right | |

**User's choice:** Expandable Client Cards/Rows  
**Notes:** Visually unified with the Projects view.

---

## Client Editor Modal

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated Client Sheet (400px) | Client Name field, optional Notes/Contact field, and quick-checklist to link/unlink existing projects | ✓ |
| Simple Name-Only Sheet | Lightweight modal asking only for Client Name | |
| You decide | Builder chooses the cleanest macOS pattern | |

**User's choice:** Dedicated Client Sheet (400px)  
**Notes:** Allows managing client-project links during client creation/editing.

---

## Client Deletion Safety

| Option | Description | Selected |
|--------|-------------|----------|
| Unlink Projects & Confirm | Confirmation alert warns the user; deleting the client resets project `clientId` to `nil`, preserving all projects, tasks, and logged hours | ✓ |
| Block Deletion if Projects Linked | Prevent deleting a client until all its projects are reassigned or removed | |
| Cascade Delete with Warning | Delete client and delete all associated projects and tasks | |

**User's choice:** Unlink Projects & Confirm  
**Notes:** Prevents accidental deletion of projects or time entries when cleaning up clients.

---

## Filtering Access for Entries

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid Filter Access | Compact "Filter" dropdown in EntriesListView header (by Project/Client), PLUS a "View Entries" action on Project/Client rows that switches to the filtered entries list | ✓ |
| Toolbar Filter Dropdown Only | Filter menu in EntriesListView toolbar with searchable Project and Client sections | |
| You decide | Builder chooses the cleanest macOS pattern | |

**User's choice:** Hybrid Filter Access  
**Notes:** Maximum user convenience whether starting from the log or browsing projects/clients.

---

## the agent's Discretion

- Indentation styling and micro-spacing within `DisclosureGroup`.
- Case-insensitive search match algorithm across projects, tasks, and clients.
- Animation curves for expand/collapse transitions.

## Deferred Ideas

*(None)*
