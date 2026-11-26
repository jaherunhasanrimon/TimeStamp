import SwiftUI

public struct DayTimelineGridView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    public let selectedDate: Date
    public var snapMinutes: Int = 15
    public var showAppleCalendarOverlay: Bool = false
    public var appleCalendarEvents: [ExternalCalendarEvent] = []
    public var onSelectEntry: ((TimeEntry) -> Void)?
    public var onCreateAtDate: ((Date) -> Void)?

    private let hourHeight: CGFloat = 60.0
    private let gutterWidth: CGFloat = 58.0

    public init(
        selectedDate: Date,
        snapMinutes: Int = 15,
        showAppleCalendarOverlay: Bool = false,
        appleCalendarEvents: [ExternalCalendarEvent] = [],
        onSelectEntry: ((TimeEntry) -> Void)? = nil,
        onCreateAtDate: ((Date) -> Void)? = nil
    ) {
        self.selectedDate = selectedDate
        self.snapMinutes = snapMinutes
        self.showAppleCalendarOverlay = showAppleCalendarOverlay
        self.appleCalendarEvents = appleCalendarEvents
        self.onSelectEntry = onSelectEntry
        self.onCreateAtDate = onCreateAtDate
    }

    private var blocks: [PositionedBlock] {
        _ = timerManager.currentDuration
        return CalendarLayoutHelper.computeBlockLayouts(
            entries: store.timeEntries,
            for: selectedDate
        )
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // 1. Hour rows & grid
                    VStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            HStack(alignment: .top, spacing: 0) {
                                Text(formatHourLabel(hour))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: gutterWidth, alignment: .trailing)
                                    .padding(.trailing, 8)
                                    .offset(y: -7)

                                ZStack(alignment: .top) {
                                    Rectangle()
                                        .fill(AppColors.border.opacity(0.6))
                                        .frame(height: 0.5)

                                    Rectangle()
                                        .fill(AppColors.border.opacity(0.25))
                                        .frame(height: 0.5)
                                        .offset(y: hourHeight / 2)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .frame(height: hourHeight)
                            .id(hour)
                        }
                    }

                    // 2. Click / Double-click canvas for creating at clicked time
                    GeometryReader { geo in
                        let canvasWidth = max(100, geo.size.width - gutterWidth)

                        // Double-click slot creation surface
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: canvasWidth, height: 24 * hourHeight)
                            .offset(x: gutterWidth)
                            .onTapGesture(count: 2) { location in
                                let snappedDate = CalendarLayoutHelper.snappedStartDate(
                                    atY: location.y,
                                    hourHeight: hourHeight,
                                    dayDate: selectedDate,
                                    snapMinutes: snapMinutes
                                )
                                onCreateAtDate?(snappedDate)
                            }

                        // Optional read-only Apple Calendar overlay
                        if showAppleCalendarOverlay {
                            let dayStart = Calendar.current.startOfDay(for: selectedDate)
                            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                            ForEach(appleCalendarEvents) { ev in
                                let effStart = max(dayStart, ev.startDate)
                                let effEnd = min(dayEnd, max(effStart.addingTimeInterval(300), ev.endDate))
                                let startMin = effStart.timeIntervalSince(dayStart) / 60.0
                                let durMin = effEnd.timeIntervalSince(effStart) / 60.0
                                let y = CGFloat(startMin / 60.0) * hourHeight
                                let h = max(20, CGFloat(durMin / 60.0) * hourHeight)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(ev.title)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    Text(ev.calendarTitle)
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary.opacity(0.75))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .frame(width: max(40, canvasWidth - 16), height: h, alignment: .topLeading)
                                .background(Color(hex: ev.colorHex).opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                        .foregroundStyle(Color(hex: ev.colorHex).opacity(0.45))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .offset(x: gutterWidth + 8, y: y)
                                .allowsHitTesting(false)
                            }
                        }

                        // Positioned time entry blocks
                        ForEach(blocks) { block in
                            let colWidth = (canvasWidth - 16) / CGFloat(block.totalSubColumns)
                            let xOffset = gutterWidth + 8 + CGFloat(block.subColumnIndex) * colWidth
                            let yOffset = CGFloat(block.startMinutes / 60.0) * hourHeight
                            let height = max(24.0, CGFloat(block.durationMinutes / 60.0) * hourHeight)
                            let project = block.entry.projectId.flatMap { store.project(for: $0) }
                            let entry = block.entry

                            CalendarBlockView(
                                entry: entry,
                                project: project,
                                height: height,
                                isCompact: false,
                                onSelect: { onSelectEntry?(entry) },
                                onMoveDeltaY: { deltaY in
                                    moveEntry(entry, deltaY: deltaY)
                                },
                                onResizeEdgeDeltaY: { edge, deltaY in
                                    resizeEntry(entry, edge: edge, deltaY: deltaY)
                                },
                                onContinue: { timerManager.continueEntry(entry) },
                                onDuplicate: { _ = store.duplicateTimeEntry(entry) },
                                onToggleBillable: {
                                    entry.isBillable.toggle()
                                    entry.updatedAt = Date()
                                    store.saveTimeEntry(entry)
                                },
                                onDelete: {
                                    if timerManager.activeEntry?.id == entry.id {
                                        timerManager.discard()
                                    } else {
                                        store.deleteTimeEntry(id: entry.id)
                                    }
                                }
                            )
                            .frame(width: max(20, colWidth - 4), height: height)
                            .offset(x: xOffset, y: yOffset)
                        }

                        // Current Time Indicator Line
                        if Calendar.current.isDateInToday(selectedDate) {
                            currentTimeIndicator(width: canvasWidth)
                                .offset(x: gutterWidth, y: currentTimeYOffset())
                        }
                    }
                }
                .frame(height: 24 * hourHeight)
                .padding(.vertical, 16)
            }
            .onAppear {
                proxy.scrollTo(8, anchor: .top)
            }
        }
        .background(AppColors.background)
    }

    private func moveEntry(_ entry: TimeEntry, deltaY: CGFloat) {
        guard let endDate = entry.endDate else { return }
        let moved = CalendarLayoutHelper.movedDates(
            originalStart: entry.startDate,
            originalEnd: endDate,
            deltaY: deltaY,
            hourHeight: hourHeight,
            snapMinutes: snapMinutes
        )
        entry.startDate = moved.start
        entry.endDate = moved.end
        entry.accumulatedDuration = moved.end.timeIntervalSince(moved.start)
        entry.updatedAt = Date()
        store.saveTimeEntry(entry)
    }

    private func resizeEntry(_ entry: TimeEntry, edge: ResizeEdge, deltaY: CGFloat) {
        guard let endDate = entry.endDate else { return }
        let resized = CalendarLayoutHelper.resizedDates(
            originalStart: entry.startDate,
            originalEnd: endDate,
            edge: edge,
            deltaY: deltaY,
            hourHeight: hourHeight,
            snapMinutes: snapMinutes
        )
        entry.startDate = resized.start
        entry.endDate = resized.end
        entry.accumulatedDuration = resized.end.timeIntervalSince(resized.start)
        entry.updatedAt = Date()
        store.saveTimeEntry(entry)
    }

    private func currentTimeIndicator(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            Circle()
                .fill(AppColors.togglMagenta)
                .frame(width: 8, height: 8)
                .offset(x: -4)

            Rectangle()
                .fill(AppColors.togglMagenta)
                .frame(width: max(0, width - 4), height: 1.5)
        }
    }

    private func currentTimeYOffset() -> CGFloat {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let mins = now.timeIntervalSince(startOfDay) / 60.0
        return CGFloat(mins / 60.0) * hourHeight - 4
    }

    private func formatHourLabel(_ hour: Int) -> String {
        if hour == 0 { return "00:00" }
        return String(format: "%02d:00", hour)
    }
}
