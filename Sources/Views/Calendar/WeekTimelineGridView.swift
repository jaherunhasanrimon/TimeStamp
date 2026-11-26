import SwiftUI

public struct WeekTimelineGridView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    public let weekStartDate: Date
    public var snapMinutes: Int = 15
    public var showAppleCalendarOverlay: Bool = false
    public var appleCalendarEvents: [ExternalCalendarEvent] = []
    public var onSelectEntry: ((TimeEntry) -> Void)?
    public var onCreateAtDate: ((Date) -> Void)?

    private let hourHeight: CGFloat = 52.0
    private let gutterWidth: CGFloat = 52.0

    public init(
        weekStartDate: Date,
        snapMinutes: Int = 15,
        showAppleCalendarOverlay: Bool = false,
        appleCalendarEvents: [ExternalCalendarEvent] = [],
        onSelectEntry: ((TimeEntry) -> Void)? = nil,
        onCreateAtDate: ((Date) -> Void)? = nil
    ) {
        self.weekStartDate = weekStartDate
        self.snapMinutes = snapMinutes
        self.showAppleCalendarOverlay = showAppleCalendarOverlay
        self.appleCalendarEvents = appleCalendarEvents
        self.onSelectEntry = onSelectEntry
        self.onCreateAtDate = onCreateAtDate
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStartDate) }
    }

    public var body: some View {
        let _ = timerManager.currentDuration

        VStack(spacing: 0) {
            // Sticky Weekday Column Headers
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: gutterWidth, height: 1)

                ForEach(weekDays, id: \.self) { day in
                    let isToday = Calendar.current.isDateInToday(day)
                    let total = dayTotalDuration(for: day)

                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Text(dayNameString(day))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(isToday ? AppColors.togglMagenta : .secondary)

                            Text(dayNumberString(day))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(isToday ? .white : .primary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(isToday ? AppColors.togglMagenta : Color.clear)
                                .clipShape(Capsule())
                        }

                        Text(total > 0 ? DateHelper.formatHumanDuration(total) : "–")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isToday ? AppColors.togglMagenta.opacity(0.05) : Color.clear)
                }
            }
            .background(AppColors.cardBackground)

            Divider()

            // Scrollable 7-Day Hourly Matrix
            ScrollViewReader { proxy in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        // Hour horizontal rows
                        VStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                HStack(alignment: .top, spacing: 0) {
                                    Text(String(format: "%02d:00", hour))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .frame(width: gutterWidth, alignment: .trailing)
                                        .padding(.trailing, 6)
                                        .offset(y: -6)

                                    Rectangle()
                                        .fill(AppColors.border.opacity(0.45))
                                        .frame(height: 0.5)
                                }
                                .frame(height: hourHeight)
                                .id(hour)
                            }
                        }

                        // Vertical Day Columns + Blocks
                        GeometryReader { geo in
                            let columnsWidth = max(100, geo.size.width - gutterWidth)
                            let colWidth = columnsWidth / 7.0

                            ForEach(0..<7, id: \.self) { dayIndex in
                                let day = weekDays[dayIndex]
                                let xBase = gutterWidth + CGFloat(dayIndex) * colWidth

                                // Column Separator
                                Rectangle()
                                    .fill(AppColors.border.opacity(0.35))
                                    .frame(width: 0.5, height: 24 * hourHeight)
                                    .offset(x: xBase)

                                // Double-click column surface to create entry on this day & hour
                                Color.clear
                                    .contentShape(Rectangle())
                                    .frame(width: colWidth, height: 24 * hourHeight)
                                    .offset(x: xBase)
                                    .onTapGesture(count: 2) { location in
                                        let snappedDate = CalendarLayoutHelper.snappedStartDate(
                                            atY: location.y,
                                            hourHeight: hourHeight,
                                            dayDate: day,
                                            snapMinutes: snapMinutes
                                        )
                                        onCreateAtDate?(snappedDate)
                                    }

                                // Optional read-only Apple Calendar events for this weekday
                                if showAppleCalendarOverlay {
                                    let dayStart = Calendar.current.startOfDay(for: day)
                                    let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                                    let dayEvents = appleCalendarEvents.filter { $0.endDate > dayStart && $0.startDate < dayEnd }
                                    ForEach(dayEvents) { ev in
                                        let effStart = max(dayStart, ev.startDate)
                                        let effEnd = min(dayEnd, max(effStart.addingTimeInterval(300), ev.endDate))
                                        let startMin = effStart.timeIntervalSince(dayStart) / 60.0
                                        let durMin = effEnd.timeIntervalSince(effStart) / 60.0
                                        let y = CGFloat(startMin / 60.0) * hourHeight
                                        let h = max(18, CGFloat(durMin / 60.0) * hourHeight)

                                        Text(ev.title)
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .frame(width: max(20, colWidth - 4), height: h, alignment: .topLeading)
                                            .background(Color(hex: ev.colorHex).opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                                                    .foregroundStyle(Color(hex: ev.colorHex).opacity(0.45))
                                            )
                                            .offset(x: xBase + 2, y: y)
                                            .allowsHitTesting(false)
                                    }
                                }

                                // Day's positioned blocks
                                let blocks = CalendarLayoutHelper.computeBlockLayouts(
                                    entries: store.timeEntries,
                                    for: day
                                )

                                ForEach(blocks) { block in
                                    let subWidth = (colWidth - 4) / CGFloat(block.totalSubColumns)
                                    let bx = xBase + 2 + CGFloat(block.subColumnIndex) * subWidth
                                    let by = CGFloat(block.startMinutes / 60.0) * hourHeight
                                    let bh = max(22.0, CGFloat(block.durationMinutes / 60.0) * hourHeight)
                                    let project = block.entry.projectId.flatMap { store.project(for: $0) }
                                    let entry = block.entry

                                    CalendarBlockView(
                                        entry: entry,
                                        project: project,
                                        height: bh,
                                        isCompact: true,
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
                                    .frame(width: max(12, subWidth - 2), height: bh)
                                    .offset(x: bx, y: by)
                                }

                                // Current Time Indicator for Today
                                if Calendar.current.isDateInToday(day) {
                                    currentTimeIndicator(width: colWidth)
                                        .offset(x: xBase, y: currentTimeYOffset())
                                }
                            }
                        }
                    }
                    .frame(height: 24 * hourHeight)
                    .padding(.vertical, 12)
                }
                .onAppear {
                    proxy.scrollTo(8, anchor: .top)
                }
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
                .frame(width: 7, height: 7)
                .offset(x: -3.5)

            Rectangle()
                .fill(AppColors.togglMagenta)
                .frame(width: max(0, width - 3.5), height: 1.5)
        }
    }

    private func currentTimeYOffset() -> CGFloat {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let mins = now.timeIntervalSince(startOfDay) / 60.0
        return CGFloat(mins / 60.0) * hourHeight - 3.5
    }

    private func dayTotalDuration(for day: Date) -> TimeInterval {
        let start = Calendar.current.startOfDay(for: day)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return 0 }
        return store.timeEntries
            .filter { $0.startDate >= start && $0.startDate < end && $0.endDate != nil }
            .reduce(0) { $0 + $1.effectiveDuration }
    }

    private func dayNameString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df.string(from: date).uppercased()
    }

    private func dayNumberString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "d"
        return df.string(from: date)
    }
}
