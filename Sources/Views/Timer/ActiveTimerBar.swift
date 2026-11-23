import SwiftUI

public struct ActiveTimerBar: View {
    @Environment(TimerManager.self) private var timerManager
    @Environment(PersistenceStore.self) private var store

    @State private var descriptionText: String = ""
    @State private var selectedProjectId: UUID?
    @State private var selectedTaskId: UUID?

    public init() {}

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Description Field (D-03, D-05)
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                TextField("What are you working on?", text: $descriptionText)
                    .textFieldStyle(.plain)
                    .font(AppTypography.body)
                    .onSubmit {
                        handleReturnKey()
                    }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 6)
            .background(AppColors.secondaryCardBackground.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))

            // Project / Task Selector (D-04)
            ProjectTaskPickerButton(
                selectedProjectId: $selectedProjectId,
                selectedTaskId: $selectedTaskId
            )

            Spacer()

            // Live Monospaced Duration Ticker (D-07, D-15)
            Text(timerManager.formattedDuration)
                .font(AppTypography.ticker)
                .foregroundStyle(timerManager.isRunning ? .primary : .secondary)
                .padding(.horizontal, AppSpacing.xs)

            // Timer Controls (D-02, D-08)
            HStack(spacing: AppSpacing.sm) {
                if timerManager.activeEntry != nil {
                    // Pause / Resume Button
                    Button(action: togglePause) {
                        Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .background(AppColors.secondaryCardBackground)
                    .clipShape(Circle())
                    .help(timerManager.isPaused ? "Resume timer" : "Pause timer")

                    // Stop Button
                    Button(action: stopTimer) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .background(Color(hex: "#FF375F"))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusButton))
                    .help("Stop & save entry (Return)")

                    // Discard Button (D-08)
                    Button(action: discardTimer) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .help("Discard timer without saving")
                } else {
                    // Start Button
                    Button(action: startTimer) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                            Text("Start")
                                .font(AppTypography.label)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .frame(height: 32)
                    }
                    .buttonStyle(.plain)
                    .background(AppColors.brandAccent)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusButton))
                    .help("Start timer (Return)")
                }
            }
        }
        .frame(height: 56)
        .padding(.horizontal, AppSpacing.md)
        .background(AppColors.cardBackground)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .onAppear {
            syncFromManager()
        }
        .onChange(of: timerManager.activeEntry) { _, newEntry in
            if let entry = newEntry {
                descriptionText = entry.entryDescription
                selectedProjectId = entry.projectId
                selectedTaskId = entry.taskId
            } else {
                descriptionText = ""
                selectedProjectId = timerManager.retainedProjectId
                selectedTaskId = timerManager.retainedTaskId
            }
        }
    }

    private func syncFromManager() {
        if let entry = timerManager.activeEntry {
            descriptionText = entry.entryDescription
            selectedProjectId = entry.projectId
            selectedTaskId = entry.taskId
        } else {
            selectedProjectId = timerManager.retainedProjectId
            selectedTaskId = timerManager.retainedTaskId
        }
    }

    private func handleReturnKey() {
        if timerManager.isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        timerManager.start(
            description: descriptionText,
            projectId: selectedProjectId,
            taskId: selectedTaskId
        )
    }

    private func stopTimer() {
        _ = timerManager.stop()
        descriptionText = ""
        selectedProjectId = timerManager.retainedProjectId
        selectedTaskId = timerManager.retainedTaskId
    }

    private func togglePause() {
        if timerManager.isPaused {
            timerManager.resume()
        } else {
            timerManager.pause()
        }
    }

    private func discardTimer() {
        timerManager.discard()
        descriptionText = ""
        selectedProjectId = timerManager.retainedProjectId
        selectedTaskId = timerManager.retainedTaskId
    }
}
