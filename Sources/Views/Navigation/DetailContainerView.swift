import SwiftUI

public struct DetailContainerView: View {
    public let destination: SidebarDestination?

    public init(destination: SidebarDestination?) {
        self.destination = destination
    }

    public var body: some View {
        Group {
            switch destination {
            case .projects:
                SkeletonRootView()
            case .timer, .calendar, .dashboard, .reports, .clients, .settings:
                placeholderView(for: destination!)
            case .none:
                Text("Select an item from the sidebar")
                    .font(AppTypography.subheading)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    @ViewBuilder
    private func placeholderView(for item: SidebarDestination) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: item.systemImage)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppColors.brandAccent)

            Text(item.rawValue)
                .font(AppTypography.heading)

            Text("This feature is scheduled in upcoming phases of development.")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)

            Text("Walking Skeleton active in Projects tab")
                .font(AppTypography.caption)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
        }
        .padding(AppSpacing.xl)
    }
}
