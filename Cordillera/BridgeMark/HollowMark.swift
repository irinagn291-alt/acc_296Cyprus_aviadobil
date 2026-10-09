import Foundation

/// Written when Bridge fires in an ISO week that has no open gap to close.
struct HollowMark: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var holdID: UUID
    var day: Int
    var isoWeek: Int
    var pagesSpent: Int
}
