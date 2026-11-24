import SwiftUI

/// Toggl Track Collapsible Goals Card (Reference Image 1).
/// Features:
/// 1. Dynamic goal progress calculated from real TimeEntry records
/// 2. Live progress updates as active timer ticks
/// 3. Fully functional KEEP GOING button with duplicate timer prevention
/// 4. Add (+), Edit, and Delete goal sheets and context menus
/// 5. Daily and weekly targets with optional project association
public struct GoalsCardView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    @State private var isCollapsed: Bool = false
    @State private var isCreatingGoal: Bool = false
    @State private var goalToEdit: Goal? = nil

    public init() {}

    private var completedGoalsCount: Int {
        store.goals.filter { goal in
            let prog = store.progress(
                for: goal,
                activeEntry: timerManager.activeEntry,
                activeDuration: timerManager.isRunning ? timerManager.currentDuration : 0
            )
            return prog.isCompleted
        }.count
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header: Goals (completed/total) with + and ^ chevron
            HStack {
                Text("Goals (\(completedGoalsCount)/\(max(1, store.goals.count)))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.primary)

                Spacer()

                HStack(spacing: 12) {
                    // + Button to Add New Goal
                    Button(action: {
                        isCreatingGoal = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColors.togglMagenta)
                    }
                    .buttonStyle(.plain)
                    .help("Create new goal")

                    // Collapse Chevron Toggle
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isCollapsed.toggle()
                        }
                    }) {
                        Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(isCollapsed ? "Expand goals" : "Collapse goals")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if !isCollapsed {
                if store.goals.isEmpty {
                    VStack(spacing: 8) {
                        Text("No active goals")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)

                        Button("Add a goal") {
                            isCreatingGoal = true
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.togglMagenta)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(store.goals.enumerated()), id: \.element.id) { index, goal in
                            if index > 0 {
                                Divider()
                                    .overlay(AppColors.border.opacity(0.6))
                            }

                            goalRow(goal: goal)
                        }
                    }
                }
            }
        }
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .sheet(isPresented: $isCreatingGoal) {
            GoalEditorSheet(mode: .create)
        }
        .sheet(item: $goalToEdit) { goal in
            GoalEditorSheet(mode: .edit(goal))
        }
    }

    @ViewBuilder
    private func goalRow(goal: Goal) -> some View {
        let activeDuration = timerManager.isRunning ? timerManager.currentDuration : 0
        let progress = store.progress(
            for: goal,
            activeEntry: timerManager.activeEntry,
            activeDuration: activeDuration
        )
        let isMatchingTimerActive = isTimerMatching(goal: goal)

        VStack(spacing: 6) {
            HStack(spacing: 12) {
                // Circular Bronze / Gold / Success / OverLimit Icon Badge
                ZStack {
                    let strokeColor: Color = {
                        if progress.isOverLimit {
                            return AppColors.destructive
                        } else if progress.isCompleted {
                            return AppColors.success
                        } else {
                            return AppColors.goalGold
                        }
                    }()

                    Circle()
                        .stroke(strokeColor, lineWidth: 1.5)
                        .frame(width: 26, height: 26)

                    let iconImage: String = {
                        if progress.isOverLimit {
                            return "exclamationmark"
                        } else if progress.isCompleted {
                            return "checkmark"
                        } else {
                            return goal.iconName
                        }
                    }()

                    Image(systemName: iconImage)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(strokeColor)
                }

                // Title & Duration Progress
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(goal.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)

                        if let pId = goal.projectId, let project = store.project(for: pId) {
                            Circle()
                                .fill(Color(hex: project.colorHex))
                                .frame(width: 6, height: 6)
                            Text(project.name)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else if let cId = goal.clientId, let client = store.client(for: cId) {
                            Text("[\(client.name)]")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Text("\(DateHelper.formatHumanDuration(progress.completedDuration)) / \(goal.targetType.rawValue) \(DateHelper.formatHumanDuration(goal.targetDuration)) (\(goal.cadence.rawValue))")
                        .font(.system(size: 11))
                        .foregroundStyle(progress.isOverLimit ? AppColors.destructive : Color.secondary)
                }

                Spacer()

                // Action Pill: OVER LIMIT, COMPLETED, or KEEP GOING
                if progress.isOverLimit {
                    Text("OVER LIMIT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.destructive)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppColors.destructive.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else if progress.isCompleted {
                    Text("COMPLETED")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.success)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppColors.success.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else {
                    Button(action: {
                        handleKeepGoing(for: goal)
                    }) {
                        HStack(spacing: 4) {
                            if isMatchingTimerActive && timerManager.isRunning {
                                Circle()
                                    .fill(AppColors.togglMagenta)
                                    .frame(width: 6, height: 6)
                                Text("TRACKING")
                            } else {
                                Text("KEEP GOING")
                            }
                        }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isMatchingTimerActive ? AppColors.togglMagenta : Color.primary.opacity(0.85))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(isMatchingTimerActive ? AppColors.togglMagenta.opacity(0.15) : AppColors.secondaryCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    .help("Track time for this goal")
                }
            }

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.insetBackground)
                        .frame(height: 3)

                    let fillColor: Color = {
                        if progress.isOverLimit {
                            return AppColors.destructive
                        } else if progress.isCompleted {
                            return AppColors.success
                        } else {
                            return AppColors.goalGold
                        }
                    }()

                    RoundedRectangle(cornerRadius: 2)
                        .fill(fillColor)
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress.percentage))), height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contextMenu {
            Button("Track Time (Keep Going)") {
                handleKeepGoing(for: goal)
            }

            Button("Edit Goal...") {
                goalToEdit = goal
            }

            Divider()

            Button("Delete Goal", role: .destructive) {
                store.deleteGoal(id: goal.id)
            }
        }
    }

    private func isTimerMatching(goal: Goal) -> Bool {
        guard let active = timerManager.activeEntry else { return false }
        return store.entryMatchesGoal(
            entry: active,
            projectId: goal.projectId,
            clientId: goal.clientId,
            taskId: goal.taskId,
            tagIds: goal.tagIds,
            billableFilter: goal.billableFilter
        )
    }

    private func handleKeepGoing(for goal: Goal) {
        if let active = timerManager.activeEntry {
            let matches = store.entryMatchesGoal(
                entry: active,
                projectId: goal.projectId,
                clientId: goal.clientId,
                taskId: goal.taskId,
                tagIds: goal.tagIds,
                billableFilter: goal.billableFilter
            )

            if matches {
                // If paused, resume it
                if timerManager.isPaused {
                    timerManager.resume()
                }
                // Already tracking this goal; prevent duplicate sessions
                return
            } else {
                // Different timer running: stop and switch to this goal
                _ = timerManager.stop()
            }
        }

        // Start new timer associated with this goal
        timerManager.start(
            description: goal.title,
            projectId: goal.projectId,
            taskId: goal.taskId,
            tagIds: goal.tagIds,
            isBillable: (goal.billableFilter == .billableOnly)
        )
    }
}
