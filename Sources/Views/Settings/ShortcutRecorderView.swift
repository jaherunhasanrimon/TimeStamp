import SwiftUI
import Carbon

public struct ShortcutPreset: Identifiable {
    public let id = UUID()
    public let label: String
    public let keyCode: UInt32
    public let modifiers: UInt32
}

public struct ShortcutRecorderView: View {
    @State private var currentDisplay: String = GlobalHotkeyManager.shared.displayString

    private let presets: [ShortcutPreset] = [
        ShortcutPreset(label: "⌥⇧T", keyCode: 17, modifiers: UInt32(optionKey | shiftKey)),
        ShortcutPreset(label: "⌃⌥T", keyCode: 17, modifiers: UInt32(controlKey | optionKey)),
        ShortcutPreset(label: "⌘⇧T", keyCode: 17, modifiers: UInt32(cmdKey | shiftKey))
    ]

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Keyboard Shortcuts")
                    .font(AppTypography.heading)
                Text("Control the timer from any application across macOS.")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Global Timer Toggle")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                        Text("Starts, pauses, or stops the active timer in the background.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Active shortcut badge
                    Text(currentDisplay)
                        .font(AppTypography.ticker)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.brandAccent.opacity(0.12))
                        .foregroundStyle(AppColors.brandAccent)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusSmall)
                                .stroke(AppColors.brandAccent.opacity(0.3), lineWidth: 1)
                        )
                }

                Divider()

                // Quick Presets
                HStack(spacing: AppSpacing.sm) {
                    Text("Quick Presets:")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)

                    ForEach(presets) { preset in
                        let isSelected = currentDisplay == preset.label

                        Button(action: {
                            applyPreset(preset)
                        }) {
                            Text(preset.label)
                                .font(AppTypography.caption)
                                .fontWeight(isSelected ? .bold : .regular)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, 4)
                                .background(isSelected ? AppColors.brandAccent : Color.secondary.opacity(0.12))
                                .foregroundStyle(isSelected ? Color.white : Color.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
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

    private func applyPreset(_ preset: ShortcutPreset) {
        GlobalHotkeyManager.shared.updateHotkey(
            keyCode: preset.keyCode,
            modifiers: preset.modifiers,
            display: preset.label
        )
        currentDisplay = preset.label
    }
}
