# Phase 1: Project Scaffolding, SwiftData Models & App Shell - Context

**Gathered:** 2026-11-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Bootstrap the native macOS 14+ Swift/SwiftUI application target, define the complete SwiftData domain model schemas (`TimeEntry`, `Project`, `Task`, `Client`, `Tag`) with a preview sample data container, set up design system styling tokens (colors, typography, container shapes), and build the root `NavigationSplitView` with a modern collapsible `AppSidebar`.
</domain>

<decisions>
## Implementation Decisions

### Window Styling & Layout
- **D-01:** Default window dimensions set to 1000x700, with a minimum size of 800x550, optimized for sidebar + timeline/dashboard on 13"-16" MacBook displays and external monitors.
- **D-02:** Modern unified toolbar presentation with hidden window title (`.windowToolbarStyle(.unified(showsTitle: false))`), seamlessly blending traffic light window controls into the sidebar header.
- **D-03:** Sidebar styled with Apple's native translucent material (`Material.sidebar` / vibrant blur) with native sidebar toggle support.
- **D-04:** Single window instance policy — activating the dock icon or menu bar re-focuses or re-opens the main window without creating duplicate window instances.

### the agent's Discretion
- **Brand & Theme Accent:** Use a refined Toggl-inspired Indigo/Purple accent (`#5C3BFE` / `#7B61FF`) with complementary macOS semantic colors, crisp monochrome neutral tones, and adaptive Light/Dark styling.
- **SwiftData Preview Container:** Include pre-seeded realistic sample projects, tasks, and historical time entries in debug/preview mode for rapid visual verification and UI development.
- **Sidebar Hierarchy:** Group navigation into logical sections: "Track" (Timer & Entries, Calendar), "Analyze" (Dashboard, Reports), and "Manage" (Projects, Clients), plus Settings in the footer.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project & Requirements
- `.planning/PROJECT.md` — Core value, platform constraints (macOS 14+ Apple Silicon), and architectural principles
- `.planning/REQUIREMENTS.md` — 35 v1 requirements and traceability mapping
- `.planning/ROADMAP.md` — 8-phase execution plan and Phase 1 success criteria

### Research & Architecture
- `.planning/research/STACK.md` — Swift 5.10+, SwiftUI, SwiftData, and SPM guidelines
- `.planning/research/ARCHITECTURE.md` — Project directory structure, SwiftData relationship schema, and component layout
- `.planning/research/PITFALLS.md` — Pitfall 2: SwiftData MainActor thread-safety rules
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Greenfield codebase; establishing primary design tokens and foundational components in this phase.

### Established Patterns
- Pure Swift & SwiftUI with SwiftData `@Model` classes and `@Observable` state pattern.
- Strict `@MainActor` isolation for UI state and main model context.

### Integration Points
- `TimeStampApp.swift`: Root entrypoint declaring `WindowGroup` scene and injecting the shared SwiftData `ModelContainer`.
- `AppSidebar.swift`: Primary navigation coordinating views across all subsequent phases.
</code_context>

<specifics>
## Specific Ideas

- Inspired by Toggl Track's sleek, distraction-free desktop client: minimal chrome, content-first typography, fluid macOS native interactions, and instant response times.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed strictly within Phase 1 scope.
</deferred>

---

*Phase: 01-Project Scaffolding, SwiftData Models & App Shell*
*Context gathered: 2026-11-23*
