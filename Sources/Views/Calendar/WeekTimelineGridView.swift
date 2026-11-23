import SwiftUI

public struct WeekTimelineGridView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    public let weekStartDate: Date
    public let hourHeight: CGFloat = 60.0
    public let gutterWidth: CGFloat = 56.0
    public let totalHeight: CGFloat = 1440.0 // 24 * 60

    public init(weekStartDate: Date) {
        self.weekStartDate = weekStartDate
    }

    private var weekDays: [Date] {
        let calendar = Calendar.current
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate)
        }
    }

    private func dayTrackedTotal(for date: Date) -> TimeInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }

        return store.timeEntries
            .filter { $0.startDate >= startOfDay && $0.startDate < endOfDay && $0.endDate != nil }
            .reduce(0.0) { $0 + $1.effectiveDuration }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Sticky Top Day Header Row
            HStack(spacing: 0) {
                // Left gutter spacer
                Spacer().frame(width: gutterWidth)

                // 7 Day Headers
                ForEach(weekDays, id: \.self) { day in
                    dayHeaderView(for: day)
                        .frame(maxWidth: .infinity)

                    if day != weekDays.last {
                        Divider()
                            .frame(height: 36)
                    }
                }
            }
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.cardBackground)
            .overlay(
                Rectangle()
                    .fill(AppColors.border)
                    .frame(height: 1),
                alignment: .bottom
            )

            // Synchronized 24-Hour Scrollable Grid
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        // 1. Horizontal hour lines & labels
                        VStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                HStack(alignment: .top, spacing: 0) {
                                    Text(String(format: "%02d:00", hour))
                                        .font(AppTypography.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: gutterWidth, alignment: .trailing)
                                        .padding(.trailing, AppSpacing.sm)
                                        .offset(y: -7)

                                    Rectangle()
                                        .fill(AppColors.border.opacity(0.4))
                                        .frame(height: 0.5)
                                }
                                .frame(height: hourHeight, alignment: .top)
                                .id("week-hour-\(hour)")
                            }
                        }
                        .frame(height: totalHeight)

                        // 2. Multi-column event days layer
                        HStack(spacing: 0) {
                            Spacer().frame(width: gutterWidth)

                            ForEach(weekDays, id: \.self) { day in
                                GeometryReader { geo in
                                    let colWidth = geo.size.width
                                    let blocks = CalendarLayoutHelper.computeBlockLayouts(
                                        entries: store.timeEntries,
                                        for: day
                                    )

                                    ZStack(alignment: .topLeading) {
                                        ForEach(blocks) { block in
                                            CalendarBlockView(
                                                positionedBlock: block,
                                                columnWidth: colWidth,
                                                hourHeight: hourHeight
                                            )
                                        }

                                        // Current-time marker on today's column (D-04)
                                        if Calendar.current.isDateInToday(day) {
                                            currentTimeIndicator(width: colWidth)
                                        }
                                    }
                                    .frame(width: colWidth, height: totalHeight)
                                }
                                .frame(maxWidth: .infinity)

                                if day != weekDays.last {
                                    Rectangle()
                                        .fill(AppColors.border.opacity(0.3))
                                        .frame(width: 0.5)
                                }
                            }
                        }
                        .frame(height: totalHeight)
                    }
                    .frame(minHeight: totalHeight)
                    .padding(.trailing, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                }
                .onAppear {
                    let currentHour = Calendar.current.component(.hour, from: Date())
                    let targetHour = max(0, currentHour - 1)
                    proxy.scrollTo("week-hour-\(targetHour)", anchor: .top)
                }
            }
        }
    }

    @ViewBuilder
    private func dayHeaderView(for day: Date) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(day)
        let dayName = dayFormatter.string(from: day)
        let dayNumber = calendar.component(.day, from: day)
        let totalTime = dayTrackedTotal(for: day)

        VStack(spacing: 2) {
            Text(dayName.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isToday ? AppColors.brandAccent : .secondary)

            ZStack {
                if isToday {
                    Circle()
                        .fill(AppColors.brandAccent)
                        .frame(width: 24, height: 24)
                }

                Text("\(dayNumber)")
                    .font(AppTypography.label)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isToday ? .white : .primary)
            }
            .frame(width: 24, height: 24)

            Text(totalTime > 0 ? DateHelper.formatHumanDuration(totalTime) : "—")
                .font(.system(size: 10, weight: .regular).monospacedDigit())
                .foregroundStyle(totalTime > 0 ? Color.primary : Color.secondary.opacity(0.6))
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func currentTimeIndicator(width: CGFloat) -> some View {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = Double(hour * 60 + minute)
        let yPos = currentMinutes * (hourHeight / 60.0)

        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.red)
                .frame(width: width, height: 2)

            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .offset(x: -4)
        }
        .position(x: width / 2.0, y: yPos)
    }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }
}
