import SwiftUI
import AppKit

public struct MenuBarPopoverView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    @State private var draftDescription: String = ""
    @State private var selectedProjectId: UUID? = nil
    @State private var selectedTaskId: UUID? = nil

    public init() {}

    private var currentDurationText: String {
        if timerManager.activeEntry != nil {
            return timerManager.formattedDuration
        } else {
            return "00:00:00"
        }
    }

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Header Bar
            HStack(alignment: .center) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "stopwatch.fill")
                        .foregroundStyle(AppColors.brandAccent)
                        .font(.system(size: 14))

                    Text("TimeStamp")
                        .font(AppTypography.subheading)
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Large Monospaced Ticker (D-04, D-06)
                Text(currentDurationText)
                    .font(Font.system(size: 20, weight: .bold, design: .default).monospacedDigit())
                    .foregroundStyle(timerManager.isPaused ? Color.orange : (timerManager.isRunning ? .primary : .secondary))
            }

            Divider()

            // Quick Entry Input & Project Picker
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if timerManager.isRunning || timerManager.isPaused {
                    // Running entry details
                    HStack(spacing: AppSpacing.xs) {
                        Text(timerManager.activeEntry?.entryDescription.isEmpty == false
                             ? timerManager.activeEntry!.entryDescription
                             : "(No description)")
                            .font(AppTypography.body)
                            .foregroundStyle(timerManager.activeEntry?.entryDescription.isEmpty == false ? .primary : .secondary)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))

                    // Project / Task display
                    if let projectId = timerManager.activeEntry?.projectId,
                       let project = store.projects.first(where: { $0.id == projectId }) {
                        HStack(spacing: AppSpacing.xs) {
                            Circle()
                                .fill(Color(hex: project.colorHex))
                                .frame(width: 8, height: 8)

                            Text(project.name)
                                .font(AppTypography.caption)
                                .foregroundStyle(.primary)

                            if let taskId = timerManager.activeEntry?.taskId,
                               let task = store.tasks.first(where: { $0.id == taskId }) {
                                Text("•")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                                Text(task.name)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                } else {
                    // Idle input
                    TextField("What are you working on?", text: $draftDescription)
                        .textFieldStyle(.roundedBorder)
                        .font(AppTypography.body)
                        .onSubmit {
                            startTimer()
                        }

                    HStack {
                        ProjectTaskPickerButton(
                            selectedProjectId: $selectedProjectId,
                            selectedTaskId: $selectedTaskId
                        )
                        Spacer()
                    }
                }
            }

            // Controls Bar
            HStack(spacing: AppSpacing.sm) {
                if timerManager.isRunning {
                    Button {
                        _ = timerManager.stop()
                        draftDescription = ""
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.destructive)

                    Button {
                        timerManager.pause()
                    } label: {
                        Image(systemName: "pause.fill")
                            .frame(width: 32)
                    }
                    .buttonStyle(.bordered)
                    .help("Pause timer")

                    Button {
                        timerManager.discard()
                        draftDescription = ""
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                            .frame(width: 28)
                    }
                    .buttonStyle(.plain)
                    .help("Discard active session")
                } else if timerManager.isPaused {
                    Button {
                        timerManager.resume()
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.brandAccent)

                    Button {
                        _ = timerManager.stop()
                        draftDescription = ""
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.destructive)

                    Button {
                        timerManager.discard()
                        draftDescription = ""
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                            .frame(width: 28)
                    }
                    .buttonStyle(.plain)
                    .help("Discard session")
                } else {
                    Button {
                        startTimer()
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "play.fill")
                            Text("Start")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.brandAccent)
                    .keyboardShortcut(.defaultAction)
                }
            }

            Divider()

            // Footer Section
            HStack {
                Button("Open TimeStamp") {
                    openMainWindow()
                }
                .buttonStyle(.plain)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.brandAccent)

                Spacer()

                Text("⌥⇧T")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .help("Global toggle shortcut")

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(AppSpacing.md)
        .frame(width: 320)
        .background(AppColors.background)
        .onAppear {
            if let retainedP = timerManager.retainedProjectId {
                selectedProjectId = retainedP
            }
            if let retainedT = timerManager.retainedTaskId {
                selectedTaskId = retainedT
            }
        }
    }

    private func startTimer() {
        let trimmed = draftDescription.trimmingCharacters(in: .whitespaces)
        timerManager.start(
            description: trimmed,
            projectId: selectedProjectId,
            taskId: selectedTaskId
        )
    }

    private func openMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { $0.title == "TimeStamp" || $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
            window.deminiaturize(nil)
        }
    }
}
