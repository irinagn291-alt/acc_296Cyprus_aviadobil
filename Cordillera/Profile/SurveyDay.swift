import Foundation

/// Day stamps for the contour. Every persisted day is an Int in YYYYMMDD form
/// taken from `Calendar.startOfDay`, so a daylight-saving edge stays one day.
enum SurveyDay {
    static func stamp(_ date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }

    static func date(from stamp: Int, calendar: Calendar = .current) -> Date? {
        var parts = DateComponents()
        parts.year = stamp / 10_000
        parts.month = (stamp / 100) % 100
        parts.day = stamp % 100
        parts.hour = 0
        guard let composed = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: composed)
    }

    static func adding(days: Int, to stamp: Int, calendar: Calendar = .current) -> Int {
        guard let origin = date(from: stamp, calendar: calendar),
              let shifted = calendar.date(byAdding: .day, value: days, to: origin) else {
            return stamp
        }
        return Self.stamp(shifted, calendar: calendar)
    }

    /// Whole start-of-day steps from `start` to `end`. Zero when the stamps match.
    static func span(from start: Int, to end: Int, calendar: Calendar = .current) -> Int {
        guard let left = date(from: start, calendar: calendar),
              let right = date(from: end, calendar: calendar) else {
            return 0
        }
        let pieces = calendar.dateComponents([.day], from: left, to: right)
        return pieces.day ?? 0
    }

    /// Days strictly after `start` and strictly before `end`.
    static func between(after start: Int, before end: Int, calendar: Calendar = .current) -> [Int] {
        guard span(from: start, to: end, calendar: calendar) > 1 else { return [] }
        var cursor = adding(days: 1, to: start, calendar: calendar)
        var marks: [Int] = []
        while span(from: cursor, to: end, calendar: calendar) > 0 {
            marks.append(cursor)
            cursor = adding(days: 1, to: cursor, calendar: calendar)
        }
        return marks
    }

    /// ISO week key `yearForWeekOfYear * 100 + weekOfYear`, stable for Bridge.
    static func isoWeek(for date: Date, calendar: Calendar = .current) -> Int {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = calendar.timeZone
        iso.locale = calendar.locale
        let week = iso.component(.weekOfYear, from: date)
        let year = iso.component(.yearForWeekOfYear, from: date)
        return year * 100 + week
    }

    static func isoWeek(stamp: Int, calendar: Calendar = .current) -> Int {
        guard let date = date(from: stamp, calendar: calendar) else { return 0 }
        return isoWeek(for: date, calendar: calendar)
    }
}
