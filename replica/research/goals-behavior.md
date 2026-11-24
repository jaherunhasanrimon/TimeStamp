# Toggl Track Goals Reference Behavior & Specifications

## 1. Executive Overview
In Toggl Track, **Time Tracking Goals** are recurring productivity targets configured by users to establish priority focus, ensure minimum required effort, or enforce upper limits on time-sink activities directly on the Timer page.

---

## 2. Core Goal Attributes & Data Model

| Field | Type | Description | Reference Rule |
|:---|:---|:---|:---|
| `title` | String | User-defined label (e.g. "Daily Deep Work", "Client Retainer") | Required, max 100 chars |
| `iconName` | String | System badge icon (target, book, computer, chart, flame, etc.) | Rendered on gold/bronze circular badge |
| `targetDuration` | Seconds | Goal target time in hours and minutes | Stored as integer seconds |
| `targetType` | Enum | `.atLeast` ("At least") or `.lessThan` ("Less than") | Determines completion condition |
| `cadence` | Enum | `.daily` ("Each day"), `.weekdays` ("Each weekday (Mon–Fri)"), `.weekly` ("Each week") | Governs calendar interval boundary |
| `projectId` | UUID? | Associated project filter | Optional. When `nil`, applies to "Any Project" |
| `taskId` | UUID? | Associated task filter within project | Optional |
| `clientId` | UUID? | Associated client filter (matches any project of client) | Optional |
| `tagIds` | [UUID] | Tag filter | Optional. When non-empty, matches entries having any/all matching tags |
| `isBillableOnly` | Bool | Restricts progress strictly to billable time entries | Optional toggle |
| `createdAt` | Date | Timestamp of goal creation | Immutable |
| `updatedAt` | Date | Timestamp of last modification | Updated on edit |

---

## 3. Goal Types: "At Least" vs. "Less Than"

### A. "At least" Target (`targetType = .atLeast`)
- **Intent**: Motivate positive effort (e.g. "Track at least 4 hours of development daily").
- **Progress Calculation**:
  $$\text{Progress \%} = \min\left(1.0, \frac{\text{completedDuration}}{\text{targetDuration}}\right)$$
- **Completion Condition**:
  $$\text{isCompleted} = \text{completedDuration} \ge \text{targetDuration}$$
- **UI State**:
  - While $\text{completedDuration} < \text{targetDuration}$: Progress bar fills in Bronze/Gold, action button displays `KEEP GOING` (or `TRACKING` if matching timer runs).
  - When $\text{completedDuration} \ge \text{targetDuration}$: Icon turns green with checkmark, action pill displays `COMPLETED` in green (`#36B37E`).

### B. "Less than" Target (`targetType = .lessThan`)
- **Intent**: Enforce ceiling / limit on time-sinks (e.g. "Spend less than 2 hours in meetings per week").
- **Progress Calculation**:
  $$\text{Progress \%} = \frac{\text{completedDuration}}{\text{targetDuration}}$$
