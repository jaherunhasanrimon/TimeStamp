---
phase: 1
slug: project-scaffolding-swiftdata-models-app-shell
status: approved
shadcn_initialized: false
preset: macos-native
created: 2026-11-23
---

# Phase 1 — UI Design Contract

> Visual and interaction contract for Phase 1: Project Scaffolding, SwiftData Models & App Shell. Adheres to Apple Human Interface Guidelines for macOS Apple Silicon desktops.

---

## Design System

| Property | Value |
|----------|-------|
| Framework | Native SwiftUI (macOS 14+ Sonoma & macOS 15+ Sequoia) |
| Preset | Native macOS Apple Silicon Desktop |
| Component library | Native SwiftUI controls (`NavigationSplitView`, `List`, `Button`, `Label`, `Toggle`) |
| Icon library | Apple SF Symbols 5 / 6 (`Image(systemName:)`) |
| Font | Apple San Francisco (`.system(size:weight:design:)`) |

---

## Spacing Scale

Declared values (multiples of 4pt matching macOS display grid):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Icon-to-label gaps, badge inline padding |
| sm | 8pt | Button inner padding, compact row spacing, list item gaps |
| md | 16pt | Standard card padding, toolbar element spacing, sidebar row insets |
| lg | 24pt | Section headers, detail container margins, card separations |
| xl | 32pt | Layout major gutters, empty state top spacing |
| 2xl | 48pt | Empty state illustration margins, page headers |
| 3xl | 64pt | Root window padding, minimum side gutters |

Exceptions: None.

---

## Typography

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Display | 28pt | Bold | 1.2 | Main view titles (Dashboard, Reports) |
| Heading | 20pt | Semibold | 1.25 | Section headers, modal titles |
| Label | 13pt | Medium | 1.3 | Sidebar navigation items, button text, form field labels |
| Body | 13pt | Regular | 1.4 | Entry descriptions, project names, table content |
| Caption | 11pt | Regular | 1.3 | Timestamps, metadata subtitles, status hints |
| Ticker | 14pt | Semibold | 1.0 (Monospaced) | Active timer ticker (`.monospacedDigit()`) |

---

## Color

Adheres to the 60-30-10 distribution across native Dark and Light system appearances:

| Role | Dark Mode Value | Light Mode Value | Usage |
|------|-----------------|------------------|-------|
| Dominant (60%) | `#1C1C1E` | `#FFFFFF` | Window background, primary content canvas (`Color(nsColor: .windowBackgroundColor)`) |
| Secondary (30%) | `#2C2C2E` / `Material.sidebar` | `#F2F2F7` / `Material.sidebar` | Translucent sidebar material, grouped cards, table row backgrounds, subtle border dividers (`#3A3A3C` / `#E5E5EA`) |
| Accent (10%) | `#7B61FF` (Vibrant Indigo) | `#5C3BFE` (Deep Indigo) | Active timer start/stop button, selected sidebar item pill, focused input outlines, active status indicators |
| Destructive | `#FF453A` (System Red) | `#D70015` (System Red) | Stop timer action, delete confirmation buttons |

**Accent reserved strictly for:**
1. Active timer toggle button in top bar and menu bar
2. Selected item background pill in `AppSidebar`
3. Primary action CTA buttons in modal sheets
4. Focus rings on text fields

*Never apply accent color to general body text or passive card backgrounds.*

---

## Window & Shell Layout

| Property | Value | Notes |
|----------|-------|-------|
| Default Size | 1000pt × 700pt | Balanced for 13"-16" MacBooks and desktop monitors |
| Minimum Size | 800pt × 550pt | Prevents content clipping while preserving compact usability |
| Window Style | Unified Toolbar (`showsTitle: false`) | Traffic lights blend into sidebar header; content extends smoothly |
| Sidebar Material | Native Translucent Blur (`Material.sidebar`) | Collapsible via standard macOS sidebar toggle (`toggleSidebar`) |
| Navigation Structure | Sectioned List: "Track", "Analyze", "Manage", Settings | Clear visual hierarchy |

---

## Copywriting Contract

| Element | Copy | Notes |
|---------|------|-------|
| Primary CTA | "Start Tracking" / "Stop Timer" | Clear verb + noun pair |
| Empty State Heading | "No Time Entries Logged" | Immediate clarity |
| Empty State Body | "Start the timer above or press ⌥Space to begin your first tracking session." | Actionable next step |
| Error State | "Unable to load entries. Check local data permissions." | Problem + recovery path |
| Destructive Confirmation | "Delete Entry: Are you sure you want to permanently delete this time entry? This action cannot be undone." | Explicit consequences |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| Apple SwiftUI / AppKit | Native system frameworks | Standard Apple SDK |
| SF Symbols | Native system glyphs | Standard Apple SDK |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** Approved 2026-11-23
