import Foundation

public enum TimeCalculator {
    /// Computes the elapsed duration in seconds using wall-clock timestamps.
    /// Uses max(0, ...) defensively against system clock backward skew.
    public static func calculateDuration(
        startDate: Date,
        endDate: Date? = nil,
        accumulatedDuration: TimeInterval = 0,
        isPaused: Bool = false,
        now: Date = Date()
    ) -> TimeInterval {
        if let endDate = endDate {
            let session = max(0, endDate.timeIntervalSince(startDate))
            return max(0, accumulatedDuration + session)
        } else if isPaused {
            return max(0, accumulatedDuration)
        } else {
            let running = max(0, now.timeIntervalSince(startDate))
            return max(0, accumulatedDuration + running)
        }
    }

    /// Formats an interval in seconds into a zero-padded HH:MM:SS string.
    public static func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded(.down)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// Formats an interval in seconds into Toggl compact H:MM:SS style (e.g. 0:00:00, 1:23:45).
    public static func formatCompactDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded(.down)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
}
