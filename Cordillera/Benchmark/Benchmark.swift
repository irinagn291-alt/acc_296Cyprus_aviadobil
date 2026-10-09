import Foundation

/// A contour plaque spawned when Pin newly crosses a ten-percent band.
struct Benchmark: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var holdID: UUID
    var day: Int
    /// Band 1 is ten percent. Band 10 is the summit.
    var band: Int
}
