# Feature Research

**Domain:** Native macOS Time Tracking Desktop Application
**Researched:** 2026-11-23
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in a professional time tracker like Toggl Track. Missing these makes the product feel incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Running Timer Controls | Core mechanic: Start, pause, stop, continue | LOW | Must support quick resume of recent tasks |
| Drift-Free Background Timing | App sleep, screen lock, or minimization must not lose time | MEDIUM | Use wall-clock reference dates (`startDate`, `accumulatedDuration`) |
| Time Entry Management | CRUD for logged entries, edit duration & timestamps | MEDIUM | Grouping by day with calculated daily totals |
| Projects & Color Tagging | Time must be categorized by client/workstream | LOW | Hex or preset curated color swatches for instant recognition |
| Tasks within Projects | Fine-grained organization under projects | LOW | Hierarchical linking (Project -> Task) |
| Clients Management | Grouping projects under distinct clients | LOW | Client-level filtering and organization |
| Today & Weekly Dashboard | Immediate answer to "How much did I work today / this week?" | MEDIUM | Visual progress bars, totals, and daily comparison |

### Differentiators (Competitive Advantage)

Features that elevate TimeStamp into a premium macOS desktop experience.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Menu Bar Status Item (`MenuBarExtra`) | Always-accessible timer ticker without switching apps | MEDIUM | Real-time ticker in menu bar, dropdown for quick start/stop |
| Global Keyboard Shortcut | Instantly toggle or start tracking from anywhere in macOS | LOW | Global hotkey (e.g. `⌃⌥Space` or user-defined) |
| Visual Calendar Timeline View | Toggl-style interactive day and week timeline blocks | HIGH | Visual representation of time gaps and overlapping slots |
| Native Swift Charts Reports | Polished breakdown by project, client, and productivity trends | MEDIUM | Interactive bar charts and summary cards with date range selection |
| Native macOS Liquid Feel | Subtle animations, native glass effects, light/dark themes | LOW | Adheres strictly to Apple HIG |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem appealing on the surface but create significant friction or creep.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Screen recording / Spyware activity logging | Bosses want to monitor employee keystrokes/screens | Creepy, violates privacy, massive battery/storage drain, ruins trust | Trust-based manual & timer tracking focused on personal productivity |
| Full Accounting / Invoicing Engine | Users want to bill clients directly | Scope explosion: tax laws, currencies, invoice PDFs, payment gateways | Provide clean CSV/JSON report exports that import into dedicated invoicing tools |
| Premature Custom Cloud Backend | Users ask about multi-device sync | Delays MVP launch by months; maintenance burden, security liabilities | Ship local SwiftData first; architecture is natively compatible with CloudKit in v2 |

## Feature Dependencies

```
[SwiftData Model Layer]
    ├──requires──> [Project & Client Management]
    │                  └──requires──> [Task Hierarchy]
    │                                     └──requires──> [Time Entry CRUD]
    │                                                        ├──requires──> [Running Timer Engine]
    │                                                        │                  ├──enhances──> [Menu Bar Extra]
    │                                                        │                  └──enhances──> [Global Hotkey]
    │                                                        ├──enhances──> [Dashboard & Reports]
    │                                                        └──enhances──> [Calendar Timeline View]
```

## MVP Definition (Full Productivity Scope)

### Launch With (v1)

- [ ] Core Timer Engine: Start, pause, stop, and continue active tracking with drift-free wall-clock math.
- [ ] Time Entries: CRUD, grouped day lists, inline editing of descriptions and start/stop timestamps.
- [ ] Projects: Color assignment, name, client linking.
- [ ] Tasks: Sub-categorization under projects.
- [ ] Clients: Entity creation and project associations.
- [ ] Dashboard: Today total, weekly summary, and recent activity feed.
- [ ] Reports: Productivity charts by project/client with custom date filters.
- [ ] Calendar: Day and week visual timeline of tracked entries.
- [ ] Menu Bar Companion: Menu bar extra showing active timer ticker and quick toggle.
- [ ] Global Hotkey: Configurable shortcut to toggle timer.
- [ ] Settings: Dark/Light theme, shortcuts, timer defaults.

### Future Consideration (v2+)

- [ ] CloudKit sync for seamless multi-Mac synchronization.
- [ ] Idle detection prompt (detecting when user is away from keyboard for 5+ min).
- [ ] Automatic pomodoro intervals or reminder notifications.
- [ ] Integration with calendar feeds (importing iCal/Google Calendar events as time entries).

---
*Feature research for: Native macOS Time Tracking Desktop Application*
*Researched: 2026-11-23*
