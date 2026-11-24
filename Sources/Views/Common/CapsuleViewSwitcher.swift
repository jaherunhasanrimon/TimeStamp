import SwiftUI

public enum TrackerViewMode: String, CaseIterable, Identifiable {
    case list = "List"
    case calendar = "Calendar"

    public var id: String { rawValue }
}

/// Toggl Track segmented capsule switcher for List and Calendar modes.
public struct CapsuleViewSwitcher: View {
    @Binding public var selectedMode: TrackerViewMode

    public init(selectedMode: Binding<TrackerViewMode>) {
        self._selectedMode = selectedMode
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(TrackerViewMode.allCases) { mode in
                let isSelected = selectedMode == mode
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedMode = mode
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Color.primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)

                        // Underline indicator in Toggl Magenta (#E54583)
                        Rectangle()
                            .fill(isSelected ? AppColors.togglMagenta : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(AppColors.cardBackground)
    }
}
