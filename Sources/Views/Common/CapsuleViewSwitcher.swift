import SwiftUI

public enum TrackerViewMode: String, CaseIterable, Identifiable {
    case list = "List"
    case calendar = "Calendar"

    public var id: String { rawValue }
}

/// Toggl Track macOS pill/capsule switcher for List and Calendar modes (Reference: toggl_macos_main_empty.jpg).
public struct CapsuleViewSwitcher: View {
    @Binding public var selectedMode: TrackerViewMode

    public init(selectedMode: Binding<TrackerViewMode>) {
        self._selectedMode = selectedMode
    }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(TrackerViewMode.allCases) { mode in
                let isSelected = selectedMode == mode
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedMode = mode
                    }
                }) {
                    Text(mode.rawValue)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color.primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? AppColors.capsuleActiveThumb : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(AppColors.capsuleTrack)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.border.opacity(0.6), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppColors.background)
    }
}
