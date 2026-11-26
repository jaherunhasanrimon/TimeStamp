import SwiftUI

/// Prompt presented when keyboard/mouse inactivity exceeds threshold while timer is running.
public struct IdleResolutionSheet: View {
    @Environment(IdleDetectionManager.self) private var idleManager

    @State private var idleEntryDescription: String = "Away / Meeting"

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: 10) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text("You were inactive for \(DateHelper.formatHumanDuration(idleManager.detectedIdleSeconds))")
                        .font(AppTypography.heading)
                    Text("Active timer: “\(idleManager.affectedEntryDescription)”")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Button {
                    idleManager.discardIdleTimeAndContinue()
                } label: {
                    actionRow(
                        title: "Discard idle time & continue",
                        subtitle: "Stop before the idle break and immediately start a fresh session.",
                        icon: "arrow.trianglehead.clockwise",
                        color: AppColors.togglMagenta
                    )
                }
                .buttonStyle(.plain)

                Button {
                    idleManager.discardIdleTime()
                } label: {
                    actionRow(
                        title: "Discard idle time",
                        subtitle: "End the timer at the moment you became inactive.",
                        icon: "scissors",
                        color: AppColors.destructive
                    )
                }
                .buttonStyle(.plain)

                Button {
                    idleManager.keepIdleTime()
                } label: {
                    actionRow(
                        title: "Keep idle time",
                        subtitle: "Include the inactive duration in your current entry.",
                        icon: "checkmark.circle",
                        color: AppColors.billable
                    )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("Idle block label", text: $idleEntryDescription)
                            .textFieldStyle(.roundedBorder)
                            .font(AppTypography.caption)

                        Button("Add as new entry") {
                            idleManager.addIdleTimeAsNewEntry(
                                idleDescription: idleEntryDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Away" : idleEntryDescription
                            )
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("End previous task at idle start, log idle time separately, and resume tracking.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(AppColors.insetBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(AppSpacing.lg)
        .frame(width: 440)
        .background(AppColors.background)
    }

    @ViewBuilder
    private func actionRow(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.label)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}
