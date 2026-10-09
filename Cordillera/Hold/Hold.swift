import Foundation

/// A volume moored in the pack. Packed until Open folds it to Active.
/// profileX is the stored route position: cumulative pages divided by totalPages.
struct Hold: Codable, Sendable, Identifiable, Equatable {
    enum Phase: String, Codable, Sendable {
        case packed
        case active
        case summited
    }

    var id: UUID
    var title: String
    var isbn: String
    var totalPages: Int
    var phase: Phase
    /// Route x. Cumulative pinned and bridged pages divided by totalPages, clamped to 1.
    var profileX: Double
    var openedDay: Int
    var plannedSummitDay: Int
}
