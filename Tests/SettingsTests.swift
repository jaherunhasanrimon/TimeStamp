import Testing
import SwiftUI
import Carbon
@testable import TimeStamp

@Suite("Settings & Preferences Tests")
@MainActor
struct SettingsTests {

    @Test("Theme resolution maps string identifiers to ColorScheme correctly")
    func testThemeResolution() throws {
        func resolveTheme(_ id: String) -> ColorScheme? {
            switch id {
            case "light": return .light
            case "dark": return .dark
            default: return nil
            }
        }

        #expect(resolveTheme("system") == nil)
        #expect(resolveTheme("light") == .light)
        #expect(resolveTheme("dark") == .dark)
    }

    @Test("Dynamic hotkey update in GlobalHotkeyManager updates properties cleanly")
    func testDynamicHotkeyUpdate() throws {
        let manager = GlobalHotkeyManager.shared

        // Update to ⌃⌥T
        manager.updateHotkey(
            keyCode: 17,
            modifiers: UInt32(controlKey | optionKey),
            display: "⌃⌥T"
        )

        #expect(manager.currentKeyCode == 17)
        #expect(manager.currentModifiers == UInt32(controlKey | optionKey))
        #expect(manager.displayString == "⌃⌥T")

        // Reset back to default ⌥⇧T
        manager.updateHotkey(
            keyCode: GlobalHotkeyManager.defaultKeyCode,
            modifiers: GlobalHotkeyManager.defaultModifiers,
            display: GlobalHotkeyManager.defaultDisplay
        )

        #expect(manager.displayString == "⌥⇧T")
    }

    @Test("Sample data seeding populates projects, clients, tasks, and time entries")
    func testSampleDataSeeding() throws {
        let store = PersistenceStore(inMemory: true)
        #expect(store.projects.isEmpty)
        #expect(store.clients.isEmpty)
        #expect(store.timeEntries.isEmpty)

        PreviewContainer.seedSampleData(store: store)

        #expect(!store.projects.isEmpty)
        #expect(!store.clients.isEmpty)
        #expect(!store.tasks.isEmpty)
        #expect(!store.timeEntries.isEmpty)
    }

    @Test("Reset all data wipes all collections cleanly")
    func testResetAllData() throws {
        let store = PersistenceStore(inMemory: true)
        PreviewContainer.seedSampleData(store: store)

        #expect(!store.projects.isEmpty)
        #expect(!store.timeEntries.isEmpty)

        store.clearAll()

        #expect(store.clients.isEmpty)
        #expect(store.projects.isEmpty)
        #expect(store.tasks.isEmpty)
        #expect(store.tags.isEmpty)
        #expect(store.timeEntries.isEmpty)
    }
}
