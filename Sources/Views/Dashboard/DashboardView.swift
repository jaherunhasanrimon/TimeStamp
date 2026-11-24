import SwiftUI

public struct DashboardView: View {
    @Environment(PersistenceStore.self) private var store

    public init() {}

    public var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Dashboard")
                            .font(AppTypography.heading)
                        Text("Overview of today's progress and weekly time allocation")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                if store.timeEntries.isEmpty {
                    TogglEmptyStateView(
                        style: .binoculars(
                            title: "No Activity Tracked",
                            subtitle: "No activity tracked today. Start a timer or log past time to view productivity metrics."
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl * 2)
                } else {
                    // Top Row: Daily Progress Card & Weekly Bar Chart
                    VStack(spacing: AppSpacing.lg) {
                        HStack(alignment: .top, spacing: AppSpacing.lg) {
                            DailyProgressCardView()
                                .frame(maxWidth: 380)

                            WeeklyActivityChartView()
                                .frame(maxWidth: .infinity)
                        }

                        // Bottom Section: Recent Activity List
                        RecentActivityListView()
                    }
                }
            }
            .padding(AppSpacing.xl)
        }
        .background(AppColors.background)
    }
}
