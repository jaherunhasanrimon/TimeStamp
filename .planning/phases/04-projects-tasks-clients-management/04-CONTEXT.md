# Phase 4: Projects, Tasks, and Clients Management - Context

**Gathered:** 2026-11-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 4 implements complete management of Projects, Tasks, and Clients, enabling structured categorization and filtering across the entire application:
- Color-coded Projects management (create, edit, archive/unarchive, delete) with custom color swatches (`PROJ-01`).
- Search and filtering by project active/archived status (`PROJ-02`).
- Tracked time and active task metrics per project (`PROJ-03`).
- Safe project deletion with entry unlinking (`PROJ-04`).
- Hierarchical Task management under projects (inline quick-add, completion toggling, direct timer tracking) (`TASK-01`, `TASK-02`, `TASK-03`).
- Client entity management (create, edit, delete, project rosters, and client metrics) (`CLNT-01`, `CLNT-02`, `CLNT-03`).
- Hybrid filtering of time entries by Project and Client (`PROJ-04`, `CLNT-03`).
- Integration into `SidebarDestination.projects` and `SidebarDestination.clients`.

Out of scope for Phase 4:
- Menu bar status item companion (Phase 5).
- Charts, analytics dashboards, and export (Phase 6).
- Visual calendar timeline 24h block grid (Phase 7).
</domain>

<decisions>
## Implementation Decisions

### Projects & Tasks View Layout
- **D-01 (Projects View Structure):** Expandable Outline List (`DisclosureGroup`) — Each project is a row showing color swatch, name, client badge, and total tracked time; clicking the chevron expands child task rows inline.
- **D-02 (Project Row Hover Actions):** Hover Actions + Context Menu — Clean row showing client badge, task count, and total tracked time; hovering reveals quick "+ Task" and "Edit" buttons, with full right-click context menu (Edit, Add Task, Archive/Unarchive, Delete).
- **D-03 (Task Row Representation):** Rich Task Row — Checkbox to mark complete/active, task name, tracked time badge, and hover "Start Timer" (`play.fill`) button to immediately track time on this task.
- **D-04 (Projects Filter & Search Toolbar):** Unified Top Filter Bar — Search field ("Search projects..."), segmented picker `[Active | Archived]`, and prominent "+ New Project" button with `Cmd+Shift+P` / `Cmd+N` shortcut.

### Task Creation & Completion UX
- **D-05 (Task Creation Flow):** Inline Quick-Add Row — An inline text field at the bottom of the expanded project ("+ Add task...", Return to save, Esc to cancel) for instant, rapid task entry without modal interruptions.
- **D-06 (Completed Task Presentation):** Collapsible "Completed (N)" Group — Completed tasks get strike-through styling and tuck into a collapsible sub-group at the bottom of the project tasks to keep active work focused.
- **D-07 (Tracking on Completed Task):** Auto-Reopen Task — Starting the timer on a completed task automatically marks it active (`isCompleted = false`) and restores it to the active list.
- **D-08 (Task Deletion Safety):** Unlink Entries & Confirm — Deleting a task with tracked entries shows a confirmation dialog and unlinks entries (sets `TimeEntry.taskId = nil`), preserving all logged time and project associations.

### Color Palette & Styling
- **D-09 (Color Selection UX):** Curated Swatches + Custom ColorPicker — Row of 8 curated high-contrast swatches (`AppColors.projectColors`: `#5C3BFE`, `#0A84FF`, `#30D158`, `#FF9F0A`, `#FF375F`, `#BF5AF2`, `#64D2FF`, `#FFD60A`) plus a "Custom..." color wheel for any custom hex code.
- **D-10 (Color Styling Pattern):** Color Dot + Low-Opacity Tint — 8px color dot in rows and pickers, with a subtle 10% opacity pill background for badges to provide instant visual distinction without visual noise.
- **D-11 (Archived Styling & Behavior):** Grayscale Dot & Archived Badge — Desaturates color dot to gray, dims text to secondary, displays "Archived" pill, and automatically excludes archived projects from timer pickers.
- **D-12 (Project Editor Modal):** Dedicated Project Sheet (420px width) — Project Name field, Client selector (with inline "+ New Client" option), Color swatches, and Archive toggle (when editing).

### Client Management & Association
- **D-13 (Clients View Presentation):** Expandable Client Cards/Rows — In `SidebarDestination.clients`, each client is a row showing name, notes, project count, and total tracked time, expandable to reveal assigned projects.
- **D-14 (Client Editor Modal):** Dedicated Client Sheet (400px width) — Client Name field, optional Notes/Contact field, and quick-checklist to link/unlink existing projects.
- **D-15 (Client Deletion Safety):** Unlink Projects & Confirm — Confirmation alert warns the user; deleting the client resets project `clientId` to `nil`, preserving all projects, tasks, and logged hours intact.
- **D-16 (Filtering Access):** Hybrid Filter Access — Compact "Filter" dropdown in `EntriesListView` header (by Project/Client), PLUS a "View Entries" action on Project/Client rows that switches to the filtered entries list.

### the agent's Discretion
- Visual spacing and micro-padding of task indentations within `DisclosureGroup`.
- Search matching algorithm (case-insensitive substring match against project names, client names, and task names).
- Exact animation curve when expanding/collapsing project and completed task disclosure groups.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing:**

### Domain Models & Persistence
- `Sources/Models/Project.swift` — Project data model (`id`, `name`, `colorHex`, `isArchived`, `createdAt`, `clientId`).
- `Sources/Models/Task.swift` — Task data model (`id`, `name`, `isCompleted`, `createdAt`, `projectId`).
- `Sources/Models/Client.swift` — Client data model (`id`, `name`, `notes`, `createdAt`).
- `Sources/Models/PersistenceStore.swift` — Reactive persistence operations (`saveProject`, `deleteProject`, `saveTask`, `deleteTask`, `saveClient`, `deleteClient`).

### Design System & Existing Views
- `Sources/DesignSystem/Colors.swift` — `AppColors.projectColors` curated swatches and brand accent.
- `Sources/Views/Timer/ProjectTaskPickerButton.swift` — Project and task dropdown picker integration.
- `Sources/Views/Entries/EntriesListView.swift` — Filter dropdown integration for Project/Client filtering.
- `Sources/Views/Navigation/DetailContainerView.swift` — Navigation routing for `.projects` and `.clients`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ProjectTaskPickerButton`: Already provides project color dots and task menus; can be reused or aligned with new project/task sheets.
- `PersistenceStore`: Already contains fully functional CRUD methods for `projects`, `tasks`, and `clients` with atomic JSON persistence.
- `AppColors.projectColors`: Array of 8 hex colors ready for the swatch picker.

### Established Patterns
- Modals use `.sheet` with 400–460px width, cancel/save shortcuts, and clear validation.
- Deletions use `confirmationDialog` before calling store deletion methods to guarantee data safety.
- Timer tracking via `timerManager.start(...)` directly callable from any row play button.
</code_context>
