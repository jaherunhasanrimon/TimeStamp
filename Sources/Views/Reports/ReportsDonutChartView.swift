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
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 16)
                    .frame(width: 180, height: 180)

                VStack(spacing: 2) {
                    Text("0m")
                        .font(AppTypography.displayTicker)
                        .foregroundStyle(.secondary)
                    Text("No tracked time")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Chart(items) { item in
                    SectorMark(
                        angle: .value("Duration", item.duration),
                        innerRadius: .ratio(0.65),
                        angularInset: 1.5
                    )
                    .foregroundStyle(Color(hex: item.colorHex))
                }
                .frame(width: 220, height: 220)

                VStack(spacing: 2) {
                    Text(DateHelper.formatHumanDuration(totalDuration))
                        .font(AppTypography.displayTicker)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Total Time")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 130)
            }
        }
        .frame(width: 220, height: 220)
    }
}
