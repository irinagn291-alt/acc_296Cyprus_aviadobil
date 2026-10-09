import Foundation

/// Family invariant for a reading expedition. The angle is derived, never stored,
/// and stays off the elevation canvas: a missed day is a GapSegment, not a curl.
/// driftAngle = (lastEndPage / total − progress) × 45. Route x is profileX.
enum ProfileDrift {
    static func driftAngle(lastEndPage: Double, totalPages: Double, progress: Double) -> Double {
        guard totalPages > 0 else { return 0 }
        return (lastEndPage / totalPages - progress) * 45
    }

    /// Progress is elapsed days over the planned summit span. A same-day span is one.
    static func progress(elapsedDays: Int, plannedSpanDays: Int) -> Double {
        let span = max(plannedSpanDays, 1)
        return Double(elapsedDays) / Double(span)
    }
}
