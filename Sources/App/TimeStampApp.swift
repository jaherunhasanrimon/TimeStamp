import SwiftUI

@main
struct TimeStampApp: App {
    @State private var store = PersistenceStore.shared
    @State private var timerManager = TimerManager.shared
    @State private var pomodoroManager = PomodoroManager.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var selectedDestination: SidebarDestination? = .timer
    @AppStorage("appTheme") private var appTheme: String = "dark"
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
            .environment(store)
            .environment(timerManager)
            .environment(pomodoroManager)
            .environment(notificationManager)
            .preferredColorScheme(resolvedColorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        .commands {
            CommandGroup(after: .windowSize) {
                Button(isFullWorkspace ? "Switch to Compact Tracker" : "Expand to Full Workspace") {
                    isFullWorkspace.toggle()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }

        // macOS System Menu Bar Companion (SYS-01, SYS-02)
        MenuBarExtra {
            MenuBarPopoverView()
                .environment(store)
                .environment(timerManager)
                .environment(pomodoroManager)
                .environment(notificationManager)
        } label: {
            MenuBarLabelView()
                .environment(timerManager)
                .environment(pomodoroManager)
        }
        .menuBarExtraStyle(.window)
    }
}
