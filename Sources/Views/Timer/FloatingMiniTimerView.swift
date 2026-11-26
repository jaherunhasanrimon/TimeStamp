import SwiftUI
import AppKit

/// Compact always-on-top Floating Mini-Timer Window matching Toggl Track macOS.
public struct FloatingMiniTimerView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    @AppStorage("miniTimerAlwaysOnTop") private var alwaysOnTop: Bool = true
    @State private var draftDescription: String = ""

    public init() {}

    private var activeProject: Project? {
        guard let pid = timerManager.activeEntry?.projectId ?? timerManager.retainedProjectId else { return nil }
        return store.project(for: pid)
    }

    public var body: some View {
        HStack(spacing: 12) {
            if let active = timerManager.activeEntry {
                // Active session info
                VStack(alignment: .leading, spacing: 2) {
                    Text(active.entryDescription.isEmpty ? "(No description)" : active.entryDescription)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let proj = activeProject {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: proj.colorHex))
                                .frame(width: 7, height: 7)
                            Text(proj.name)
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: proj.colorHex))
                                .lineLimit(1)
                        }
                    } else {
                        Text(timerManager.isPaused ? "Paused" : "Running")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(timerManager.compactFormattedDuration)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(timerManager.isPaused ? .secondary : AppColors.togglMagenta)

                Button {
                    if timerManager.isPaused {
                        timerManager.resume()
                    } else {
                        timerManager.pause()
                    }
                } label: {
                    Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.primary)
                        .frame(width: 26, height: 26)
                        .background(AppColors.insetBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(timerManager.isPaused ? "Resume" : "Pause")

                Button {
                    _ = timerManager.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(AppColors.destructive)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Stop timer")
            } else {
                // Idle Quick Start Input
                TextField("Track something quick...", text: $draftDescription)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .onSubmit {
                        startQuick()
                    }
                    .frame(maxWidth: .infinity)

                Text("0:00:00")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)

                Button {
                    startQuick()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(AppColors.togglMagenta)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Start timer")
            }

            // Pin / Always-on-top toggle
            Button {
                alwaysOnTop.toggle()
            } label: {
                Image(systemName: alwaysOnTop ? "pin.fill" : "pin.slash")
                    .font(.system(size: 11))
                    .foregroundStyle(alwaysOnTop ? AppColors.togglMagenta : .secondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help(alwaysOnTop ? "Pinned always on top" : "Pin window on top")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 380, height: 54)
        .background(AppColors.cardBackground)
        .background(WindowLevelConfigurator(isFloating: alwaysOnTop))
    }

    private func startQuick() {
        let trimmed = draftDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        timerManager.start(
            description: trimmed,
            projectId: timerManager.retainedProjectId,
            taskId: timerManager.retainedTaskId,
            tagIds: timerManager.retainedTagIds,
            isBillable: timerManager.retainedIsBillable
        )
        draftDescription = ""
    }
}

private struct WindowLevelConfigurator: NSViewRepresentable {
    let isFloating: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.level = isFloating ? .floating : .normal
            view.window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.level = isFloating ? .floating : .normal
        }
    }
}
