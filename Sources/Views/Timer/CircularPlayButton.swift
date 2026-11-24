import SwiftUI

/// Authentic Toggl Track circular play/stop button.
/// 36x36pt circle with vibrant magenta (#E54583) when idle and red (#FF453A) when running.
public struct CircularPlayButton: View {
    public let isRunning: Bool
    public let isPaused: Bool
    public let onToggle: () -> Void
    public let onPauseToggle: (() -> Void)?

    @State private var isHovered: Bool = false

    public init(
        isRunning: Bool,
        isPaused: Bool = false,
        onToggle: @escaping () -> Void,
        onPauseToggle: (() -> Void)? = nil
    ) {
        self.isRunning = isRunning
        self.isPaused = isPaused
        self.onToggle = onToggle
        self.onPauseToggle = onPauseToggle
    }

    public var body: some View {
        HStack(spacing: 8) {
            if isRunning, let onPause = onPauseToggle {
                Button(action: onPause) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 26, height: 26)
                        .background(AppColors.secondaryCardBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(isPaused ? "Resume timer" : "Pause timer")
            }

            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isRunning ? AppColors.destructive : AppColors.togglMagenta)
                        .frame(width: 34, height: 34)
                        .shadow(
                            color: (isRunning ? AppColors.destructive : AppColors.togglMagenta).opacity(isHovered ? 0.45 : 0.25),
                            radius: isHovered ? 6 : 3,
                            y: 2
                        )

                    if isRunning {
                        // Stop square icon
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                    } else {
                        // Play triangle icon (offset slightly right for visual balance)
                        Image(systemName: "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                            .offset(x: 1)
                    }
                }
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
            }
            .help(isRunning ? "Stop timer (Return)" : "Start timer (Return)")
        }
    }
}
