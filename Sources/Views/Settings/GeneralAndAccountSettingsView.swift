import SwiftUI

public struct GeneralAndAccountSettingsView: View {
    @Environment(SystemIntegrationManager.self) private var systemManager
    @Environment(PersistenceStore.self) private var store

    @AppStorage("menuBarShowProject") private var menuBarShowProject: Bool = true
    @AppStorage("calendarSnapMinutes") private var calendarSnapMinutes: Int = 15

    public init() {}

    public var body: some View {
        @Bindable var bindSys = systemManager

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ThemePickerView()

                // System & Menu Bar Card
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Label("macOS System & Windowing", systemImage: "macwindow")
                        .font(AppTypography.subheading)

                    Toggle("Show TimeStamp icon in the macOS Dock", isOn: $bindSys.showDockIcon)

                    HStack {
                        Toggle("Open TimeStamp automatically at login", isOn: Binding(
                            get: { systemManager.launchAtLoginEnabled },
                            set: { systemManager.setLaunchAtLogin($0) }
                        ))
                        Spacer()
                        Text(systemManager.launchAtLoginStatusText)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Show active project / task beside menu bar timer", isOn: $menuBarShowProject)

                    Picker("Calendar drag/click snap interval", selection: $calendarSnapMinutes) {
                        Text("1 minute").tag(1)
                        Text("5 minutes").tag(5)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                    }
                    .frame(width: 280)
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))

                ShortcutRecorderView()

                // Local Profile & Sync Readiness Notice
                VStack(alignment: .leading, spacing: 8) {
                    Label("Workspace & Future CloudKit Readiness", systemImage: "icloud.slash")
                        .font(AppTypography.subheading)

                    Text("Mode: Local Offline macOS Storage (\(store.timeEntries.count) entries, \(store.projects.count) projects, \(store.goals.count) goals)")
                        .font(AppTypography.body)

                    Text("Cloud sync & remote Toggl accounts require external OAuth / CloudKit team entitlements and are intentionally not simulated offline. All domain models remain clean Codable structures ready for CloudKit or backend synchronization.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
            }
            .padding(AppSpacing.lg)
        }
    }
}
