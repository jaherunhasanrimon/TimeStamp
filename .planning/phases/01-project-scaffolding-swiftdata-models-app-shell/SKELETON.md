# Walking Skeleton — TimeStamp

**Phase:** 1
**Generated:** 2026-11-23

## Capability Proven End-to-End

A user can launch the native macOS TimeStamp desktop application, see a responsive sidebar with sectioned navigation ("Track", "Analyze", "Manage", Settings) on a translucent background, create and view a persisted Project in SwiftData with custom color tagging, and verify that data persists across app relaunches.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Language & Framework | Swift 5.10 / 6.0 + SwiftUI | Native Apple Silicon optimization, lowest memory footprint (<35MB RAM), seamless system integration |
| Minimum OS Target | macOS 14.0 (Sonoma) & macOS 15.0 (Sequoia) | Access to modern `NavigationSplitView`, `MenuBarExtra`, `@Observable` macro, and SwiftData `@Model` |
| Persistence Layer | SwiftData (`ModelContainer`) | Modern declarative schema with automatic migration capabilities and future CloudKit sync readiness |
| Window Architecture | Single window with `.windowToolbarStyle(.unified(showsTitle: false))` | Modern macOS aesthetic matching Toggl Track, traffic lights integrated into sidebar |
| Window Dimensions | 1000×700 default, 800×550 minimum | Balanced layout for sidebar + detail timeline without clipping on smaller MacBook screens |
| Navigation Model | `NavigationSplitView` with sectioned `AppSidebar` | Scalable hierarchy: "Track" (Timer/Entries, Calendar), "Analyze" (Dashboard, Reports), "Manage" (Projects, Clients) |
| Design Tokens | 60-30-10 Color rule with Toggl Indigo `#5C3BFE` / `#7B61FF` | High-contrast, clean typography, adaptive Dark/Light system appearances conforming to Apple HIG |

## Stack Touched in Phase 1

- [x] Project scaffold (`Package.swift` with macOS executable target, Swift 5.10+, automated test target)
- [x] Routing (`NavigationSplitView` with `SidebarDestination` enum covering all 7 app views)
- [x] Database (`ModelContainer` with `TimeEntry`, `Project`, `Task`, `Client`, `Tag` schemas; real read and write verified)
- [x] UI (Interactive sidebar navigation, custom design system tokens, live SwiftData-backed project list)
- [x] Deployment / Local Run (`swift run` / Xcode build verified on Apple Silicon Mac)

## Out of Scope (Deferred to Later Slices)

- Running timer engine with start/pause/stop/continue mechanics (Phase 2)
- Time entry manual logging, grouping, and editing sheets (Phase 3)
- Full project, task, and client CRUD managers (Phase 4)
- macOS Menu Bar Extra live ticker companion & global hotkeys (Phase 5)
- Today Dashboard metrics and Swift Charts reporting (Phase 6)
- Interactive visual Calendar Timeline time blocks (Phase 7)
- Settings preferences tabs and theme override switches (Phase 8)
- CloudKit remote sync and user authentication (v2+)

## Subsequent Slice Plan

Each subsequent phase builds vertically on this walking skeleton:
- **Phase 2:** Active Timer Engine — adds `TimerManager`, drift-free timestamp delta math, top active timer bar, and sleep/wake handling
- **Phase 3:** Time Entries Log — adds daily grouped list view, daily totals calculation, and entry edit modal
- **Phase 4:** Projects, Tasks & Clients — completes full entity management, color picker, and hierarchical filtering
- **Phase 5:** Menu Bar Companion & Global Hotkeys — adds `MenuBarExtra` scene with live ticker and `KeyboardShortcuts` daemon
- **Phase 6:** Dashboard & Reports — adds Swift Charts visualization and CSV/JSON export
- **Phase 7:** Calendar Timeline — adds interactive 24-hour day and 7-day multi-column time grid blocks
- **Phase 8:** Settings & Polish — adds appearance preferences, shortcut recorder, and full test suite verification
