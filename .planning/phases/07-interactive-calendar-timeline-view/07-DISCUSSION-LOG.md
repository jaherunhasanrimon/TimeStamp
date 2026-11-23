# Phase 7: Interactive Calendar Timeline View - Discussion Log

**Date:** 2026-11-23  
**Status:** Decisions Locked  
**Phase:** 07-interactive-calendar-timeline-view  

---

## Discussion Topics & User Selections

### Topic 1: Vertical Time Grid & Visible Hour Range (`CAL-01`)
- **Question:** How should the vertical time grid and visible hour range be structured in Day/Week views?
- **Options Presented:**
  1. *(Recommended)* Scrollable 24-hour grid (60px/hour) auto-scrolled to current time or 8:00 AM work hours.
  2. Compact workday view (7:00 AM - 8:00 PM) with an expandable toggle for off-hours.
  3. Fixed full-height 24-hour view without scrolling (scaled dynamically).
- **User Selection:** Scrollable 24-hour grid (60px/hour) auto-scrolled to current time or 8:00 AM work hours.
- **Decision:** **D-01** locked.

### Topic 2: View Switching & Date Navigation (`CAL-01`, `CAL-02`)
- **Question:** How should the user switch views (Day vs Week) and navigate between dates?
- **Options Presented:**
  1. *(Recommended)* Segmented picker `[Day | Week]` with Previous/Next date chevrons and a "Today" quick-jump button.
  2. Tab bar selector with swipe gestures between adjacent days and weeks.
  3. Standalone mini-calendar sidebar picker with Day/Week view toggle.
- **User Selection:** Segmented picker `[Day | Week]` with Previous/Next date chevrons and a "Today" quick-jump button.
- **Decision:** **D-02** locked.

### Topic 3: Overlapping Entries & Real-time Indicator (`CAL-01`, `CAL-02`)
- **Question:** How should overlapping time entries and the live current-time indicator be displayed?
- **Options Presented:**
  1. *(Recommended)* Side-by-side sub-columns (like Apple Calendar/Google Calendar) with a live red horizontal indicator line at current time.
  2. Stacked semi-transparent blocks overlapping each other with current time badge.
  3. Highlight overlapping time spans with a warning badge and list them sequentially.
- **User Selection:** Side-by-side sub-columns (like Apple Calendar/Google Calendar) with a live red horizontal indicator line at current time.
- **Decision:** **D-03**, **D-04**, **D-05** locked.

### Topic 4: Calendar Block Click Interaction (`CAL-03`)
- **Question:** What should happen when the user clicks a calendar time block (CAL-03)?
- **Options Presented:**
  1. *(Recommended)* Click opens an inspector popover with duration, project, notes, and an "Edit" button opening `EntryEditSheet` plus a "Continue" action.
  2. Click opens the full `EntryEditSheet` modal directly.
  3. Click selects the block with an inline inspector sidebar on the right.
- **User Selection:** Click opens an inspector popover with duration, project, notes, and an "Edit" button opening `EntryEditSheet` plus a "Continue" action.
- **Decision:** **D-06** locked.

---

## Downstream Impact
- Research & Planning will focus on:
  - Calendar block positioning math and sub-column overlap clustering algorithm.
  - `ScrollViewReader` coordinate auto-scrolling to current hour mark.
  - Interactive calendar block SwiftUI components with popover inspector and `EntryEditSheet` integration.
  - Week multi-column synchronized scrolling grid with daily summary headers.
