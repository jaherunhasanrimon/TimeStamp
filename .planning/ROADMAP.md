# Milestone Roadmap

## Milestone v1.0: Native macOS TimeStamp Foundation (Completed)
Delivered core TimerEngine, Projects/Tasks/Clients, Dashboard, Reports, Calendar Read-Only Grids, Menu Bar Companion, Global Hotkeys, Settings, Goals Engine, Pomodoro Engine, Billable & Tags, and Sample-Goal Cleanup.

## Milestone v2.0: Full Toggl Track Feature Parity & UI Reconstruction (Phases 0–6 Complete)

- [x] **Phase 0: Bug Triage, Calculation Integrity & Test Runner Repair**
  Eliminated active-timer double-counting (`BUG-A`/`BUG-B`), fixed CLI notification crash & test isolation, fixed `./scripts/run-qa-tests.sh` (`Swift Testing`), and set System theme default.
- [x] **Phase 1: Core Timer, Entry UX & Visual Foundations** (`Tests/Phase1CoreTrackingTests.swift`)
  Live autocomplete popover, `@`/`#` triggers, vertical Play/`+` manual mode (`⌘D`), `0:00:00` bar ticker, `⌘E` running edit, Duplicate, Undo Delete, Favorites, Same-day Grouping, Entry Search & Billable filter, Enforce Default Project, Vector Empty State & Capsule Pill Switcher.
- [x] **Phase 2: Projects, Clients, Tasks & Tags Parity** (`Tests/Phase2ProjectsTagsTests.swift`)
  Project rates/estimates UI, Client rate/currency UI, Client filter in Projects, Searchable Project/Task Picker (white `"Create project"` text + archived filtering + keyboard nav), Tag inline rename & dedicated `TagsListView` sidebar screen.
- [x] **Phase 3: Interactive Calendar & Multi-View Reports** (`Tests/Phase3CalendarReportsTests.swift`)
  Double-click Calendar slot creation, Drag move & Top/Bottom resize with configurable snap, Context Menu, Opt-in Apple Calendar EventKit overlay, Summary/Detailed/Weekly Reports, Stacked Bar + Project/Task Hierarchy + CSV/JSON Extended + CoreGraphics PDF export.
- [x] **Phase 4: Goals & Pomodoro Parity** (`Tests/Phase4GoalsPomodoroTests.swift`)
  Multi-project Goals + `UNTIL` end dates + Production-safe tolerant Codable decoding, Toggl `GOAL` Popover layout, Borderless `KEEP GOING`, 60-tick Pomodoro Dial, `"I'm focusing on..."` DETAILS popover, Standalone Window, Auto-start & Count-up modes.
- [x] **Phase 5: Native macOS Integration, Mini-Timer, Idle, Reminders, Autotracker & Settings** (`Tests/Phase5SystemIntegrationTests.swift`)
  Floating always-on-top Mini-Timer (`⇧⌘M`), Menu Bar Favorites & Project indicator, CoreGraphics HID Idle Detection (4 actions), Workday Reminders, Opt-in Local Activity Recorder + Autotracker + Purge, Dock Icon & Login Item toggles, 6-tab Settings.
- [x] **Phase 6: Final QA, Release Packaging, Visual Verification & Parity Sign-Off**
  Clean release build & codesign of `TimeStamp.app`, live GUI screenshot verification in Dark/Light modes, visual bug fixes (`WeekTimelineGridView` header spacing, `PomodoroPopoverView` edge fill, `Goal` legacy JSON compat, `NSApp` launch safety), `129/129` tests passing, and `100.0 / 100` `parity.py` score.
