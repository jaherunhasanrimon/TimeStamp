import SwiftUI

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
    @State private var targetHours: Int = 1
    @State private var targetMinutes: Int = 0
    @State private var selectedProjectId: UUID? = nil
    @State private var selectedClientId: UUID? = nil
    @State private var selectedTagIds: [UUID] = []
    @State private var billableFilter: GoalBillableFilter = .all
    @State private var selectedIcon: String = "target"

    // Popover & Modal state
    @State private var isProjectPickerPresented: Bool = false
    @State private var isTagPickerPresented: Bool = false
    @State private var isCreateProjectSheetPresented: Bool = false
    @State private var knownProjectIds: Set<UUID> = []

    private let availableIcons: [String] = [
        "target",
        "book.fill",
        "desktopcomputer",
        "chart.line.uptrend.xyaxis",
        "flame.fill",
        "clock.fill",
        "pencil.line",
        "star.fill"
    ]

    public init(mode: Mode = .create) {
        self.mode = mode
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var draftTargetDuration: TimeInterval {
        TimeInterval(max(5 * 60, (targetHours * 3600) + (targetMinutes * 60)))
    }

    private var selectedProject: Project? {
        guard let id = selectedProjectId else { return nil }
        return store.projects.first(where: { $0.id == id })
    }

    private var selectedClient: Client? {
        guard let id = selectedClientId else { return nil }
        return store.clients.first(where: { $0.id == id })
    }

    // Live preview calculation matching real entries in active period
    private var livePreview: (matchingDuration: TimeInterval, percentage: Double, isCompleted: Bool, isOverLimit: Bool) {
        store.progressPreview(
            targetDuration: draftTargetDuration,
            targetType: targetType,
            cadence: cadence,
            projectId: selectedProjectId,
            clientId: selectedClientId,
            taskId: nil,
            tagIds: selectedTagIds,
            billableFilter: billableFilter
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditMode ? "Edit Goal" : "New Goal")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.primary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(AppColors.cardBackground)

            Divider()
                .overlay(AppColors.border)

            // Form Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 1. Goal Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("GOAL TITLE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)

                        TextField("e.g. Daily Deep Work, Client Retainer, Study", text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .padding(8)
                            .background(AppColors.insetBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }

                    // 2. Goal Type & Recurrence Row
                    HStack(spacing: 12) {
                        // Goal Type (At least vs Less than)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("GOAL TYPE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)

                            Picker("", selection: $targetType) {
                                ForEach(GoalTargetType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Recurrence / Cadence
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CADENCE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)

                            Picker("", selection: $cadence) {
                                ForEach(GoalCadence.allCases) { c in
                                    Text(c.rawValue).tag(c)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    // 3. Target Duration (Hours and Minutes)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TARGET DURATION")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            HStack {
                                Stepper(value: $targetHours, in: 0...24) {
                                    Text("\(targetHours) hr")
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.insetBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            HStack {
                                Stepper(value: $targetMinutes, in: 0...55, step: 5) {
                                    Text("\(targetMinutes) min")
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.insetBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            Text("= \(DateHelper.formatHumanDuration(draftTargetDuration))")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // 4. Project Association (Searchable Popover + Inline Creation)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("ASSOCIATED PROJECT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button(action: {
                                isCreateProjectSheetPresented = true
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("New project")
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppColors.togglMagenta)
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            isProjectPickerPresented.toggle()
                        }) {
                            HStack(spacing: 8) {
                                if let project = selectedProject {
                                    Circle()
                                        .fill(Color(hex: project.colorHex))
                                        .frame(width: 8, height: 8)
                                    Text(project.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color.primary)

                                    if let cId = project.clientId, let client = store.client(for: cId) {
                                        Text("• \(client.name)")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button(action: {
                                        selectedProjectId = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Clear project filter")
                                } else {
                                    Image(systemName: "folder")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                    Text("Any Project (All Logged Time)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(AppColors.insetBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $isProjectPickerPresented, arrowEdge: .bottom) {
                            ProjectPickerPopover(
                                selectedProjectId: $selectedProjectId,
                                selectedTaskId: .constant(nil),
                                onDismiss: {
                                    isProjectPickerPresented = false
                                }
                            )
                        }
                    }

                    // 5. Tags & Billable Filters
                    HStack(spacing: 12) {
                        // Tag Filter Button
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TAGS FILTER")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)

                            Button(action: {
                                isTagPickerPresented.toggle()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: selectedTagIds.isEmpty ? "tag" : "tag.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(selectedTagIds.isEmpty ? Color.secondary : AppColors.togglMagenta)

                                    Text(selectedTagIds.isEmpty ? "All Tags" : "\(selectedTagIds.count) tag(s)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(selectedTagIds.isEmpty ? .secondary : .primary)

                                    Spacer()

                                    if !selectedTagIds.isEmpty {
                                        Button(action: { selectedTagIds.removeAll() }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(AppColors.insetBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: $isTagPickerPresented, arrowEdge: .bottom) {
                                TagPickerPopover(
                                    selectedTagIds: $selectedTagIds,
                                    onDismiss: { isTagPickerPresented = false }
                                )
                            }
                        }

                        // Billable Filter
                        VStack(alignment: .leading, spacing: 6) {
                            Text("BILLABLE FILTER")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)

                            Picker("", selection: $billableFilter) {
                                ForEach(GoalBillableFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    }

                    // 6. Selected Tags Badges (if any)
                    if !selectedTagIds.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(selectedTagIds, id: \.self) { tagId in
                                    if let tag = store.tags.first(where: { $0.id == tagId }) {
                                        HStack(spacing: 4) {
                                            Text("#\(tag.name)")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundStyle(Color.white)
                                            Button(action: { selectedTagIds.removeAll { $0 == tagId } }) {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundStyle(Color.white.opacity(0.8))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color(hex: tag.colorHex).opacity(0.85))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    // 7. Badge Icon Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("BADGE ICON")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    ZStack {
                                        Circle()
                                            .stroke(selectedIcon == icon ? AppColors.togglMagenta : AppColors.border, lineWidth: selectedIcon == icon ? 2 : 1)
                                            .frame(width: 30, height: 30)
                                            .background(
                                                Circle()
                                                    .fill(selectedIcon == icon ? AppColors.togglMagenta.opacity(0.15) : AppColors.insetBackground)
                                            )

                                        Image(systemName: icon)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(selectedIcon == icon ? AppColors.togglMagenta : AppColors.goalGold)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // 8. LIVE PROGRESS PREVIEW (Transparency Card)
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

                        // Preview Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(AppColors.insetBackground)
                                    .frame(height: 5)

                                let barColor: Color = {
                                    if livePreview.isOverLimit {
                                        return AppColors.destructive
                                    } else if livePreview.isCompleted {
                                        return AppColors.success
                                    } else {
                                        return AppColors.goalGold
                                    }
                                }()

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(barColor)
                                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(livePreview.percentage))), height: 5)
                            }
                        }
                        .frame(height: 5)

                        // Status Description
                        HStack(spacing: 6) {
                            if livePreview.matchingDuration == 0 {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppColors.togglMagenta)
                                Text("No matching entries logged for this period. Goal starts at 0h 00m.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            } else if targetType == .atLeast && livePreview.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppColors.success)
                                Text("\(DateHelper.formatHumanDuration(livePreview.matchingDuration)) already tracked. Goal will be reached upon creation.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppColors.success)
                            } else if targetType == .lessThan && livePreview.isOverLimit {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppColors.destructive)
                                Text("Existing time (\(DateHelper.formatHumanDuration(livePreview.matchingDuration))) already exceeds this limit.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppColors.destructive)
                            } else {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Text("\(DateHelper.formatHumanDuration(livePreview.matchingDuration)) of \(DateHelper.formatHumanDuration(draftTargetDuration)) currently tracked.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
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

            Divider()
                .overlay(AppColors.border)

            // Footer Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button(action: saveGoal) {
                    Text(isEditMode ? "Save Changes" : "Create Goal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 16)
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
        .frame(width: 440, height: 600)
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
                let totalMin = Int(existingGoal.targetDuration / 60)
                targetHours = totalMin / 60
                targetMinutes = totalMin % 60
                selectedProjectId = existingGoal.projectId
                selectedClientId = existingGoal.clientId
                selectedTagIds = existingGoal.tagIds
                billableFilter = existingGoal.billableFilter
                selectedIcon = existingGoal.iconName
            }
        }
        .onChange(of: store.projects) { _, newProjects in
            // Auto-select newly created project from quick create flow
            let currentIds = Set(newProjects.map { $0.id })
            let addedIds = currentIds.subtracting(knownProjectIds)
            if let newId = addedIds.first {
                selectedProjectId = newId
            }
            knownProjectIds = currentIds
        }
    }

    private func saveGoal() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        switch mode {
        case .create:
            let newGoal = Goal(
                title: trimmedTitle,
                targetDuration: draftTargetDuration,
                targetType: targetType,
                cadence: cadence,
                projectId: selectedProjectId,
                clientId: selectedClientId,
                taskId: nil,
                tagIds: selectedTagIds,
                billableFilter: billableFilter,
                iconName: selectedIcon
            )
            store.saveGoal(newGoal)

        case .edit(let existingGoal):
            existingGoal.title = trimmedTitle
            existingGoal.targetDuration = draftTargetDuration
            existingGoal.targetType = targetType
            existingGoal.cadence = cadence
            existingGoal.projectId = selectedProjectId
            existingGoal.clientId = selectedClientId
            existingGoal.tagIds = selectedTagIds
            existingGoal.billableFilter = billableFilter
            existingGoal.iconName = selectedIcon
            store.saveGoal(existingGoal)
        }

        dismiss()
    }
}
