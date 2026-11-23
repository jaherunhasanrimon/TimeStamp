import SwiftUI

public enum CalendarViewMode: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"

    public var id: String { rawValue }
}

public struct CalendarTimelineView: View {
    @Environment(PersistenceStore.self) private var store

    @State private var viewMode: CalendarViewMode = .week
    @State private var currentDate: Date = Date()

    public init() {}

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday start
        return cal
    }

    private var weekStart: Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
        return calendar.date(from: components) ?? calendar.startOfDay(for: currentDate)
    }

    private var weekEnd: Date {
        calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    private var headerDateTitle: String {
        switch viewMode {
        case .day:
            let f = DateFormatter()
            f.dateFormat = "EEEE, MMM d, yyyy"
            return f.string(from: currentDate)

        case .week:
            let startF = DateFormatter()
            startF.dateFormat = "MMM d"
            let endF = DateFormatter()
            endF.dateFormat = "MMM d, yyyy"
            return "\(startF.string(from: weekStart)) – \(endF.string(from: weekEnd))"
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Navigation & View Mode Toolbar
            HStack(spacing: AppSpacing.md) {
                // View Mode Segmented Picker (D-02)
                Picker("View", selection: $viewMode) {
                    ForEach(CalendarViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)

                // Date Navigation Cluster (D-02)
                HStack(spacing: AppSpacing.xs) {
                    Button(action: goToPrevious) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                    .help(viewMode == .day ? "Previous Day" : "Previous Week")

                    Button("Today") {
                        goToToday()
                    }
                    .font(AppTypography.label)
                    .padding(.horizontal, AppSpacing.sm)
                    .frame(height: 26)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                    .buttonStyle(.plain)

                    Button(action: goToNext) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                    .help(viewMode == .day ? "Next Day" : "Next Week")
                }

                Text(headerDateTitle)
                    .font(AppTypography.heading)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.cardBackground)
            .overlay(
                Rectangle()
                    .fill(AppColors.border)
                    .frame(height: 1),
                alignment: .bottom
            )

            // Timeline View Body
            Group {
                switch viewMode {
                case .day:
                    DayTimelineGridView(selectedDate: currentDate)
                case .week:
                    WeekTimelineGridView(weekStartDate: weekStart)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppColors.background)
    }

    private func goToPrevious() {
        let step = viewMode == .day ? -1 : -7
        currentDate = calendar.date(byAdding: .day, value: step, to: currentDate) ?? currentDate
    }

    private func goToNext() {
        let step = viewMode == .day ? 1 : 7
        currentDate = calendar.date(byAdding: .day, value: step, to: currentDate) ?? currentDate
    }

    private func goToToday() {
        currentDate = Date()
    }
}
