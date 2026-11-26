import SwiftUI

public struct SettingsView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings")
                        .font(AppTypography.heading)
                        .foregroundStyle(.primary)
                    Text("Preferences, Pomodoro, Idle Detection, Activity Recorder & Local Data")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            Divider()

            TabView {
                GeneralAndAccountSettingsView()
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }

                ScrollView {
                    TimerPreferencesSectionView()
                        .padding(AppSpacing.lg)
                }
                .tabItem {
                    Label("Timer", systemImage: "stopwatch")
                }

                PomodoroSettingsSectionView()
                    .tabItem {
                        Label("Pomodoro", systemImage: "timer")
                    }

                IdleAndRemindersSettingsView()
                    .tabItem {
                        Label("Idle & Reminders", systemImage: "moon.zzz")
                    }

                ActivityAutotrackerSettingsView()
                    .tabItem {
                        Label("Activity", systemImage: "timeline.selection")
                    }

                ScrollView {
                    DataManagementSectionView()
                        .padding(AppSpacing.lg)
                }
                .tabItem {
                    Label("Data", systemImage: "externaldrive")
                }
            }
            .padding(.top, 8)
        }
        .background(AppColors.background)
    }
}
