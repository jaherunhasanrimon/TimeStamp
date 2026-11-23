import SwiftUI
import AppKit

public struct VisualEffectBackground: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode

    public init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .followsWindowActiveState
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

public struct AppSidebar: View {
    @Binding public var selection: SidebarDestination?

    public init(selection: Binding<SidebarDestination?>) {
        self._selection = selection
    }

    public var body: some View {
        List(selection: $selection) {
            Section("Track") {
                sidebarRow(for: .timer)
                sidebarRow(for: .calendar)
            }

            Section("Analyze") {
                sidebarRow(for: .dashboard)
                sidebarRow(for: .reports)
            }

            Section("Manage") {
                sidebarRow(for: .projects)
                sidebarRow(for: .clients)
            }

            Section {
                sidebarRow(for: .settings)
            } header: {
                Text("Preferences")
            }
        }
        .listStyle(.sidebar)
        .background(VisualEffectBackground(material: .sidebar))
        .frame(minWidth: 200, idealWidth: 220)
    }

    @ViewBuilder
    private func sidebarRow(for destination: SidebarDestination) -> some View {
        NavigationLink(value: destination) {
            Label(destination.rawValue, systemImage: destination.systemImage)
                .font(AppTypography.body)
        }
    }
}
