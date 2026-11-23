# Architecture Research

**Domain:** Native macOS Desktop Time Tracking (Swift & SwiftUI)
**Researched:** 2026-11-23
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             Presentation Layer                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌───────────────────┐  │
│  │ Main Window UI       │  │ Menu Bar Companion   │  │ Settings & Config │  │
│  │ (Sidebar, Dashboard, │  │ (MenuBarExtra, Quick │  │ (Theme, Hotkeys,  │  │
│  │  Entries, Calendar,  │  │  Toggle, Live Ticker)│  │  Defaults)        │  │
│  │  Projects, Reports)  │  │                      │  │                   │  │
│  └──────────┬───────────┘  └──────────┬───────────┘  └────────┬──────────┘  │
│             │                         │                       │             │
├─────────────┴─────────────────────────┴───────────────────────┴─────────────┤
│                          Application State & Services                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────────────────┐  │
│  │ TimerManager     │  │ HotKeyManager    │  │ SleepWakeMonitor          │  │
│  │ (@Observable,    │  │ (Global Shortcut │  │ (NSWorkspace Notifications│  │
│  │  Drift-Free Math)│  │  Listener)       │  │  for system sleep/wake)   │  │
│  └──────────┬───────┘  └──────────┬───────┘  └─────────────┬─────────────┘  │
│             │                     │                        │                │
├─────────────┴─────────────────────┴────────────────────────┴────────────────┤
│                           Domain & Persistence Layer                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ SwiftData ModelContext & ModelContainer                                │  │
│  │ Models: TimeEntry, Project, Task, Client, Tag                         │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Implementation Details |
|-----------|----------------|------------------------|
| `TimeStampApp` | Application lifecycle, window declarations, menu bar setup | SwiftUI `App` scene defining `WindowGroup` and `MenuBarExtra` |
| `TimerManager` | Active running timer state, starting, pausing, stopping | `@Observable class TimerManager: @MainActor`, publishes active `TimeEntry` and seconds elapsed |
| `TimeCalculator` | Mathematical elapsed duration logic | Pure Swift static methods calculating elapsed intervals from wall-clock timestamps |
| `SleepWakeMonitor` | Listens to macOS sleep/wake notifications | Subscribes to `NSWorkspace.willSleepNotification` and `NSWorkspace.didWakeNotification` |
| `HotKeyManager` | Global shortcut binding and execution | Interacts with `KeyboardShortcuts` framework to trigger timer actions from any app |
| `SwiftDataContainer` | Manages local schema, migrations, and previews | Configures `ModelContainer` for `TimeEntry`, `Project`, `Task`, `Client`, `Tag` |

## Recommended Project Structure

```
TimeStamp/
├── Sources/
│   ├── App/
│   │   ├── TimeStampApp.swift             # App entrypoint with WindowGroup & MenuBarExtra
│   │   ├── AppState.swift                 # Root navigation and window coordination
│   │   └── AppEnvironment.swift           # Shared environment objects and container setup
│   ├── Models/
│   │   ├── TimeEntry.swift                # SwiftData @Model for time tracking sessions
│   │   ├── Project.swift                  # SwiftData @Model for projects & color schemes
│   │   ├── Task.swift                     # SwiftData @Model for sub-project tasks
│   │   ├── Client.swift                   # SwiftData @Model for client entities
│   │   └── Tag.swift                      # SwiftData @Model for tags/labels
│   ├── Core/
│   │   ├── TimerManager.swift             # Active timer engine & observable state
│   │   ├── TimeCalculator.swift           # Pure timestamp arithmetic
│   │   └── SleepWakeMonitor.swift         # NSWorkspace sleep/wake observers
│   ├── Services/
│   │   ├── HotKeyManager.swift            # Keyboard shortcut registration
│   │   └── ExportService.swift            # CSV and JSON summary exporter
│   ├── Views/
│   │   ├── Navigation/
│   │   │   ├── AppSidebar.swift           # macOS navigation sidebar
│   │   │   └── DetailContainerView.swift  # Active tab container
│   │   ├── Timer/
│   │   │   ├── ActiveTimerBar.swift       # Sticky top timer bar with live controls
│   │   │   └── DurationPickerView.swift   # Quick manual entry picker
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift        # Overview metrics, progress bars
│   │   │   └── TodaySummaryCard.swift     # Breakdown of current day
│   │   ├── Entries/
│   │   │   ├── EntriesListView.swift      # Grouped daily time entries list
│   │   │   ├── EntryRowView.swift         # Individual entry row with inline edit
│   │   │   └── EntryEditSheet.swift       # Comprehensive edit modal
│   │   ├── Calendar/
│   │   │   ├── CalendarTimelineView.swift # Day & week visual block timeline
│   │   │   └── TimelineSlotView.swift     # Individual block layout
│   │   ├── Projects/
│   │   │   ├── ProjectsListView.swift     # Projects and tasks manager
│   │   │   └── ProjectEditorView.swift    # Color picker and metadata
│   │   ├── Clients/
│   │   │   └── ClientsListView.swift      # Client catalog and associations
│   │   ├── Reports/
│   │   │   ├── ReportsView.swift          # Swift Charts visualizations
│   │   │   └── ChartCardView.swift        # Reusable chart containers
│   │   ├── MenuBar/
│   │   │   └── MenuBarCompanionView.swift # MenuBarExtra dropdown popup
│   │   └── Settings/
│   │       ├── SettingsView.swift         # Preferences window tabs
│   │       └── ShortcutSettingsTab.swift  # Hotkey configuration
│   └── DesignSystem/
│       ├── Colors.swift                   # Theme palettes, project color presets
│       ├── Typography.swift               # macOS standard typography styles
│       └── Components/                    # Buttons, badges, cards, inputs
└── Tests/
    ├── TimerManagerTests.swift            # Unit tests for timer arithmetic & pause/resume
    ├── ModelTests.swift                   # SwiftData relationship and cascade tests
    └── ExportServiceTests.swift           # Report formatting tests
```

## Architectural Patterns

### Pattern 1: Drift-Free Wall-Clock Timer Math

**What:** Never use an integer counter that increments `seconds += 1` inside a timer loop. Instead, store the exact reference timestamp `startDate: Date` and accumulated duration from prior pause segments.

**When to use:** All time-tracking logic.

```swift
final class TimeCalculator {
    static func currentDuration(
        startDate: Date?,
        accumulatedDuration: TimeInterval,
        isPaused: Bool,
        now: Date = Date()
    ) -> TimeInterval {
        guard let startDate = startDate, !isPaused else {
            return accumulatedDuration
        }
        return accumulatedDuration + max(0, now.timeIntervalSince(startDate))
    }
}
```

### Pattern 2: SwiftData Cloud-Ready Relationships

**What:** Design all relationships with explicit inverse relationships and optional/null handling, which guarantees smooth data migrations and readiness for future CloudKit sync.

```swift
@Model
final class Project {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#0A84FF"
    var createdAt: Date = Date()

    @Relationship(inverse: \TimeEntry.project)
    var entries: [TimeEntry] = []

    @Relationship(inverse: \Task.project)
    var tasks: [Task] = []

    var client: Client?

    init(name: String, colorHex: String = "#0A84FF", client: Client? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.client = client
    }
}
```

---
*Architecture research for: Native macOS Desktop Time Tracking*
*Researched: 2026-11-23*
