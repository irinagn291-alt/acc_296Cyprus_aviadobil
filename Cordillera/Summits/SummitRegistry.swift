import Foundation

/// Finished holds and the benchmark badges they earned. Derived from the chart.
struct SummitRegistry: Sendable, Equatable {
    struct Entry: Sendable, Equatable, Identifiable {
        var id: UUID
        var hold: Hold
        var bands: [Int]
    }

    var entries: [Entry]

    static func make(from chart: ContourChart) -> SummitRegistry {
        let entries = chart.holds
            .filter { $0.phase == .summited }
            .map { hold in
                let bands = chart.benchmarks
                    .filter { $0.holdID == hold.id }
                    .map(\.band)
                    .sorted()
                return Entry(id: hold.id, hold: hold, bands: bands)
            }
        return SummitRegistry(entries: entries)
    }
}
