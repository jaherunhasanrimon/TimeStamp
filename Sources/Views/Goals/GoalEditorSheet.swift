import SwiftUI

/// Toggl Track Authentic Goal Editor matching `toggl_macos_goal_popover.jpg`.
/// Supports Goal Title + Badge Icon, Multi-Project selection (`TRACK`), Client/Task/Tag/Billable
/// filters, At Least / Less Than numeric hours + Daily/Weekday/Weekly cadence (`FOR`),
/// optional End Date (`UNTIL` + `No end date`), Live Progress Preview, Delete, and Save.
public struct GoalEditorSheet: View {
    public enum Mode {
        case create
        case edit(Goal)
    }

    public let mode: Mode
    @Environment(PersistenceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var targetType: GoalTargetType = .atLeast
    @State private var cadence: GoalCadence = .daily
    @State private var targetHoursText: String = "1"
    @State private var selectedProjectIds: [UUID] = []
    @State private var selectedClientId: UUID? = nil
    @State private var selectedTaskId: UUID? = nil
    @State private var selectedTagIds: [UUID] = []
    @State private var billableFilter: GoalBillableFilter = .all
    @State private var selectedIcon: String = "target"
    @State private var startDate: Date = Date()
    @State private var hasNoEndDate: Bool = true
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

    @State private var isProjectPickerPresented: Bool = false
    @State private var isTagPickerPresented: Bool = false
    @State private var isCreateProjectSheetPresented: Bool = false
    @State private var knownProjectIds: Set<UUID> = []

    private let availableIcons = [
        "target", "flame.fill", "book.fill", "desktopcomputer",
        "hammer.fill", "star.fill", "bolt.fill", "checkmark.seal.fill"
    ]

    public init(mode: Mode = .create) {
        self.mode = mode
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var parsedHours: Double {
        let cleaned = targetHoursText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        return max(0.05, Double(cleaned) ?? 1.0)
    }

    private var draftTargetDuration: TimeInterval {
        max(60, parsedHours * 3600.0)
    }

    private var livePreview: (matchingDuration: TimeInterval, percentage: Double, isCompleted: Bool, isOverLimit: Bool) {
        store.progressPreview(
            targetDuration: draftTargetDuration,
            targetType: targetType,
            cadence: cadence,
            projectId: selectedProjectIds.first,
            projectIds: selectedProjectIds,
            clientId: selectedClientId,
            taskId: selectedTaskId,
            tagIds: selectedTagIds,
            billableFilter: billableFilter,
            startDate: startDate,
            endDate: hasNoEndDate ? nil : endDate
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("GOAL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.8)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.cardBackground)

            Divider().overlay(AppColors.border)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 1. Title + Icon Pill (Toggl Green Ring)
                    HStack(spacing: 8) {
                        TextField("e.g. Deep Work 2 hrs", text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(AppColors.insetBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(AppColors.focusBorder, lineWidth: 1.5)
                            )

                        Menu {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Label(iconLabel(icon), systemImage: icon)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.togglMagenta)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(AppColors.insetBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                    }

                    // 2. TRACK section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("TRACK")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                            Image(systemName: "info.circle")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary.opacity(0.7))
                                .help("Select projects, client, task, tags, or billable filter for this goal.")
                        }

                        HStack(spacing: 10) {
                            // Multi-Project Picker Popover
                            Button {
                                isProjectPickerPresented.toggle()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "folder")
                                        .font(.system(size: 12))
                                        .foregroundStyle(selectedProjectIds.isEmpty ? .secondary : AppColors.togglMagenta)
                                    if !selectedProjectIds.isEmpty {
                                        Text("\(selectedProjectIds.count)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(AppColors.togglMagenta)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(selectedProjectIds.isEmpty ? AppColors.insetBackground : AppColors.togglMagenta.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(selectedProjectIds.isEmpty ? AppColors.border : AppColors.togglMagenta.opacity(0.5), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .help("Track specific projects")
                            .popover(isPresented: $isProjectPickerPresented, arrowEdge: .bottom) {
                                multiProjectPopover
                            }

                            // Tag Picker Popover
                            Button {
                                isTagPickerPresented.toggle()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "tag")
                                        .font(.system(size: 12))
                                        .foregroundStyle(selectedTagIds.isEmpty ? .secondary : AppColors.togglMagenta)
                                    if !selectedTagIds.isEmpty {
                                        Text("\(selectedTagIds.count)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(AppColors.togglMagenta)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(selectedTagIds.isEmpty ? AppColors.insetBackground : AppColors.togglMagenta.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(selectedTagIds.isEmpty ? AppColors.border : AppColors.togglMagenta.opacity(0.5), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .help("Filter by tags")
                            .popover(isPresented: $isTagPickerPresented, arrowEdge: .bottom) {
                                TagPickerPopover(selectedTagIds: $selectedTagIds) {
                                    isTagPickerPresented = false
                                }
                            }

                            // Client filter dropdown (optional)
                            if selectedProjectIds.isEmpty && !store.clients.isEmpty {
                                Picker("", selection: $selectedClientId) {
                                    Text("Any Client").tag(Optional<UUID>.none)
                                    ForEach(store.clients) { c in
                                        Text(c.name).tag(Optional<UUID>.some(c.id))
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: 130)
                            }

                            // Billable filter pill
                            Picker("", selection: $billableFilter) {
                                ForEach(GoalBillableFilter.allCases) { f in
                                    Text(f.displayName).tag(f)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: 135)
                        }

                        // Selected project & tag chips
                        if !selectedProjectIds.isEmpty || !selectedTagIds.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(selectedProjectIds, id: \.self) { pId in
                                        if let proj = store.project(for: pId) {
                                            HStack(spacing: 4) {
                                                Circle()
                                                    .fill(Color(hex: proj.colorHex))
                                                    .frame(width: 7, height: 7)
                                                Text(proj.name)
                                                    .font(.system(size: 10, weight: .medium))
                                                Button {
                                                    selectedProjectIds.removeAll { $0 == pId }
                                                } label: {
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 8, weight: .bold))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(Color(hex: proj.colorHex).opacity(0.16))
                                            .clipShape(Capsule())
                                        }
                                    }

                                    ForEach(selectedTagIds, id: \.self) { tId in
                                        if let tag = store.tag(for: tId) {
                                            HStack(spacing: 4) {
                                                Text("#\(tag.name)")
                                                    .font(.system(size: 10, weight: .medium))
                                                Button {
                                                    selectedTagIds.removeAll { $0 == tId }
                                                } label: {
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 8, weight: .bold))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(Color.secondary.opacity(0.15))
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. FOR section (at least / less than | hours | every day/weekday/week)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("FOR")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                            Image(systemName: "info.circle")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary.opacity(0.7))
                        }

                        HStack(spacing: 8) {
                            Picker("", selection: $targetType) {
                                ForEach(GoalTargetType.allCases) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 108)

                            TextField("1", text: $targetHoursText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .frame(width: 52)
                                .padding(.vertical, 5)
                                .background(AppColors.insetBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )

                            Text("hours")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)

                            Picker("", selection: $cadence) {
                                ForEach(GoalCadence.allCases) { c in
                                    Text(c.displayName).tag(c)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }
                    }

                    // 4. UNTIL section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("UNTIL")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                            Image(systemName: "info.circle")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary.opacity(0.7))
                        }

                        if hasNoEndDate {
                            Text("No end date")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(AppColors.insetBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                        } else {
                            DatePicker("End date", selection: $endDate, in: startDate..., displayedComponents: .date)
                                .labelsHidden()
                        }

                        Toggle("No end date", isOn: $hasNoEndDate)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 12))
                    }

                    // 5. LIVE PROGRESS PREVIEW Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("LIVE PROGRESS PREVIEW (\(cadence.rawValue.uppercased()))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)

                            Spacer()

                            let statusText: String = {
                                if livePreview.isOverLimit {
                                    return "OVER LIMIT"
                                } else if livePreview.isCompleted {
                                    return "COMPLETED"
                                } else {
                                    return "\(Int(livePreview.percentage * 100))%"
                                }
                            }()

                            let statusColor: Color = {
                                if livePreview.isOverLimit {
                                    return AppColors.destructive
                                } else if livePreview.isCompleted {
                                    return AppColors.success
                                } else {
                                    return AppColors.goalGold
                                }
                            }()

                            Text(statusText)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(statusColor)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(AppColors.insetBackground)
                                    .frame(height: 5)

                                let barColor: Color = livePreview.isOverLimit ? AppColors.destructive :
                                    (livePreview.isCompleted ? AppColors.success : AppColors.goalGold)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(barColor)
                                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(livePreview.percentage))), height: 5)
                            }
                        }
                        .frame(height: 5)

                        Text(livePreview.matchingDuration == 0
                             ? "No matching entries logged yet. Starts cleanly at 0h 00m."
                             : "\(DateHelper.formatHumanDuration(livePreview.matchingDuration)) of \(DateHelper.formatHumanDuration(draftTargetDuration)) currently tracked.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(AppColors.secondaryCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                .padding(16)
            }

            Divider().overlay(AppColors.border)

            // Footer Actions
            HStack {
                if case .edit(let existingGoal) = mode {
                    Button(role: .destructive) {
                        store.deleteGoal(id: existingGoal.id)
                        dismiss()
                    } label: {
                        Text("Delete")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.destructive)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColors.insetBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(AppColors.destructive.opacity(0.35), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: saveGoal) {
                    Text("Save")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : AppColors.togglMagenta)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(16)
            .background(AppColors.cardBackground)
        }
        .frame(width: 430, height: 590)
        .background(AppColors.background)
        .sheet(isPresented: $isCreateProjectSheetPresented) {
            ProjectEditorSheet(mode: .create())
        }
        .onAppear {
            knownProjectIds = Set(store.projects.map { $0.id })
            if case .edit(let existingGoal) = mode {
                title = existingGoal.title
                targetType = existingGoal.targetType
                cadence = existingGoal.cadence
                let hrs = existingGoal.targetDuration / 3600.0
                targetHoursText = hrs.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(hrs))" : String(format: "%.2g", hrs)
                selectedProjectIds = existingGoal.effectiveProjectIds
                selectedClientId = existingGoal.clientId
                selectedTaskId = existingGoal.taskId
                selectedTagIds = existingGoal.tagIds
                billableFilter = existingGoal.billableFilter
                selectedIcon = existingGoal.iconName
                startDate = existingGoal.startDate
                if let end = existingGoal.endDate {
                    hasNoEndDate = false
                    endDate = end
                } else {
                    hasNoEndDate = true
                }
            }
        }
        .onChange(of: store.projects) { _, newProjects in
            let currentIds = Set(newProjects.map { $0.id })
            let addedIds = currentIds.subtracting(knownProjectIds)
            if let newId = addedIds.first, !selectedProjectIds.contains(newId) {
                selectedProjectIds.append(newId)
                selectedClientId = nil
                knownProjectIds = currentIds
            }
        }
    }

    @ViewBuilder
    private var multiProjectPopover: some View {
        let activeProjects = store.projects.filter { !$0.isArchived }
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Select Projects")
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                if !selectedProjectIds.isEmpty {
                    Button("Clear") {
                        selectedProjectIds.removeAll()
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.togglMagenta)
                    .buttonStyle(.plain)
                }
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if activeProjects.isEmpty {
                        Text("No active projects yet")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(activeProjects) { proj in
                            let isChecked = selectedProjectIds.contains(proj.id)
                            Button {
                                if isChecked {
                                    selectedProjectIds.removeAll { $0 == proj.id }
                                } else {
                                    selectedProjectIds.append(proj.id)
                                    selectedClientId = nil
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 12))
                                        .foregroundStyle(isChecked ? AppColors.togglMagenta : .secondary)
                                    Circle()
                                        .fill(Color(hex: proj.colorHex))
                                        .frame(width: 8, height: 8)
                                    Text(proj.name)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)

            Divider()

            HStack {
                Button {
                    isProjectPickerPresented = false
                    isCreateProjectSheetPresented = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .foregroundStyle(AppColors.togglMagenta)
                        Text("Create project")
                            .foregroundStyle(.primary)
                    }
                    .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Done") {
                    isProjectPickerPresented = false
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.togglMagenta)
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(width: 260)
        .background(AppColors.popoverBackground)
    }

    private func iconLabel(_ icon: String) -> String {
        switch icon {
        case "target": return "Target"
        case "flame.fill": return "Flame"
        case "book.fill": return "Study"
        case "desktopcomputer": return "Computer"
        case "hammer.fill": return "Build"
        case "star.fill": return "Star"
        case "bolt.fill": return "Bolt"
        case "checkmark.seal.fill": return "Check"
        default: return icon
        }
    }

    private func saveGoal() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let resolvedEnd: Date? = hasNoEndDate ? nil : endDate

        switch mode {
        case .create:
            let goal = Goal(
                title: trimmed,
                targetDuration: draftTargetDuration,
                targetType: targetType,
                cadence: cadence,
                projectId: selectedProjectIds.first,
                projectIds: selectedProjectIds,
                clientId: selectedClientId,
                taskId: selectedTaskId,
                tagIds: selectedTagIds,
                billableFilter: billableFilter,
                iconName: selectedIcon,
                startDate: startDate,
                endDate: resolvedEnd
            )
            store.saveGoal(goal)

        case .edit(let existing):
            existing.title = trimmed
            existing.targetDuration = draftTargetDuration
            existing.targetType = targetType
            existing.cadence = cadence
            existing.projectIds = selectedProjectIds
            existing.projectId = selectedProjectIds.first
            existing.clientId = selectedClientId
            existing.taskId = selectedTaskId
            existing.tagIds = selectedTagIds
            existing.billableFilter = billableFilter
            existing.iconName = selectedIcon
            existing.startDate = startDate
            existing.endDate = resolvedEnd
            store.saveGoal(existing)
        }

        dismiss()
    }
}
