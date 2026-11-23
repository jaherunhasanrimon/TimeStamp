# Stack Research

**Domain:** Native macOS Desktop Time Tracking (Apple Silicon)
**Researched:** 2026-11-23
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift | 5.10 / 6.0 | Primary programming language | Modern, type-safe, strict concurrency support, native Apple Silicon optimization |
| SwiftUI | macOS 14.0+ (Sonoma/Sequoia) | Declarative UI framework | Native macOS desktop components, `MenuBarExtra`, `@Observable` macro, native dark/light styling |
| SwiftData | macOS 14.0+ | Modern persistence framework | Native replacement for CoreData; declarative `@Model`, type-safe schema, effortless future CloudKit sync |
| Swift Package Manager (SPM) | Swift 5.10+ | Dependency management | Native Apple ecosystem integration, zero third-party package manager overhead |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| KeyboardShortcuts (Sindre Sorhus) | ~2.2.0 | Global system keyboard shortcut recording & handling | User-configurable global hotkeys to start/stop the timer from any application |
| Swift Charts (Apple) | Native (macOS 14+) | Data visualization & reporting | Building polished productivity charts, weekly time breakdowns, and project distribution graphs |
| UniformTypeIdentifiers | Native | Export file types | CSV and JSON report exports |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode / swift-driver | Compiler, builder, test runner | Standard development environment for Apple Silicon macOS binaries |
| Swift Testing (`import Testing`) | Unit & integration testing | Modern Swift testing framework with `@Test`, `#expect`, and parameterization |
| XCTest | UI & system integration testing | Automated testing of window and menu bar interactions |

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Swift & SwiftUI | Tauri v2 (Rust + React) | When multi-platform (Windows/Linux) is an immediate Day-1 requirement |
| Swift & SwiftUI | Electron | When team has only JavaScript developers and memory/CPU efficiency is secondary |
| SwiftData | CoreData | Only if targeting legacy macOS versions (< 14.0) |
| SwiftData | SQLite / GRDB.swift | When highly complex custom SQL indexing or cross-language portability is needed |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Combine `ObservableObject` / `@Published` | Deprecated paradigm in modern Swift; introduces unnecessary boilerplate and re-render overhead | Modern Swift `@Observable` macro |
| Naive `Timer.scheduledTimer` for elapsed time | Pauses during system sleep or App Nap, accumulating massive timing drift | Wall-clock `Date` timestamp delta calculation (`Date().timeIntervalSince(startDate)`) |
| Electron / Node.js wrapper | Excessive memory consumption (150-250MB idle), sluggish menu bar extra, non-native feel | Native Swift & SwiftUI (< 35MB idle footprint) |
| Hardcoded CoreGraphics drawing | Fragile across macOS display scaling and dark/light modes | Declarative SwiftUI Shape / Path / Canvas views |

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| SwiftData | macOS 14.0+ | Requires macOS 14 Sonoma or macOS 15 Sequoia |
| Swift Charts | macOS 13.0+ | Fully supported on macOS 14+ |
| KeyboardShortcuts | macOS 13.0+ | Fully compatible with macOS 14 and 15 |

## Sources

- Apple Developer Documentation — *SwiftData Model and Container Architecture*
- Apple Developer Documentation — *MenuBarExtra and macOS Window Management*
- Apple Human Interface Guidelines — *macOS Desktop App Design Patterns*

---
*Stack research for: Native macOS Desktop Time Tracking*
*Researched: 2026-11-23*
