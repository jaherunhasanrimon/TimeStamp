import SwiftUI

public struct TimerPreferencesSectionView: View {
    @Environment(PersistenceStore.self) private var store

    @AppStorage("defaultProjectId") private var defaultProjectIdString: String = ""
    @AppStorage("menuBarDisplayFormat") private var menuBarDisplayFormat: String = "icon_and_duration"
    @AppStorage("playTimerSounds") private var playTimerSounds: Bool = true

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Timer & Menu Bar")
                    .font(AppTypography.heading)
                Text("Configure default tracking behavior and system integrations.")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: AppSpacing.md) {
                // Default Project Selection
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Default Project")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                        Text("Automatically assign this project to newly started timers.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $defaultProjectIdString) {
                        Text("None (Select on start)").tag("")
                        ForEach(store.projects) { project in
                            Text(project.name).tag(project.id.uuidString)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }

                Divider()

                // Menu Bar Format
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Menu Bar Display")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                        Text("Choose what information appears in your macOS menu bar.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $menuBarDisplayFormat) {
                        Text("Icon & Duration").tag("icon_and_duration")
                        Text("Duration Only").tag("duration_only")
                        Text("Icon Only").tag("icon_only")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                }

                Divider()

                // Sound Effects Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Play Timer Sounds")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                        Text("Play a subtle audio confirmation when starting or stopping a timer.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $playTimerSounds)
                        .labelsHidden()
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                .stroke(AppColors.border, lineWidth: 0.5)
        )
    }
}
