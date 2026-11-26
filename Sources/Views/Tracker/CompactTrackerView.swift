import SwiftUI

/// Toggl Track Authentic Compact Desktop Tracker Window (Reference Images 1 & 5).
/// Features:
/// 1. Top Two-Row Active Timer Bar (Pomodoro Tomato, Description, Monospace Ticker, Circular Magenta Play Button, Folder/Tag/Billable actions)
/// 2. Capsule View Switcher [ List | Calendar ] with Toggl Magenta underline
/// 3. Subheader: "TODAY TOTAL 0:00:00" + "EXPAND TO WORKSPACE ↗"
/// 4. Collapsible Goals Card (Goals 4/4 with bronze badges and "KEEP GOING")
/// 5. Daily Entries List / Interactive Calendar with "Let's get tracking!" empty state
public struct CompactTrackerView: View {
    @Environment(PersistenceStore.self) private var store
    @Environment(TimerManager.self) private var timerManager

    @State private var selectedMode: TrackerViewMode = .list
    @State private var entryFilter: EntryFilter = .none
    public let onExpandToWorkspace: () -> Void

    public init(onExpandToWorkspace: @escaping () -> Void) {
        self.onExpandToWorkspace = onExpandToWorkspace
    }

    private var todayTotalDuration: TimeInterval {
        let calendar = Calendar.current
        let today = Date()
        let completedSum = store.timeEntries
            .filter { $0.endDate != nil && calendar.isDate($0.startDate, inSameDayAs: today) }
            .reduce(0.0) { $0 + $1.effectiveDuration }
        let activeDuration: TimeInterval = {
            guard let active = timerManager.activeEntry,
                  calendar.isDate(active.startDate, inSameDayAs: today) else {
                return 0.0
            }
            return timerManager.currentDuration
        }()
        return completedSum + activeDuration
    }

    private var formattedTodayTotal: String {
        TimeCalculator.formatCompactDuration(todayTotalDuration)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Active Timer Bar (elevated zIndex so autocomplete floats above body)
            ActiveTimerBar()
                .zIndex(50)

            // 2. Capsule View Switcher [ List | Calendar ]
            CapsuleViewSwitcher(selectedMode: $selectedMode)

            // 3. Subheader: TODAY TOTAL + EXPAND TO WORKSPACE ↗
            HStack {
                HStack(spacing: 6) {
                    Text("TODAY TOTAL")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text(formattedTodayTotal)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.primary)
                }

                Spacer()

                Button(action: onExpandToWorkspace) {
                    HStack(spacing: 4) {
                        Text("EXPAND TO WORKSPACE")
                            .font(.system(size: 10, weight: .bold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(AppColors.togglMagenta)
                }
                .buttonStyle(.plain)
                .help("Open full workspace with reports, projects & clients")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppColors.background)

            // 4. Main Body Content
            ScrollView {
                VStack(spacing: 16) {
                    // Goals Section (Collapsible)
                    GoalsCardView()

                    // Mode Content
                    if selectedMode == .list {
                        EntriesListView(filter: $entryFilter, isCompact: true)
                    } else {
                        CalendarTimelineView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(minWidth: 400, idealWidth: 460, maxWidth: 600)
        .background(AppColors.background)
    }
}
