import SwiftUI

public struct CalendarBlockView: View {
    public let entry: TimeEntry
    public let project: Project?
    public let height: CGFloat
    public let isCompact: Bool
    public let onSelect: () -> Void
    public var onMoveDeltaY: ((CGFloat) -> Void)? = nil
    public var onResizeEdgeDeltaY: ((ResizeEdge, CGFloat) -> Void)? = nil
    public var onContinue: (() -> Void)? = nil
    public var onDuplicate: (() -> Void)? = nil
    public var onToggleBillable: (() -> Void)? = nil
    public var onDelete: (() -> Void)? = nil

    @State private var isHovered: Bool = false
    @State private var dragMoveOffsetY: CGFloat = 0
    @State private var dragTopDeltaY: CGFloat = 0
    @State private var dragBottomDeltaY: CGFloat = 0

    public init(
        entry: TimeEntry,
        project: Project?,
        height: CGFloat,
        isCompact: Bool = false,
        onSelect: @escaping () -> Void,
        onMoveDeltaY: ((CGFloat) -> Void)? = nil,
        onResizeEdgeDeltaY: ((ResizeEdge, CGFloat) -> Void)? = nil,
        onContinue: (() -> Void)? = nil,
        onDuplicate: (() -> Void)? = nil,
        onToggleBillable: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.entry = entry
        self.project = project
        self.height = height
        self.isCompact = isCompact
        self.onSelect = onSelect
        self.onMoveDeltaY = onMoveDeltaY
        self.onResizeEdgeDeltaY = onResizeEdgeDeltaY
        self.onContinue = onContinue
        self.onDuplicate = onDuplicate
        self.onToggleBillable = onToggleBillable
        self.onDelete = onDelete
    }

    private var accentColor: Color {
        if let hex = project?.colorHex {
            return Color(hex: hex)
        }
        return AppColors.brandAccent
    }

    private var isLiveRunning: Bool {
        entry.endDate == nil
    }

    private var renderedHeight: CGFloat {
        max(22, height + dragBottomDeltaY - dragTopDeltaY)
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if isLiveRunning {
                        Circle()
                            .fill(AppColors.togglMagenta)
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 6, height: 6)
                    }

                    Text(entry.entryDescription.isEmpty ? "(No description)" : entry.entryDescription)
                        .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 2)

                    if entry.isBillable {
                        Text("$")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppColors.billable)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(AppColors.billable.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }

                    if height >= 28 && !isCompact {
                        Text(TimeCalculator.formatCompactDuration(entry.effectiveDuration))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                if renderedHeight >= 40 {
                    HStack(spacing: 4) {
                        if let project {
                            Text(project.name)
                                .font(.system(size: isCompact ? 9 : 11))
                                .foregroundStyle(accentColor)
                                .lineLimit(1)
                        }

                        if !isCompact {
                            Text("· \(DateHelper.formatTimeRange(start: entry.startDate, end: entry.endDate))")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.horizontal, isCompact ? 5 : 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Top resize handle
            if !isLiveRunning && onResizeEdgeDeltaY != nil && renderedHeight >= 26 {
                Rectangle()
                    .fill(isHovered ? accentColor.opacity(0.6) : Color.clear)
                    .frame(height: 5)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { value in
                                dragTopDeltaY = value.translation.height
                            }
                            .onEnded { value in
                                onResizeEdgeDeltaY?(.top, value.translation.height)
                                dragTopDeltaY = 0
                            }
                    )
            }

            // Bottom resize handle
            if !isLiveRunning && onResizeEdgeDeltaY != nil {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(isHovered ? accentColor.opacity(0.6) : Color.clear)
                        .frame(height: 6)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 2)
                                .onChanged { value in
                                    dragBottomDeltaY = value.translation.height
                                }
                                .onEnded { value in
                                    onResizeEdgeDeltaY?(.bottom, value.translation.height)
                                    dragBottomDeltaY = 0
                                }
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: renderedHeight)
        .background(accentColor.opacity(isHovered ? 0.25 : 0.16))
        .overlay(
            HStack(spacing: 0) {
                Rectangle()
                    .fill(isLiveRunning ? AppColors.togglMagenta : accentColor)
                    .frame(width: 4)
                Spacer()
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isHovered || isLiveRunning ? accentColor.opacity(0.75) : accentColor.opacity(0.32), lineWidth: 1)
        )
        .offset(y: dragMoveOffsetY + dragTopDeltaY)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onSelect()
        }
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    guard !isLiveRunning, onMoveDeltaY != nil else { return }
                    dragMoveOffsetY = value.translation.height
                }
                .onEnded { value in
                    guard !isLiveRunning, let onMove = onMoveDeltaY else {
                        dragMoveOffsetY = 0
                        return
                    }
                    onMove(value.translation.height)
                    dragMoveOffsetY = 0
                }
        )
        .contextMenu {
            if let onContinue {
                Button {
                    onContinue()
                } label: {
                    Label("Continue Tracking", systemImage: "play.fill")
                }
            }

            if let onDuplicate {
                Button {
                    onDuplicate()
                } label: {
                    Label("Duplicate Entry", systemImage: "plus.square.on.square")
                }
            }

            Button {
                onSelect()
            } label: {
                Label("Edit Details...", systemImage: "pencil")
            }

            if let onToggleBillable {
                Button {
                    onToggleBillable()
                } label: {
                    Label(entry.isBillable ? "Mark Non-billable" : "Mark Billable ($)", systemImage: "dollarsign.circle")
                }
            }

            if let onDelete {
                Divider()
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Entry", systemImage: "trash")
                }
            }
        }
    }
}
