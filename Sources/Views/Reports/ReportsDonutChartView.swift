import SwiftUI
import Charts

public struct BreakdownItem: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let colorHex: String
    public let duration: TimeInterval
    public let percentage: Double

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        duration: TimeInterval,
        percentage: Double
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.duration = duration
        self.percentage = percentage
    }
}

public struct ReportsDonutChartView: View {
    public let items: [BreakdownItem]
    public let totalDuration: TimeInterval

    public init(items: [BreakdownItem], totalDuration: TimeInterval) {
        self.items = items
        self.totalDuration = totalDuration
    }

    public var body: some View {
        ZStack {
            if items.isEmpty {
                TogglEmptyStateView(
                    style: .binoculars(
                        title: "Nothing to see here...",
                        subtitle: "We couldn't find any time entries for this period."
                    )
                )
                .frame(height: 220)
            } else {
                Chart(items) { item in
                    SectorMark(
                        angle: .value("Duration", item.duration),
                        innerRadius: .ratio(0.68),
                        angularInset: 2.0
                    )
                    .foregroundStyle(Color(hex: item.colorHex))
                }
                .frame(width: 220, height: 220)

                VStack(spacing: 2) {
                    Text(TimeCalculator.formatDuration(totalDuration))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("PROJECT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
