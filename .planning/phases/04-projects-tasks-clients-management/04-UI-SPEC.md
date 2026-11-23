---
phase: 04
slug: projects-tasks-clients-management
status: approved
shadcn_initialized: false
preset: macos-native
created: 2026-11-23
---

# Phase 4 — UI Design Contract: Projects, Tasks, and Clients Management

> Visual and interaction design contract for Phase 4 Projects & Tasks management, Client management, and cross-entity filtering. Inherits core tokens from `01-UI-SPEC.md` and locks decisions D-01 through D-16.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Native SwiftUI (macOS 14+) |
| Preset | macOS Native Human Interface Guidelines |
| Component library | Native SwiftUI Views & Modifiers |
| Icon library | SF Symbols 5 (`folder`, `folder.fill`, `circle.fill`, `checkmark.circle`, `checkmark.circle.fill`, `play.fill`, `plus`, `pencil`, `trash`, `archivebox`, `archivebox.fill`, `person.2`, `person.2.fill`, `magnifyingglass`, `chevron.right`, `chevron.down`, `tag`, `line.3.horizontal.decrease.circle`) |
| Font | San Francisco (System & Monospaced Digits) |

---

## Spacing Scale

Declared values (conforming to 4pt grid in `AppSpacing`):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Swatch-to-text gaps, task row indentation micro-padding, inline icons |
| sm | 8px | Button padding, row vertical padding, color swatch gaps, badge padding |
| md | 16px | View horizontal padding, list margins, sheet internal padding |
| lg | 24px | Section separation between outline groups |
| xl | 32px | Empty state layout spacing, modal outer margins |
| 2xl | 48px | Major view padding |
| 3xl | 64px | Page-level spacing |

Exceptions:
- Project Row height: minimum 40px
- Task Row height: minimum 32px
- Client Card/Row height: minimum 48px
- Project Editor Modal Sheet: fixed width 420px, height ~380px (`D-12`)
- Client Editor Modal Sheet: fixed width 400px, height ~360px (`D-14`)

---

## Typography

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| View Header Title | 20pt | Semibold | 1.2 | "Projects", "Clients" toolbar headings |
| Project Row Title | 14pt | Medium | 1.2 | Project name in list row |
| Client Badge | 11pt | Medium | 1.2 | Client pill next to project name |
| Task Row Title | 13pt | Regular | 1.3 | Task name in project sub-list |
| Task Row Completed | 13pt | Regular (Strikethrough) | 1.3 | Completed task name in collapsible section |
| Metrics Badge | 12pt | Medium | 1.0 (`monospacedDigit()`) | Total tracked time ("12h 45m"), task count ("4 tasks") |
| Search Input | 13pt | Regular | 1.2 | Filter & search text field |
| Caption | 11pt | Regular | 1.2 | Form hints, shortcut labels ("⌘⇧P") |

---

## Color (60-30-10 Rule)

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#1C1C1E` (Dark) / `#FFFFFF` (Light) | Window background, projects and clients scroll canvas |
| Secondary (30%) | `#2C2C2E` (Dark) / `#F2F2F7` (Light) | Row hover backgrounds, cards, sheet backgrounds, search bar fill |
| Accent (10%) | `#7B61FF` (Dark) / `#5C3BFE` (Light) | "+ New Project" / "+ New Client" primary CTA, hover play button, active segment |
| Destructive | `#FF453A` (Dark) / `#D70015` (Light) | Delete actions, destructive alerts |

### Curated Project Swatches (`D-09`)
Eight high-contrast curated swatches available in `AppColors.projectColors`:
1. `#5C3BFE` (Electric Indigo / Brand Accent)
2. `#0A84FF` (System Blue)
3. `#30D158` (System Green)
4. `#FF9F0A` (System Orange)
5. `#FF375F` (System Pink)
6. `#BF5AF2` (System Purple)
7. `#64D2FF` (System Cyan)
8. `#FFD60A` (System Yellow)
Plus native macOS `ColorPicker` for custom hexadecimal values.

### Color Dot & Pill Styling (`D-10`, `D-11`)
- Active Project: 8px circular color dot (`Circle().fill(Color(hex: project.colorHex))`). Client badge uses 10% opacity pill background.
- Archived Project: Desaturated gray dot (`Color.secondary.opacity(0.6)`), text dimmed to `.secondary`, accompanied by an "Archived" pill badge (`D-11`). Archived projects are hidden from timer pickers.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Projects Toolbar Header | "Projects" |
| Projects Active Segment | "Active" |
| Projects Archived Segment | "Archived" |
| Projects Search Placeholder | "Search projects..." |
| New Project Button | "+ New Project" |
| New Task Inline Placeholder | "+ Add task..." |
| Completed Tasks Header | "Completed ({count})" |
| Project Sheet Title (Create) | "New Project" |
| Project Sheet Title (Edit) | "Edit Project" |
| Project Sheet Primary CTA (Create) | "Create Project" |
| Project Sheet Primary CTA (Edit) | "Save Changes" |
| Clients Toolbar Header | "Clients" |
| Clients Search Placeholder | "Search clients..." |
| New Client Button | "+ New Client" |
| Client Sheet Title (Create) | "New Client" |
| Client Sheet Title (Edit) | "Edit Client" |
| Client Sheet Primary CTA (Create) | "Create Client" |
| Client Sheet Primary CTA (Edit) | "Save Changes" |
| Modal Secondary CTA | "Cancel" |
| Delete Project Confirmation Title | "Delete Project “{name}”?" |
| Delete Project Confirmation Message | "Deleting this project will permanently remove its child tasks and unlink all associated time entries. Logged time will be preserved." |
| Delete Task Confirmation Title | "Delete Task “{name}”?" |
| Delete Task Confirmation Message | "Deleting this task will unlink it from all associated time entries. Logged time and project associations will be preserved." |
| Delete Client Confirmation Title | "Delete Client “{name}”?" |
| Delete Client Confirmation Message | "Deleting this client will unlink assigned projects. No projects, tasks, or time entries will be deleted." |
| Delete Confirmation CTA | "Delete" |

