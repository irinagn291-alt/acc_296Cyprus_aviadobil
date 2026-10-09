import Foundation

/// One closure per ISO week. Spends twice the offered pages and closes the oldest open gap.
struct BridgeMark: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var holdID: UUID
    var day: Int
    var isoWeek: Int
    var pagesSpent: Int
    var closedGapID: UUID
}
