import Foundation

/// Pushes the planned summit day forward and clears a Pin refusal caused by too many gaps.
struct RecenterMark: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var holdID: UUID
    var day: Int
    var previousSummitDay: Int
    var plannedSummitDay: Int
}
