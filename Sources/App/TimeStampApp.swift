import SwiftUI

@main
struct TimeStampApp: App {
    @State private var store = PersistenceStore.shared

    var body: some Scene {
        WindowGroup {
            Text("TimeStamp")
                .frame(minWidth: 800, minHeight: 550)
                .environment(store)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
