import Foundation

/// A waypoint. Pin writes one mark for today's pages and advances profileX.
struct TrigMark: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var holdID: UUID
    var day: Int
    var pages: Int
    /// Running end page after this pin. The latest value is lastEndPage.
    var endPage: Int
}
