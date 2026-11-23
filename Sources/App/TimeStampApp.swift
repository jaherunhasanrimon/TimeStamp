import SwiftUI

@main
struct TimeStampApp: App {
    @State private var store = PersistenceStore.shared
    @State private var timerManager = TimerManager.shared
    @State private var selectedDestination: SidebarDestination? = .timer

    init() {
        GlobalHotkeyManager.shared.setupTimerToggle(timerManager: TimerManager.shared)
    }

    var body: some Scene {
        WindowGroup("TimeStamp", id: "main") {
            NavigationSplitView {
                AppSidebar(selection: $selectedDestination)
            } detail: {
                DetailContainerView(destination: $selectedDestination)
            }
            .frame(
                minWidth: 800,
                idealWidth: 1000,
                minHeight: 550,
                idealHeight: 700
            )
            .environment(store)
            .environment(timerManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))

        // macOS System Menu Bar Companion (SYS-01, SYS-02)
        MenuBarExtra {
            MenuBarPopoverView()
                .environment(store)
                .environment(timerManager)
        } label: {
            MenuBarLabelView()
                .environment(timerManager)
        }
        .menuBarExtraStyle(.window)
    }
}
