<!-- GSD:project-start source:PROJECT.md -->
## Project

**TimeStamp**

TimeStamp is a polished, native macOS desktop time-tracking application inspired by Toggl Track, built specifically for Apple Silicon Macs with Swift and SwiftUI. It combines a distraction-free running timer, menu bar companion, and structured time tracking (projects, tasks, clients) with lightweight local persistence and clear productivity dashboards.

**Core Value:** Frictionless, accurate time tracking that stays out of the user's way while providing immediate, reliable visibility into where time goes on macOS.

### Constraints

- **Tech Stack**: Pure Swift & SwiftUI with SwiftData — hard constraint for native macOS performance, memory efficiency (<40MB RAM), and Apple Human Interface Guidelines compliance.
- **Platform**: macOS 14.0+ Apple Silicon — leverages modern SwiftUI windowing, SwiftData persistence, and macOS menu bar extras.
- **Persistence**: Native Swift persistence store with clean `@Observable` & `Codable` schemas (`TimeEntry`, `Project`, `Task`, `Client`, `Tag`), atomic local storage, and repository pattern ensuring migration readiness for future CloudKit syncing.
- **Design System**: Strict adherence to macOS design patterns, support for both native Light and Dark system appearances, and accessible typography.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

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
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

| Skill | Description | Path |
|-------|-------------|------|
| replica-architect | >- Plans the stack, database schema and API for an app clone, from the recon map replica-recon wrote. Picks boring, managed tech, turns the inferred data model into real SQL with indexes and access rules, lists every route by flow, and orders the build as a thin vertical slice first. Use when the user says "plan the clone", "what stack should I use", "design the database", "write the schema", "plan the API", "architecture for my version of X", or after /replica-recon finishes. | `.agents/skills/replica-architect/SKILL.md` |
| replica-backend | >- Builds the backend of an app clone: auth, database migrations and access rules, payments with Stripe, email, background jobs and third-party integrations through official APIs only, plus a security checklist. Use when the user says "add login", "set up auth", "wire up the database", "add payments", "connect Stripe", "add Google Calendar", "send emails", "backend for my clone", or when /replica-build is running on fake data. | `.agents/skills/replica-backend/SKILL.md` |
| replica-brand | >- Names and rebrands an app clone so it is the user's own: name candidates with the trademark, domain, store and handle checks to run, a new palette checked for contrast, a logo brief, a voice guide, and a sweep tool that finds anything of the original left in the codebase. Use when the user says "name my app", "rebrand the clone", "make it mine", "pick a name and colours", "logo brief", "brand voice", "check for leftovers", or after /replica-entrepreneur. Always runs before /replica-launch. | `.agents/skills/replica-brand/SKILL.md` |
| replica-build | >- Rebuilds an app screen by screen from the recon map: app shell first, then the core flow as a vertical slice, then every screen with all its states, ticking off the feature matrix as it goes. Writes every line fresh, never the original's code, assets or copy. Use when the user says "build the clone", "build screen S07", "start building", "rebuild this screen", "implement the booking page", or after /replica-design. | `.agents/skills/replica-build/SKILL.md` |
| replica-deploy | >- Ships an app clone live on the user's own domain: a preflight gate (tests green, parity must-haves done, rebrand sweep clean, listing linted, legal pages up), production database and env vars, the host, DNS records for the domain and for email, Stripe live mode, OAuth redirects, monitoring, and mobile builds to TestFlight and Play. Use when the user says "deploy it", "ship it", "put it live", "connect my domain", "go to production", "publish the app", or after /replica-launch. | `.agents/skills/replica-deploy/SKILL.md` |
| replica-design | >- Rebuilds an app's design system for a clone: colour roles, type scale, spacing, radius, shadows and every component with its states, as design tokens plus component specs, with original assets instead of the target's logos, icons, illustrations or licensed fonts. Includes a WCAG contrast checker. Use when the user says "match the design", "rebuild the design system", "get the colours and fonts", "make it look like X", "design tokens for my clone", or after /replica-architect. | `.agents/skills/replica-design/SKILL.md` |
| replica-diff | >- Compares an app clone against the original: a feature parity score from the feature matrix (weighted by must, should, could) with the missing list in build order, plus a screenshot layout diff that ignores colour so a rebrand does not count against you. Two standard-library Python tools. Use when the user says "how close is my clone", "compare it to the original", "what's missing", "parity check", "diff the screens", "is it ready", or after /replica-test. | `.agents/skills/replica-diff/SKILL.md` |
| replica-entrepreneur | >- Researches the app being cloned and reads what its real users say in public reviews (App Store, Google Play, G2, Capterra, Trustpilot, Reddit, Hacker News, its own feature-request board), then ranks what they hate, what is missing and what is unsolved, turns it into a fix plan for the clone and a positioning angle you can sell. Every quote is real, verbatim and linked. Use when the user says "what do people hate about X", "read the reviews", "how do I make mine better", "find the gap", "what features are missing", "how do I position this", "make it sellable", or after /replica-diff. | `.agents/skills/replica-entrepreneur/SKILL.md` |
| replica-launch | >- Writes the launch for an app clone: the landing page built on the positioning angle, pricing set against the original's public pricing and its users' complaints, and the App Store and Google Play listing linted against the stores' limits and copycat rules. Use when the user says "landing page", "pricing", "how much should I charge", "App Store listing", "store screenshots", "launch plan", "Product Hunt", or after /replica-brand. | `.agents/skills/replica-launch/SKILL.md` |
| replica-recon | >- Reverse-engineers any app into a recon map: screen inventory, user flows, component list, inferred data model and a feature matrix, from public pages, screenshots, app store listings, help docs and the user's own account. The first step of the Replica pack. Use when the user says "clone this app", "reverse engineer X", "how does X work", "map out X", "what screens does X have", "I want to build my own version of X", "copy this app", or pastes an app's URL or App Store link and wants to rebuild it. | `.agents/skills/replica-recon/SKILL.md` |
| replica-test | >- Clicks through every flow of an app clone and tests it for bugs: a test plan generated from the recon flows with happy paths and edge cases, Playwright end-to-end tests where possible, a browser click-through where not, and bug reports in a fixed format with severity, steps and evidence. Use when the user says "test my clone", "find bugs", "QA this", "click through everything", "write e2e tests", "does it work", or after /replica-build or /replica-backend. | `.agents/skills/replica-test/SKILL.md` |
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
