# Component Specs: TimeStamp (Toggl Track Replica)

Specification of UI primitives and components based on Toggl Track macOS Desktop reference screenshots (`replica/screens/`).

---

## 1. Window Shell & Layout Modes

### Compact Tracker Window (S01)
- **Role**: Dedicated daily companion tracker window.
- **Dimensions**: Fixed default ~440px wide, ~700px high (min width 380px, max width 520px).
- **Window Chrome**: Standard macOS title bar with traffic lights, title centered ("Workspace" / Workspace Name), dark title bar background matching app surface (`#14101A`).
- **Surface**: Dark plum background (`#14101A`).

### Full Dashboard Window (S05)
- **Role**: In-depth reporting, full calendar timeline, and project/client administration.
- **Dimensions**: Min width 960px, ideal width 1180px, min height 640px.
- **Layout**: Collapsible left sidebar navigation (`#1E1322`) + sticky top timer bar + main content workspace (`#14101A`).

---

## 2. TimerBar (Top Sticky Bar)

- **Variants**:
  - `compact`: S01 companion window.
  - `full`: S05 dashboard window.
- **Layout**:
  - **Left**: Pomodoro icon button (circular tomato indicator) or status glyph.
  - **Center-Left**: Borderless description text field with placeholder `"What are you working on?"`. Font: 13pt regular, text color `#F5F4F8`.
  - **Center-Right**: Monospaced duration ticker `"0:00:00"`. Font: 15pt bold monospaced digits.
  - **Right Action**:
    - When Idle: Circular Magenta Start button (36x36pt, `#E54583`, white play triangle) + manual entry toggle icon.
    - When Running: Circular Red Stop button (36x36pt, `#FF453A`, white square) + secondary Pause/Resume button.
- **Secondary Action Row** (under description):
  - 📁 **Project/Task Button**: Icon-only or icon + project pill. Opens `ProjectPickerPopover`.
  - 🏷️ **Tag Button**: Tag glyph. Opens tag selection popover.
  - 💲 **Billable Button**: Dollar glyph (`#9E97AA` when non-billable, `#30D158` when billable).

---

## 3. ProjectPickerPopover (S02)

- **Role**: Instant fuzzy search & hierarchical project/client selection.
- **Anchor**: Attached to the 📁 Folder icon in `TimerBar`.
- **Dimensions**: Width ~300px, max height ~400px.
- **Components**:
  - **Search Input**: Top text field with bright green outline focus ring (`#36B37E`, 2px radius 8px). Placeholder: `"Search by project, task or client"`.
  - **Deselect Row**: `"• No Project"` with subtle hover highlight.
  - **Grouped List**:
    - Client header: Uppercase tracking text (e.g., `NO CLIENT`, `CLIENT NAME`). Font: 11pt bold, color `#9E97AA`.
    - Project row: 8px colored circle dot + Project name + optional task count / expansion.
    - Hover state: Background `#2A223A` with rounded corners.
  - **Sticky Footer**:
    - Divider line (`#362B4A`).
    - Button: `+ Create project` (magenta `+` icon, 13pt medium text).

---

## 4. SegmentedSwitcher (View Toggle)

- **Role**: Quick switching between List and Calendar modes.
- **Shape**: Full-width capsule / pill container with dark inset background (`#100D15`).
- **Options**: `[ List | Calendar ]` (and `Timesheet` in full view).
- **Selected State**: Elevated rounded thumb (`#2A223A`) with white text.
- **Subheader Text**:
  - Left: `TODAY TOTAL 0:00:00` (11pt uppercase, bold ticker).
  - Right: `EXPLORE ON WEB APP ↗` (11pt uppercase link).

---

## 5. GoalsCard (S01)

- **Role**: Daily / weekly goal tracking drawer.
- **Container**: Rounded card (`#201A2C`), 12px radius, subtle border (`#362B4A`).
- **Header**:
  - Left: `Goals (4/4)` (13pt bold).
  - Right: `+` add goal button and `^` collapse chevron.
- **Item Row**:
  - Left: Circular bronze icon badge (`#D4973B` with dark glyph: target, book, timer).
  - Center: Goal Title (e.g. `IELTS Daily 30 to 45 minutes`, 13pt regular).
  - Right: Status badge `KEEP GOING` (10pt bold uppercase, `#9E97AA`).

---

## 6. EmptyStateIllustration

- **Variants**:
  - `welcome`: Hands on laptop illustration inside white circle backdrop + `"Let's get tracking!"` + `"Get ready to track time and boost your productivity."`.
  - `no-entries`: Purple binoculars (`#BF5AF2`) under soft pink clouds (`#E8A0BF`) + `"No entries found in the selected period"` + `"Load old entries"` button.
  - `empty-reports`: Binoculars graphic + `"Nothing to see here..."` + `"We couldn't find any time entries."`.

---

## 7. ReportsSummaryScreen (S06)

- **Subnav Tabs**: `[ Summary | Detailed | Workload | Profitability | My reports ]` with active magenta underline indicator.
- **Toolbar**:
  - Date Range Stepper: `< [Calendar] This week W48 >`.
  - Filter Pills: Capsule buttons with dropdown chevron (`Client`, `Project`, `Tag`, `Description`, `+ Add filter`).
- **4 KPI Metric Cards**:
  - Grid: 4 equal cards in a row (`Total Hours`, `Billable Hours`, `Amount`, `Average Daily Hours`).
  - Values: Large bold numbers or `-` placeholder.
- **Chart Cards**:
  - Card 1: `Duration by day` (Bar chart).
  - Card 2: `Client distribution` (Donut chart with `Slice by: Clients v`).
  - Table: `Project and member breakdown`.
