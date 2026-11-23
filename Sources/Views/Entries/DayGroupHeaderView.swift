import SwiftUI

public struct DayGroupHeaderView: View {
    public let date: Date
    public let totalDuration: TimeInterval

    public init(date: Date, totalDuration: TimeInterval) {
        self.date = date
        self.totalDuration = totalDuration
    }

    public var body: some View {
        HStack {
            Text(DateHelper.formatRelativeDay(date))
                .font(AppTypography.heading)
                .foregroundStyle(.primary)

            Spacer()

            Text(DateHelper.formatHumanDuration(totalDuration))
                .font(AppTypography.subheading)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
    }
}
