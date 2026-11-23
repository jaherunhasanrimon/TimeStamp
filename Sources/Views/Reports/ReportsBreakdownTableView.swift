import SwiftUI

public struct ReportsBreakdownTableView: View {
    public let items: [BreakdownItem]

    public init(items: [BreakdownItem]) {
        self.items = items
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if items.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Text("No breakdown data available for this range.")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, AppSpacing.lg)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(items) { item in
                        VStack(spacing: 4) {
                            HStack(spacing: AppSpacing.sm) {
                                Circle()
                                    .fill(Color(hex: item.colorHex))
                                    .frame(width: 10, height: 10)

                                Text(item.name)
                                    .font(AppTypography.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)

                                Spacer()

                                Text(DateHelper.formatHumanDuration(item.duration))
                                    .font(AppTypography.ticker)

                                Text("\(Int(round(item.percentage)))%")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 38, alignment: .trailing)
                            }

                            // Subtle percentage fill bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.12))

                                    Capsule()
                                        .fill(Color(hex: item.colorHex))
                                        .frame(width: max(3, geo.size.width * CGFloat(item.percentage / 100.0)))
                                }
                            }
                            .frame(height: 4)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}
