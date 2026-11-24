import Testing
import SwiftUI
@testable import TimeStamp

@MainActor
struct TogglReplicaTests {
    @Test func togglColorPaletteRoles() {
        #expect(AppColors.togglMagenta.toHex() == "#E54583")
        #expect(AppColors.brandAccent.toHex() == "#E54583")
        #expect(AppColors.focusBorder.toHex() == "#36B37E")
        #expect(AppColors.billable.toHex() == "#36B37E")
        #expect(AppColors.goalGold.toHex() == "#D4973B")
        #expect(AppColors.destructive.toHex() == "#FF453A")
    }

    @Test func timeEntryBillableProperty() throws {
        let entry = TimeEntry(
            entryDescription: "Client Call",
            isBillable: true
        )
        #expect(entry.isBillable == true)

        let encoded = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(TimeEntry.self, from: encoded)
        #expect(decoded.isBillable == true)
        #expect(decoded == entry)
    }

    @Test func capsuleViewSwitcherModes() {
        let modes = TrackerViewMode.allCases
        #expect(modes.count == 2)
        #expect(modes[0] == .list)
        #expect(modes[1] == .calendar)
        #expect(TrackerViewMode.list.rawValue == "List")
        #expect(TrackerViewMode.calendar.rawValue == "Calendar")
    }

    @Test func circularPlayButtonInstantiation() {
        let idleButton = CircularPlayButton(isRunning: false, onToggle: {})
        #expect(idleButton.isRunning == false)
        #expect(idleButton.isPaused == false)

        let runningButton = CircularPlayButton(isRunning: true, isPaused: true, onToggle: {}, onPauseToggle: {})
        #expect(runningButton.isRunning == true)
        #expect(runningButton.isPaused == true)
    }

    @Test func togglEmptyStateStyles() {
        let welcome = TogglEmptyStateView(style: .letsGetTracking)
        #expect(type(of: welcome.body) != EmptyView.self)

        let binoculars = TogglEmptyStateView(
            style: .binoculars(
                title: "No entries found in the selected period",
                subtitle: "There's no activity here"
            )
        )
        #expect(type(of: binoculars.body) != EmptyView.self)
    }

    @Test func compactTrackerViewInstantiation() {
        var didExpand = false
        let view = CompactTrackerView(onExpandToWorkspace: {
            didExpand = true
        })
        #expect(type(of: view) == CompactTrackerView.self)
        view.onExpandToWorkspace()
        #expect(didExpand == true)
    }

    @Test func goalsCardInstantiation() {
        let goalsCard = GoalsCardView()
        #expect(type(of: goalsCard) == GoalsCardView.self)
    }
}
