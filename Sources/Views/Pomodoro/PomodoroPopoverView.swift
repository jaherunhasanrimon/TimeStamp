import SwiftUI

/// Authentic Toggl Track Pomodoro UI matching `toggl_macos_pomodoro_window.jpg`.
/// Used both inside the toolbar Tomato Popover and as a standalone floating Pomodoro Window.
public struct PomodoroPopoverView: View {
    @Environment(PomodoroManager.self) private var pomodoro
    @Environment(PersistenceStore.self) private var store
    @Environment(\.openWindow) private var openWindow

    public let onDismiss: () -> Void
    public let isStandaloneWindow: Bool

    @State private var isDetailsPresented: Bool = false
    @State private var isSettingsExpanded: Bool = false
    @State private var isProjectPickerPresented: Bool = false
    @State private var isTagPickerPresented: Bool = false

    @State private var draftDescription: String = ""
    @State private var draftProjectId: UUID? = nil
    @State private var draftTaskId: UUID? = nil
    @State private var draftTagIds: [UUID] = []
    @State private var draftIsBillable: Bool = false

    public init(isStandaloneWindow: Bool = false, onDismiss: @escaping () -> Void = {}) {
        self.isStandaloneWindow = isStandaloneWindow
        self.onDismiss = onDismiss
    }

    private var accentColor: Color {
        switch pomodoro.sessionType {
        case .work:
            return AppColors.togglMagenta
        case .shortBreak, .longBreak:
            return AppColors.billable
        }
    }

    private var phaseSubtitle: String {
        if !pomodoro.isRunning && !pomodoro.isPaused {
            return "Ready?"
        }
        if pomodoro.isPaused {
            return "Paused"
        }
        switch pomodoro.sessionType {
        case .work:
            return "Focus • Session \(pomodoro.completedWorkSessions + 1)/\(pomodoro.targetIntervalCount)"
        case .shortBreak:
            return "Short breather"
        case .longBreak:
            return "Long recharge"
        }
    }

