import SwiftUI

public struct DayTimelineGridView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    public let selectedDate: Date
    public let hourHeight: CGFloat = 60.0
    public let gutterWidth: CGFloat = 56.0
    public let totalHeight: CGFloat = 1440.0 // 24 * 60

    public init(selectedDate: Date) {
        self.selectedDate = selectedDate
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    // 1. 24-Hour horizontal lines and hour labels
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
                                    .fill(AppColors.border.opacity(0.6))
                                    .frame(height: 0.5)
                            }
                            .frame(height: hourHeight, alignment: .top)
                            .id("day-hour-\(hour)")
                        }
                    }
                    .frame(height: totalHeight)

                    // 2. Events layer
                    HStack(spacing: 0) {
                        Spacer().frame(width: gutterWidth)

                        GeometryReader { geo in
                            let columnWidth = geo.size.width
                            let blocks = CalendarLayoutHelper.computeBlockLayouts(
                                entries: store.timeEntries,
                                for: selectedDate
                            )

                            ZStack(alignment: .topLeading) {
                                ForEach(blocks) { block in
                                    CalendarBlockView(
                                        positionedBlock: block,
                                        columnWidth: columnWidth,
                                        hourHeight: hourHeight
                                    )
                                }

                                // Live Current-Time Indicator Line (CAL-01, D-04)
                                if Calendar.current.isDateInToday(selectedDate) {
                                    currentTimeIndicator(width: columnWidth)
                                }
                            }
                            .frame(width: columnWidth, height: totalHeight)
                        }
                    }
                    .frame(height: totalHeight)
                }
                .frame(minHeight: totalHeight)
                .padding(.trailing, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
            }
            .onAppear {
                let currentHour = Calendar.current.component(.hour, from: Date())
                let targetHour = Calendar.current.isDateInToday(selectedDate) ? max(0, currentHour - 1) : 8
                proxy.scrollTo("day-hour-\(targetHour)", anchor: .top)
            }
        }
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
            // Horizontal line
            Rectangle()
                .fill(Color.red)
                .frame(width: width, height: 2)

            // Red dot marker
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .offset(x: -4)
        }
        .position(x: width / 2.0, y: yPos)
    }
}
