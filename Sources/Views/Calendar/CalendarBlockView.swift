import SwiftUI

public struct CalendarBlockView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    public let positionedBlock: PositionedBlock
    public let columnWidth: CGFloat
    public let hourHeight: CGFloat

    @State private var isPopoverPresented = false
    @State private var isEditSheetPresented = false
    @State private var isHovered = false

    public init(
        positionedBlock: PositionedBlock,
        columnWidth: CGFloat,
        hourHeight: CGFloat = 60.0
    ) {
        self.positionedBlock = positionedBlock
        self.columnWidth = columnWidth
        self.hourHeight = hourHeight
    }

    private var project: Project? {
        positionedBlock.entry.projectId.flatMap { store.project(for: $0) }
    }

    private var task: Task? {
        positionedBlock.entry.taskId.flatMap { store.task(for: $0) }
    }

    private var projectColor: Color {
        project.map { Color(hex: $0.colorHex) } ?? AppColors.brandAccent
    }

    public var body: some View {
        let yOffset = CGFloat(positionedBlock.startMinutes) * (hourHeight / 60.0)
        let blockHeight = max(24.0, CGFloat(positionedBlock.durationMinutes) * (hourHeight / 60.0))
        let availableWidth = max(20.0, columnWidth - 4.0)
        let subColWidth = availableWidth / CGFloat(max(1, positionedBlock.totalSubColumns))
        let xOffset = 2.0 + CGFloat(positionedBlock.subColumnIndex) * subColWidth
        let width = max(18.0, subColWidth - 2.0)

        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: AppSpacing.xs) {
                Text(positionedBlock.entry.entryDescription.isEmpty ? "(No description)" : positionedBlock.entry.entryDescription)
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(blockHeight > 40 ? 2 : 1)

                Spacer()
            }

            if blockHeight > 36 {
                Text(DateHelper.formatTimeRange(start: positionedBlock.entry.startDate, end: positionedBlock.entry.endDate))
                    .font(.system(size: 10, weight: .regular).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(width: width, height: blockHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusSmall)
                .fill(projectColor.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusSmall)
                .stroke(projectColor, lineWidth: 1.2)
        )
        .shadow(color: isHovered ? Color.black.opacity(0.18) : Color.clear, radius: 4, x: 0, y: 2)
        .position(x: xOffset + width / 2.0, y: yOffset + blockHeight / 2.0)
        .onHover { isHovered = $0 }
        .onTapGesture {
            isPopoverPresented = true
        }
        .popover(isPresented: $isPopoverPresented) {
            popoverInspector()
        }
        .sheet(isPresented: $isEditSheetPresented) {
            EntryEditSheet(mode: .edit(positionedBlock.entry))
        }
    }

    @ViewBuilder
    private func popoverInspector() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header: Project & Task
            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(projectColor)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 1) {
                    Text(project?.name ?? "No Project")
                        .font(AppTypography.subheading)

                    if let task = task {
                        Text(task.name)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(DateHelper.formatHumanDuration(positionedBlock.entry.effectiveDuration))
                    .font(AppTypography.ticker)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 2)
                    .background(projectColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            Divider()

            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text("Description")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                Text(positionedBlock.entry.entryDescription.isEmpty ? "(No description)" : positionedBlock.entry.entryDescription)
                    .font(AppTypography.body)
            }

            // Time range
            VStack(alignment: .leading, spacing: 2) {
                Text("Time Range")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                Text(DateHelper.formatTimeRange(start: positionedBlock.entry.startDate, end: positionedBlock.entry.endDate))
                    .font(AppTypography.caption)
            }

            Divider()

            // Actions: Continue & Edit
            HStack(spacing: AppSpacing.md) {
                Button(action: {
                    timerManager.continueEntry(positionedBlock.entry)
                    isPopoverPresented = false
                }) {
                    Label("Continue", systemImage: "play.fill")
                        .font(AppTypography.label)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.brandAccent)

                Spacer()

                Button(action: {
                    isPopoverPresented = false
                    isEditSheetPresented = true
                }) {
                    Label("Edit Details...", systemImage: "pencil")
                        .font(AppTypography.label)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(AppSpacing.md)
        .frame(width: 280)
    }
}
