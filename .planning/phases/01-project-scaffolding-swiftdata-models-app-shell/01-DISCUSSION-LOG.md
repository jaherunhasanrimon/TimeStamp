# Phase 1: Project Scaffolding, SwiftData Models & App Shell - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-23
**Phase:** 01-Project Scaffolding, SwiftData Models & App Shell
**Areas discussed:** Window styling & layout

---

## Window Styling & Layout

### Question 1: Window Dimensions & Resizability
| Option | Description | Selected |
|--------|-------------|----------|
| 1000x700 default size, min 800x550 | Balanced for sidebar + timeline/dashboard, fits 13"-16" screens | ✓ |
| 850x600 default size, min 700x500 | Compact utility window | |
| 1200x800 default size, min 900x650 | Spacious desktop workspace | |
| You decide | Agent discretion | |

**User's choice:** 1000x700 default size, min 800x550
**Notes:** Provides a generous workspace without overwhelming smaller MacBook displays.

### Question 2: Title Bar Presentation
| Option | Description | Selected |
|--------|-------------|----------|
| Modern unified toolbar with hidden title bar | Traffic light controls blend into sidebar, content flows cleanly | ✓ |
| Standard macOS title bar | Explicit title "TimeStamp" centered and separate toolbar | |
| Seamless full-size content view | .titlebarAppearsTransparent with custom layout | |
| You decide | Agent discretion | |

**User's choice:** Modern unified toolbar with hidden title bar (`.windowToolbarStyle(.unified(showsTitle: false))`)
**Notes:** Delivers the sleek, modern aesthetic characteristic of Toggl Track and premium macOS utilities.

### Question 3: Sidebar Material
| Option | Description | Selected |
|--------|-------------|----------|
| Native macOS translucent sidebar material | Apple HIG vibrant blur, collapsible sidebar button | ✓ |
| Solid opaque background | High contrast across custom dark and light color themes | |
| You decide | Agent discretion | |

**User's choice:** Native macOS translucent sidebar material (`Material.sidebar`)
**Notes:** Matches native macOS system appearances and Apple Human Interface Guidelines.

### Question 4: Window Management Policy
| Option | Description | Selected |
|--------|-------------|----------|
| Single window instance | Clicking dock icon or menu bar re-focuses or re-opens main window | ✓ |
| Multiple windows allowed | Can open independent project or report windows | |
| You decide | Agent discretion | |

**User's choice:** Single window instance
**Notes:** Clean single-window utility model prevents clutter.

---

## the agent's Discretion

- **Design Tokens & Accent Colors:** Selected Toggl-inspired Indigo/Purple accent (`#5C3BFE` / `#7B61FF`) with dark/light adaptive surfaces and semantic tokens.
- **Preview Data Container:** Configured pre-seeded sample data in preview environment for immediate UI fidelity.
- **Sidebar Organization:** Sectioned into "Track", "Analyze", and "Manage" groups.

## Deferred Ideas

None — discussion remained focused on Phase 1 scope.
