import Foundation

public struct PositionedBlock: Identifiable, Equatable {
    public let id: UUID
    public let entry: TimeEntry
    public let startMinutes: Double // 0.0 ... 1440.0
    public let durationMinutes: Double
    public let subColumnIndex: Int
    public let totalSubColumns: Int

    public init(
        id: UUID = UUID(),
        entry: TimeEntry,
        startMinutes: Double,
        durationMinutes: Double,
        subColumnIndex: Int,
        totalSubColumns: Int
    ) {
        self.id = id
        self.entry = entry
        self.startMinutes = startMinutes
        self.durationMinutes = durationMinutes
        self.subColumnIndex = subColumnIndex
        self.totalSubColumns = totalSubColumns
    }
}

public enum CalendarLayoutHelper {

    private struct CandidateBlock {
        let entry: TimeEntry
        let startMinutes: Double
        let endMinutes: Double
        var durationMinutes: Double { endMinutes - startMinutes }
    }

    /// Computes layout positions and partitions overlapping entries into sub-columns
    public static func computeBlockLayouts(
        entries: [TimeEntry],
        for date: Date,
        calendar: Calendar = .current
    ) -> [PositionedBlock] {
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        // 1. Filter entries overlapping this calendar day
        var candidates: [CandidateBlock] = []

        for entry in entries {
            let entryStart = entry.startDate
            let entryEnd = entry.endDate ?? (entry.isPaused ? entry.startDate.addingTimeInterval(entry.accumulatedDuration) : Date())

            // Check if entry overlaps with [startOfDay, endOfDay)
            if entryEnd <= startOfDay || entryStart >= endOfDay {
                continue
            }

            // Clamp to day boundaries
            let effectiveStart = max(startOfDay, entryStart)
            let effectiveEnd = min(endOfDay, max(effectiveStart.addingTimeInterval(60), entryEnd))

            let startMin = effectiveStart.timeIntervalSince(startOfDay) / 60.0
            let endMin = effectiveEnd.timeIntervalSince(startOfDay) / 60.0

            candidates.append(
                CandidateBlock(
                    entry: entry,
                    startMinutes: max(0.0, min(1440.0, startMin)),
                    endMinutes: max(0.0, min(1440.0, endMin))
                )
            )
        }

        // Sort candidates by startMinutes ascending, duration descending
        candidates.sort {
            if abs($0.startMinutes - $1.startMinutes) > 0.001 {
                return $0.startMinutes < $1.startMinutes
            }
            return $0.durationMinutes > $1.durationMinutes
        }

        guard !candidates.isEmpty else { return [] }

        // 2. Partition into clusters of overlapping entries
        var clusters: [[CandidateBlock]] = []
        var currentCluster: [CandidateBlock] = []
        var clusterMaxEnd: Double = 0

        for candidate in candidates {
            if currentCluster.isEmpty {
                currentCluster.append(candidate)
                clusterMaxEnd = candidate.endMinutes
            } else if candidate.startMinutes < clusterMaxEnd {
                // Overlaps with current cluster
                currentCluster.append(candidate)
                clusterMaxEnd = max(clusterMaxEnd, candidate.endMinutes)
            } else {
                // Gap reached: push previous cluster and start new one
                clusters.append(currentCluster)
                currentCluster = [candidate]
                clusterMaxEnd = candidate.endMinutes
            }
        }
        if !currentCluster.isEmpty {
            clusters.append(currentCluster)
        }

        // 3. For each cluster, assign sub-columns using greedy interval coloring
        var result: [PositionedBlock] = []

        for cluster in clusters {
            var columnEndTimes: [Double] = []
            var assignments: [(CandidateBlock, Int)] = []

            for item in cluster {
                // Find first column where previous item ended at or before item.startMinutes
                var assignedCol = -1
                for colIdx in 0..<columnEndTimes.count {
                    if columnEndTimes[colIdx] <= item.startMinutes {
                        assignedCol = colIdx
                        columnEndTimes[colIdx] = item.endMinutes
                        break
                    }
                }

                if assignedCol == -1 {
                    assignedCol = columnEndTimes.count
                    columnEndTimes.append(item.endMinutes)
                }

                assignments.append((item, assignedCol))
            }

            let totalCols = max(1, columnEndTimes.count)
            for (item, colIdx) in assignments {
                result.append(
                    PositionedBlock(
                        id: item.entry.id,
                        entry: item.entry,
                        startMinutes: item.startMinutes,
                        durationMinutes: item.durationMinutes,
                        subColumnIndex: colIdx,
                        totalSubColumns: totalCols
                    )
                )
            }
        }

        return result
    }
}
