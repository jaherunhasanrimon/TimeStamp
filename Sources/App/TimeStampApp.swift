import SwiftUI

@main
struct TimeStampApp: App {
    @State private var store = PersistenceStore.shared
    @State private var timerManager = TimerManager.shared
    @State private var pomodoroManager = PomodoroManager.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var idleManager = IdleDetectionManager.shared
    @State private var reminderManager = ReminderManager.shared
    @State private var activityManager = ActivityTrackerManager.shared
    @State private var systemManager = SystemIntegrationManager.shared
    @State private var selectedDestination: SidebarDestination? = .timer
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("isFullWorkspace") private var isFullWorkspace: Bool = false

    init() {
        GlobalHotkeyManager.shared.setupTimerToggle(timerManager: TimerManager.shared)
    }

    private var resolvedColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup("Workspace", id: "main") {
            RootWorkspaceContainer(
                isFullWorkspace: $isFullWorkspace,
                selectedDestination: $selectedDestination
            )
            .environment(store)
            .environment(timerManager)
            .environment(pomodoroManager)
            .environment(notificationManager)
            .environment(idleManager)
            .environment(reminderManager)
            .environment(activityManager)
            .environment(systemManager)
            .preferredColorScheme(resolvedColorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences...") {
                    isFullWorkspace = true
                    selectedDestination = .settings
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandMenu("Timer") {
                Button("New / Focus Timer") {
                    NotificationCenter.default.post(name: .tsFocusTimerField, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Switch Timer / Manual Mode") {
                    NotificationCenter.default.post(name: .tsToggleManualMode, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)

                Button("Stop Timer") {
                    _ = timerManager.stop()
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!timerManager.isRunning && !timerManager.isPaused)

                Button("Continue Last Entry") {
                    timerManager.continueLastEntry()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Edit Running / Latest Entry") {
                    NotificationCenter.default.post(name: .tsEditRunningEntry, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)

                Divider()

                Button("Toggle Mini-Timer") {
                    NotificationCenter.default.post(name: .tsToggleMiniTimer, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }

            CommandGroup(after: .windowSize) {
                Button(isFullWorkspace ? "Switch to Compact Tracker" : "Expand to Full Workspace") {
                    isFullWorkspace.toggle()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }

        // Floating Always-on-Top Mini Timer Window (Cmd+Shift+M)
        Window("Mini Timer", id: "mini-timer") {
            FloatingMiniTimerView()
                .environment(store)
                .environment(timerManager)
                .environment(pomodoroManager)
                .environment(notificationManager)
                .preferredColorScheme(resolvedColorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // Floating Standalone Pomodoro Window
        Window("Pomodoro", id: "pomodoro") {
            PomodoroPopoverView(isStandaloneWindow: true)
                .environment(store)
                .environment(timerManager)
                .environment(pomodoroManager)
                .environment(notificationManager)
                .preferredColorScheme(resolvedColorScheme)
        }
        .windowResizability(.contentSize)

        // macOS System Menu Bar Companion (SYS-01, SYS-02)
        MenuBarExtra {
            MenuBarPopoverView()
                .environment(store)
                .environment(timerManager)
                .environment(pomodoroManager)
                .environment(notificationManager)
                .environment(idleManager)
                .environment(reminderManager)
                .environment(activityManager)
                .environment(systemManager)
        } label: {
            MenuBarLabelView()
                .environment(store)
                .environment(timerManager)
                .environment(pomodoroManager)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct RootWorkspaceContainer: View {
    @Binding var isFullWorkspace: Bool
    @Binding var selectedDestination: SidebarDestination?

    @Environment(IdleDetectionManager.self) private var idleManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if isFullWorkspace {
                NavigationSplitView {
                    AppSidebar(
                        selection: $selectedDestination,
                        onSwitchToCompact: { isFullWorkspace = false }
                    )
                } detail: {
                    DetailContainerView(destination: $selectedDestination)
                }
                .frame(
                    minWidth: 800,
                    idealWidth: 1080,
                    minHeight: 580,
                    idealHeight: 740
                )
            } else {
                CompactTrackerView(
                    onExpandToWorkspace: { isFullWorkspace = true }
                )
                .frame(
                    minWidth: 400,
                    idealWidth: 460,
                    maxWidth: 600,
                    minHeight: 520,
                    idealHeight: 720
                )
            }
        }
        .onAppear {
            SystemIntegrationManager.shared.applyDockIconPolicy()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tsToggleMiniTimer)) { _ in
            if let existing = NSApp.windows.first(where: { $0.title == "Mini Timer" && $0.isVisible }) {
                existing.close()
            } else {
                openWindow(id: "mini-timer")
            }
        }
        .sheet(isPresented: Binding(
            get: { idleManager.isPromptPresented },
            set: { if !$0 { idleManager.dismissPrompt() } }
        )) {
            IdleResolutionSheet()
        }
    }
}