---

## Component Specifications

### 1. `ProjectsListView` & Toolbar (`D-01`, `D-04`)
- Top Toolbar:
  - Title: "Projects" with subtitle displaying project count.
  - Search field: "Search projects..." with magnifying glass icon and clear button.
  - Segmented Picker: `[Active | Archived]` (`D-04`).
  - Primary Action: "+ New Project" button (shortcut: `Cmd+Shift+P`).
- Main ScrollView:
  - List of `ProjectRowView` items.
  - Empty state when no projects match query or segment.

### 2. `ProjectRowView` (`D-01`, `D-02`, `D-03`, `D-05`, `D-06`)
- Structure: Wrapped in SwiftUI `DisclosureGroup` with custom expandable label.
- Header Row (min height 40px):
  - Left: Chevron expand/collapse arrow, 8px color dot, Project Name.
  - Client badge: Pill with client name (if assigned).
  - Metrics: Task count badge ("3 tasks"), total tracked time badge ("14h 20m").
  - Hover Action Container:
    - "+ Task" quick add button.
    - "Edit" button (opens `ProjectEditorSheet`).
- Context Menu:
  - "Add Task"
  - "Edit Project..."
  - "View Entries" (navigates/filters to time entries for this project)
  - Divider
  - Archive / Unarchive Project
  - "Delete Project..." (role: `.destructive`)
- Expanded Content:
  - List of active `TaskRowView` items.
  - Collapsible "Completed (N)" disclosure group if completed tasks exist (`D-06`).
  - Bottom: `InlineTaskAddRow` ("+ Add task...", Return to save, Esc to cancel) (`D-05`).

### 3. `TaskRowView` (`D-03`, `D-07`, `D-08`)
- Min height 32px, indented by 24px padding.
- Left:
  - Checkbox button (`circle` / `checkmark.circle.fill`) toggling `task.isCompleted`.
  - Task name (regular text if active; dimmed strikethrough if completed).
- Right:
  - Task total tracked duration ("2h 10m").
  - Hover Action:
    - "Start Timer" button (`play.fill`) to immediately start a tracking session with this task and project. If task was completed, auto-reopens it (`isCompleted = false`) (`D-07`).
    - "Delete" button (triggers task deletion confirmation dialog `D-08`).
- Context Menu:
  - "Start Timer"
  - Mark as Completed / Mark as Active
  - "Delete Task..." (role: `.destructive`)

### 4. `InlineTaskAddRow` (`D-05`)
- Indented text field: "+ Add task..."
- Keyboard interactions:
  - Return: Saves task if non-empty, clears field to allow typing next task immediately.
  - Escape: Cancels and unfocuses.

### 5. `ProjectEditorSheet` (`D-09`, `D-12`)
- Width: 420px.
- Fields:
  - Project Name (auto-focused text field).
  - Client Picker: Dropdown of existing clients, plus "+ New Client" inline option.
  - Color Swatches: `ColorSwatchPicker` showing the 8 curated swatches with selected ring + native `ColorPicker` for custom hex.
  - Archive Toggle: Switch for "Archive Project" (visible when editing existing project).
- Actions: "Cancel" (Esc) and "Save Changes" / "Create Project" (Return).

### 6. `ClientsListView` & `ClientRowView` (`D-13`, `D-15`)
- Top Toolbar:
  - Title: "Clients" with count.
  - Search field: "Search clients...".
  - Primary Action: "+ New Client" button.
- Client Row:
  - DisclosureGroup or Expandable card:
    - Name, Notes preview (if present), Project count badge, Total tracked time across all client projects.
    - Hover Actions: "Edit", "Delete".
    - Context Menu: "Edit Client...", "View Entries", "Delete Client...".
  - Expanded content: List of projects assigned to this client with their individual metrics.

### 7. `ClientEditorSheet` (`D-14`)
- Width: 400px.
- Fields:
  - Client Name.
  - Notes / Contact text area (optional).
  - Assigned Projects checklist: List of existing projects with checkboxes to link/unlink.
- Actions: "Cancel" and "Save Changes" / "Create Client".

### 8. `EntriesListView` Hybrid Filter (`D-16`)
- Header additions:
  - Compact "Filter" dropdown menu:
    - All Entries (default)
    - Section: Projects (lists active projects with color dots)
    - Section: Clients (lists clients)
  - Active filter pill: Shows selected filter name (e.g., "Project: Marketing Website" or "Client: Acme Corp") with an "xmark" button to quickly clear filter.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-11-23
