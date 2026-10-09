import Foundation

/// The expedition written when Open folds a Packed hold to Active.
/// Summit is the volume's total page count, fixed at open.
struct Traverse: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var holdID: UUID
    var summitPages: Int
    var openedDay: Int
}
