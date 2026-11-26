import SwiftUI
import AppKit

public struct AppSidebar: View {
    @Binding public var selection: SidebarDestination?
    public var onSwitchToCompact: (() -> Void)?

    public init(
        selection: Binding<SidebarDestination?>,
        onSwitchToCompact: (() -> Void)? = nil
    ) {
        self._selection = selection
        self.onSwitchToCompact = onSwitchToCompact
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Workspace Header (Toggl Track Style)
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppColors.togglMagenta)
                        .frame(width: 22, height: 22)

                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                }

                Text("TimeStamp")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()
                .overlay(AppColors.border)

            List(selection: $selection) {
                Section("TRACK") {
                    sidebarRow(for: .timer)
                    sidebarRow(for: .calendar)
                }

                Section("ANALYZE") {
                    sidebarRow(for: .dashboard)
                    sidebarRow(for: .reports)
                }

                Section("MANAGE") {
                    sidebarRow(for: .projects)
                    sidebarRow(for: .clients)
                    sidebarRow(for: .tags)
                }

                Section("ADMIN") {
                    sidebarRow(for: .settings)
                }
            }
            .listStyle(.sidebar)

            if let onCompact = onSwitchToCompact {
                Divider()
                    .overlay(AppColors.border)

                Button(action: onCompact) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.left.and.arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColors.togglMagenta)

                        Text("Compact Tracker")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(minWidth: 200, idealWidth: 220)
        .background(AppColors.cardBackground)
    }

    @ViewBuilder
    private func sidebarRow(for destination: SidebarDestination) -> some View {
        NavigationLink(value: destination) {
            Label(destination.rawValue, systemImage: destination.systemImage)
                .font(.system(size: 13, weight: .regular))
        }
    }
}
