import SwiftUI

/// Toggl Track Day Group Header (Reference Image 5).
/// Displays relative day title (e.g. "Today", "Yesterday", "Mon, 08 Aug")
/// on the left and formatted human duration (e.g. "4 h 15 min") on the right.
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
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.primary)

            Spacer()

            HStack(spacing: 6) {
                Text(DateHelper.formatHumanDuration(totalDuration))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.up")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary.opacity(0.8))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }
}
