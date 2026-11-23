import SwiftUI

public struct DetailContainerView: View {
    @Binding public var destination: SidebarDestination?
    @State private var activeEntryFilter: EntryFilter = .none

    public init(destination: Binding<SidebarDestination?>) {
        self._destination = destination
    }

    public init(destination: SidebarDestination?) {
        self._destination = .constant(destination)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Global Sticky Active Timer Bar (D-01)
            ActiveTimerBar()

            Group {
                switch destination {
                case .timer:
                    EntriesListView(filter: $activeEntryFilter)
                case .projects:
                    ProjectsListView(onViewEntries: { filter in
                        activeEntryFilter = filter
                        destination = .timer
                    })
                case .clients:
                    ClientsListView(onViewEntries: { filter in
                        activeEntryFilter = filter
                        destination = .timer
                    })
                case .calendar, .dashboard, .reports, .settings:
                    placeholderView(for: destination!)
                case .none:
                    EntriesListView(filter: $activeEntryFilter)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

            Text("Active Timer Bar & Timer Engine functional above")
                .font(AppTypography.caption)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
        }
        .padding(AppSpacing.xl)
    }
}