    private var focusSummaryLabel: String {
        let trimmed = pomodoro.focusDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        if let pid = pomodoro.focusProjectId, let proj = store.project(for: pid) {
            return proj.name
        }
        return "I'm focusing on..."
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Optional Pop-out Window header when opened in popover
            if !isStandaloneWindow {
                HStack {
                    Text("Pomodoro")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button {
                        openWindow(id: "pomodoro")
                        onDismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "macwindow.badge.plus")
                                .font(.system(size: 11))
                            Text("Window")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open floating Pomodoro window")
                }
            }

            // "I'm focusing on..." Intent Pill -> DETAILS Popover
            Button {
                draftDescription = pomodoro.focusDescription
                draftProjectId = pomodoro.focusProjectId
                draftTaskId = pomodoro.focusTaskId
                draftTagIds = pomodoro.focusTagIds
                draftIsBillable = pomodoro.focusIsBillable
                isDetailsPresented.toggle()
            } label: {
                HStack(spacing: 6) {
                    if let pid = pomodoro.focusProjectId, let proj = store.project(for: pid) {
                        Circle()
                            .fill(Color(hex: proj.colorHex))
                            .frame(width: 7, height: 7)
                    }
                    Text(focusSummaryLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(pomodoro.focusDescription.isEmpty && pomodoro.focusProjectId == nil ? .secondary : .primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(AppColors.insetBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isDetailsPresented, arrowEdge: .leading) {
                detailsPopover
            }

            // 60-Tick Toggl Pomodoro Circular Dial
            ZStack {
                Circle()
                    .fill(AppColors.insetBackground.opacity(0.65))
                    .frame(width: 190, height: 190)

                Circle()
                    .stroke(accentColor.opacity(0.20), lineWidth: 10)
                    .frame(width: 190, height: 190)

                Circle()
                    .trim(from: 0, to: CGFloat(max(0.0, min(1.0, pomodoro.progressPercentage))))
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .butt)
                    )
                    .frame(width: 190, height: 190)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: pomodoro.progressPercentage)

                // 60 Radial Tick Marks inside Ring
                ForEach(0..<60, id: \.self) { tick in
                    let isMajor = tick % 5 == 0
                    Rectangle()
                        .fill(Color.primary.opacity(isMajor ? 0.55 : 0.22))
                        .frame(width: isMajor ? 1.5 : 1.0, height: isMajor ? 8 : 5)
                        .offset(y: -78)
                        .rotationEffect(.degrees(Double(tick) * 6.0))
                }

                // Center Dial Stack
                VStack(spacing: 4) {
                    Text(pomodoro.sessionType.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(pomodoro.formattedDisplayTime)
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.primary)

                    Text(phaseSubtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(pomodoro.isRunning ? accentColor : .secondary)
                }
            }
            .frame(width: 204, height: 204)

            // Primary Action CTA + Secondary Controls
            VStack(spacing: 8) {
                if !pomodoro.isRunning && !pomodoro.isPaused {
                    Button {
                        pomodoro.start(
                            description: pomodoro.focusDescription,
                            projectId: pomodoro.focusProjectId,
                            taskId: pomodoro.focusTaskId,
                            tagIds: pomodoro.focusTagIds,
                            isBillable: pomodoro.focusIsBillable
                        )
                    } label: {
                        Text("Start session")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 8) {
                        Button {
                            if pomodoro.isRunning {
                                pomodoro.pause()
                            } else {
                                pomodoro.resume()
                            }
                        } label: {
                            Label(pomodoro.isRunning ? "Pause" : "Resume",
                                  systemImage: pomodoro.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        Button {
                            pomodoro.skip()
                        } label: {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 12))
                                .frame(width: 34, height: 34)
                                .background(AppColors.insetBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .help("Skip phase")

                        Button {
                            pomodoro.reset()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                                .frame(width: 34, height: 34)
                                .background(AppColors.insetBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .help("Reset session")
                    }
                }
            }

            // Expandable Pomodoro Settings Disclosure
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isSettingsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Pomodoro settings")
                        .underline()
                    Image(systemName: isSettingsExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if isSettingsExpanded {
                inlineSettingsDrawer
            }
        }
        .padding(18)
        .frame(width: 280)
        .frame(maxHeight: isStandaloneWindow ? .infinity : nil)
        .background(AppColors.cardBackground)
    }

    @ViewBuilder
    private var detailsPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DETAILS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
                Spacer()
                Button {
                    isDetailsPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            TextField("Description...", text: $draftDescription)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AppColors.insetBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppColors.focusBorder, lineWidth: 1.5)
                )

            HStack(spacing: 8) {
                Button {
                    isProjectPickerPresented.toggle()
                } label: {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(draftProjectId != nil ? AppColors.togglMagenta : .secondary)
                        .padding(6)
                        .background(AppColors.insetBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isProjectPickerPresented) {
                    ProjectPickerPopover(selectedProjectId: $draftProjectId, selectedTaskId: $draftTaskId) {
                        isProjectPickerPresented = false
                    }
                }

                Button {
                    isTagPickerPresented.toggle()
                } label: {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(!draftTagIds.isEmpty ? AppColors.togglMagenta : .secondary)
                        .padding(6)
                        .background(AppColors.insetBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isTagPickerPresented) {
                    TagPickerPopover(selectedTagIds: $draftTagIds) {
                        isTagPickerPresented = false
                    }
                }

                Button {
                    draftIsBillable.toggle()
                } label: {
                    Text("$")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(draftIsBillable ? AppColors.billable : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(draftIsBillable ? AppColors.billable.opacity(0.16) : AppColors.insetBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    pomodoro.updateFocusIntent(
                        description: draftDescription,
                        projectId: draftProjectId,
                        taskId: draftTaskId,
                        tagIds: draftTagIds,
                        isBillable: draftIsBillable
                    )
                    isDetailsPresented = false
                } label: {
                    Text("Save")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(AppColors.togglMagenta)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 260)
        .background(AppColors.popoverBackground)
    }

    @ViewBuilder
    private var inlineSettingsDrawer: some View {
        @Bindable var bindablePomodoro = pomodoro
        VStack(alignment: .leading, spacing: 8) {
            Divider().overlay(AppColors.border)

            Stepper("Focus: \(Int(pomodoro.workDuration / 60)) min", value: Binding(
                get: { Int(pomodoro.workDuration / 60) },
                set: { pomodoro.workDuration = TimeInterval(max(1, min(120, $0)) * 60) }
            ), in: 1...120)
            .font(.system(size: 11))

            Stepper("Short break: \(Int(pomodoro.shortBreakDuration / 60)) min", value: Binding(
                get: { Int(pomodoro.shortBreakDuration / 60) },
                set: { pomodoro.shortBreakDuration = TimeInterval(max(1, min(60, $0)) * 60) }
            ), in: 1...60)
            .font(.system(size: 11))

            Stepper("Long break: \(Int(pomodoro.longBreakDuration / 60)) min", value: Binding(
                get: { Int(pomodoro.longBreakDuration / 60) },
                set: { pomodoro.longBreakDuration = TimeInterval(max(1, min(60, $0)) * 60) }
            ), in: 1...60)
            .font(.system(size: 11))

            Toggle("Auto-start breaks", isOn: $bindablePomodoro.autoStartBreaks)
                .font(.system(size: 11))
            Toggle("Auto-start focus sessions", isOn: $bindablePomodoro.autoStartFocus)
                .font(.system(size: 11))
            Toggle("Count-up display", isOn: $bindablePomodoro.countUpMode)
                .font(.system(size: 11))
            Toggle("macOS notifications", isOn: $bindablePomodoro.notificationsEnabled)
                .font(.system(size: 11))
            Toggle("Completion sound", isOn: $bindablePomodoro.soundEnabled)
                .font(.system(size: 11))
        }
    }
}
