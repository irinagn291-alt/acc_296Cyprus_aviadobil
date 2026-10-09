import Foundation

/// A dashed day on the profile. Appended when a calendar day has no Pin.
/// Closing a gap does not move profileX.
struct GapSegment: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var holdID: UUID
    var day: Int
    var closed: Bool
}