- **Completion Condition**:
  - Within target limit: `isCompleted = true` (Goal is satisfied as long as user hasn't exceeded the ceiling).
  - If $\text{completedDuration} > \text{targetDuration}$: Goal is **EXCEEDED / OVER LIMIT** (Warning state in red/orange `#FF453A`, e.g. "OVER LIMIT").
- **UI State**:
  - While $\text{completedDuration} \le \text{targetDuration}$: Inverted progress or status indicating remaining buffer ("1h 15m remaining").
  - When $\text{completedDuration} > \text{targetDuration}$: Pill displays `OVER LIMIT` in red.

---

## 4. Recurrence & Calendar Boundaries

Progress is calculated strictly within local calendar boundaries:

1. **Each Day (`cadence = .daily`)**:
   - Interval: From local `calendar.startOfDay(for: now)` to `startOfDay(for: tomorrow)`.
   - Resets automatically at midnight local time every day.
2. **Each Weekday (`cadence = .weekdays`)**:
   - Semantics: An individual recurring daily target for **each weekday** (Monday through Friday), NOT a combined 5-day duration pool.
   - For example: A 5-hour target each weekday means 5 hours on Monday, 5 hours on Tuesday, etc.
   - Calculation: Evaluates entries on the active current weekday (`startOfDay(for: now)` to `startOfDay(for: tomorrow)` when Monday–Friday).
   - On Saturday and Sunday: The active weekday tracking pauses; displays Friday's completed status or a muted weekend state without accumulating weekend time towards weekday targets.
3. **Each Week (`cadence = .weekly`)**:
   - Interval: From Monday 00:00:00 (first day of ISO week) to the following Monday 00:00:00.
   - Resets automatically on Monday morning.

---

## 5. Association & Client Data Hierarchy

Follow Toggl Track's exact data hierarchy:
- A **Client** has multiple projects.
- Each **Project** belongs to one client (`project.clientId: UUID?`).
- **Time entries** belong to projects (`entry.projectId: UUID?`), never directly to clients.

When evaluating whether a `TimeEntry` contributes to a `Goal`:
1. **Time Range**: `entry.startDate >= intervalStart && entry.startDate < intervalEnd`.
2. **Project & Client Association**:
   - If `goal.projectId != nil`: `entry.projectId == goal.projectId`.
   - If `goal.projectId == nil` and `goal.clientId != nil`: Matched through the project's client association:
     $$\text{store.project(for: entry.projectId)?.clientId} == \text{goal.clientId}$$
   - If both are `nil`: Matches any project ("Any Project").
3. **Task Filter**: If `goal.taskId != nil`: `entry.taskId == goal.taskId`.
4. **Tag Filter**: If `!goal.tagIds.isEmpty`: `entry.tagIds.contains(where: { goal.tagIds.contains($0) })`.
5. **Billable Filter**: If `goal.isBillableOnly == true`: `entry.isBillable == true`.

---

## 6. Real-time Live Timer Contribution & Anti-Double-Counting

- If an active running timer (`timerManager.activeEntry`) matches the goal's criteria:
  - Its running elapsed seconds (`activeDuration`) are dynamically added to `completedDuration`.
- **Anti-Double-Counting Rule**:
  - The running timer in memory has `endDate == nil`.
  - Stored historical entries have `endDate != nil`.
  - When the timer is stopped, it transitions into a stored historical entry.
  - Active duration is added **only once** while running and smoothly transitions into stored time upon stopping.

---

## 7. How Existing Time Entries Affect Newly Created Goals

- **Toggl Track Standard**: Goals are **retroactively evaluated against all matching entries within the current active recurrence period**.
- If a user has already tracked 2 hours on Project A today, and creates a 1-hour daily goal for Project A, that goal will immediately evaluate to 2h/1h (100% completed).
- **User Experience Requirement**:
  - The New Goal editor MUST show a **Live Progress Preview**:
    - *"Current progress today: 0h 0m of 1h 0m (0%)"*
    - If matching entries already exist, it clearly displays: *"Matching time in this period: 1h 30m — Goal will be reached upon creation."*
    - This provides complete transparency and eliminates surprise "instant completions".

---

## 8. Goal Limits & Product Decision for TimeStamp

- **Toggl Track Web/Desktop**: Restricts free plans to a maximum of 4 active goals, requiring a paid Starter/Premium plan to create more.
- **TimeStamp Implementation**:
  - TimeStamp is a free, native, independent macOS desktop application.
  - **No paywalls, no upgrade prompts, no artificial 4-goal limit**.
  - Users can create unlimited active personal goals.
  - Header displays dynamic counts: `Goals (completed / total)`.

---

## 9. Data Safety & Duration Calculation Integrity

1. **Duration Invariance across All Pathways**:
   - Running: `accumulatedDuration + max(0, Date().timeIntervalSince(startDate))`
   - Paused: `accumulatedDuration`
   - Stopped / Stored: `accumulatedDuration > 0 ? accumulatedDuration : max(0, endDate.timeIntervalSince(startDate))`
   - Manual Log: `endDate.timeIntervalSince(startDate)`
   - No double counting of `accumulatedDuration` and `(endDate - startDate)`.
2. **Zero-Loss Data Safety**:
   - Existing user entries and projects are never silently deleted on update or launch.
   - Clean install starts with zero entries, zero goals, zero sample clients/projects.
   - Production auto-seeding (`seedSampleGoalsIfNeeded`) is permanently removed from production init.
   - Any manual data reset requires explicit confirmation and creates a timestamped backup in `~/Library/Application Support/TimeStamp/backups/`.
