import Foundation

/// A catalogue hit mapped from Open Library DTOs. Page count is optional
/// because the remote record is often incomplete.
struct MoorRecord: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var isbn: String
    var title: String
    var author: String
    var pageCount: Int?
}
