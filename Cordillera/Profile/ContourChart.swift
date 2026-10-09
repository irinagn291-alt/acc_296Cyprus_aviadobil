import Foundation

/// Contour is an ADT fold over Holds: Bare when the pack is empty, otherwise
/// Packed, Active, or Summited. Open, Pin, Peel, Bridge, and Recenter are the
/// only transitions. The profile is this fold, not a stored schedule.
struct ContourChart: Codable, Sendable, Equatable {
    static let currentSchema = 1

    var schemaVersion: Int
    var holds: [Hold]
    var traverses: [Traverse]
    var trigMarks: [TrigMark]
    var benchmarks: [Benchmark]
    var gapSegments: [GapSegment]
    var bridgeMarks: [BridgeMark]
    var recenterMarks: [RecenterMark]
    var hollowMarks: [HollowMark]
    /// Resolved Open Library titles cached so a failed search still has a shelf.
    var moorings: [MoorRecord]

    static var bare: ContourChart {
        ContourChart(
            schemaVersion: currentSchema,
            holds: [],
            traverses: [],
            trigMarks: [],
            benchmarks: [],
            gapSegments: [],
            bridgeMarks: [],
            recenterMarks: [],
            hollowMarks: [],
            moorings: []
        )
    }

    enum Fold: String, Sendable, Equatable {
        case bare
        case packed
        case active
        case summited
    }

    var fold: Fold {
        if holds.isEmpty { return .bare }
        if holds.contains(where: { $0.phase == .active }) { return .active }
        if holds.contains(where: { $0.phase == .packed }) { return .packed }
        return .summited
    }

    var activeHold: Hold? {
        holds.first { $0.phase == .active }
    }

    init(schemaVersion: Int, holds: [Hold], traverses: [Traverse], trigMarks: [TrigMark], benchmarks: [Benchmark], gapSegments: [GapSegment], bridgeMarks: [BridgeMark], recenterMarks: [RecenterMark], hollowMarks: [HollowMark], moorings: [MoorRecord]) {
        self.schemaVersion = schemaVersion
        self.holds = holds
        self.traverses = traverses
        self.trigMarks = trigMarks
        self.benchmarks = benchmarks
        self.gapSegments = gapSegments
        self.bridgeMarks = bridgeMarks
        self.recenterMarks = recenterMarks
        self.hollowMarks = hollowMarks
        self.moorings = moorings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 0
        switch version {
        case 1:
            schemaVersion = 1
            holds = try container.decodeIfPresent([Hold].self, forKey: .holds) ?? []
            traverses = try container.decodeIfPresent([Traverse].self, forKey: .traverses) ?? []
            trigMarks = try container.decodeIfPresent([TrigMark].self, forKey: .trigMarks) ?? []
            benchmarks = try container.decodeIfPresent([Benchmark].self, forKey: .benchmarks) ?? []
            gapSegments = try container.decodeIfPresent([GapSegment].self, forKey: .gapSegments) ?? []
            bridgeMarks = try container.decodeIfPresent([BridgeMark].self, forKey: .bridgeMarks) ?? []
            recenterMarks = try container.decodeIfPresent([RecenterMark].self, forKey: .recenterMarks) ?? []
            hollowMarks = try container.decodeIfPresent([HollowMark].self, forKey: .hollowMarks) ?? []
            moorings = try container.decodeIfPresent([MoorRecord].self, forKey: .moorings) ?? []
        default:
            throw ContourStoreError.unknownSchema(version)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(holds, forKey: .holds)
        try container.encode(traverses, forKey: .traverses)
        try container.encode(trigMarks, forKey: .trigMarks)
        try container.encode(benchmarks, forKey: .benchmarks)
        try container.encode(gapSegments, forKey: .gapSegments)
        try container.encode(bridgeMarks, forKey: .bridgeMarks)
        try container.encode(recenterMarks, forKey: .recenterMarks)
        try container.encode(hollowMarks, forKey: .hollowMarks)
        try container.encode(moorings, forKey: .moorings)
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case holds
        case traverses
        case trigMarks
        case benchmarks
        case gapSegments
        case bridgeMarks
        case recenterMarks
        case hollowMarks
        case moorings
    }

    /// Moor a packed volume. Pages must be positive. This does not open a traverse.
    @discardableResult
    mutating func moor(title: String, isbn: String, totalPages: Int, on day: Int) throws -> Hold {
        guard totalPages > 0 else { throw ContourRefusal.invalidPages }
        let hold = Hold(
            id: UUID(),
            title: title,
            isbn: isbn,
            totalPages: totalPages,
            phase: .packed,
            profileX: 0,
            openedDay: day,
            plannedSummitDay: day
        )
        holds.append(hold)
        return hold
    }

    /// Open writes a Traverse and folds Packed to Active. A second Open while
    /// any hold is Active is refused. Pin on Packed is refused elsewhere.
    @discardableResult
    mutating func open(holdID: UUID, on day: Int, plannedSummitDay: Int) throws -> Traverse {
        if holds.contains(where: { $0.phase == .active }) {
            throw ContourRefusal.secondOpen
        }
        guard let index = holds.firstIndex(where: { $0.id == holdID }) else {
            throw ContourRefusal.missingHold
        }
        guard holds[index].phase == .packed else {
            throw ContourRefusal.secondOpen
        }
        holds[index].phase = .active
        holds[index].openedDay = day
        holds[index].plannedSummitDay = max(plannedSummitDay, day)
        let traverse = Traverse(
            id: UUID(),
            holdID: holdID,
            summitPages: holds[index].totalPages,
            openedDay: day
        )
        traverses.append(traverse)
        return traverse
    }

    func openGapCount(holdID: UUID) -> Int {
        gapSegments.filter { $0.holdID == holdID && !$0.closed }.count
    }

    /// Append GapSegments for calendar days with no Pin. Does not move profileX.
    mutating func recordGaps(holdID: UUID, through day: Int, calendar: Calendar = .current) {
        guard let hold = holds.first(where: { $0.id == holdID }) else { return }
        let pinnedDays = Set(trigMarks.filter { $0.holdID == holdID }.map(\.day))
        let existing = Set(gapSegments.filter { $0.holdID == holdID }.map(\.day))
        let origin = trigMarks
            .filter { $0.holdID == holdID }
            .map(\.day)
            .max() ?? hold.openedDay
        for stamp in SurveyDay.between(after: origin, before: day, calendar: calendar) {
            if pinnedDays.contains(stamp) || existing.contains(stamp) { continue }
            gapSegments.append(GapSegment(id: UUID(), holdID: holdID, day: stamp, closed: false))
        }
    }

    /// Pin writes a TrigMark, advances profileX, and may write a Benchmark.
    @discardableResult
    mutating func pin(pages: Int, on day: Int, calendar: Calendar = .current) throws -> TrigMark {
        guard pages > 0 else { throw ContourRefusal.invalidPages }
        guard let index = holds.firstIndex(where: { $0.phase == .active }) else {
            if holds.contains(where: { $0.phase == .packed }) {
                throw ContourRefusal.pinOnPacked
            }
            throw ContourRefusal.noActiveHold
        }
        let holdID = holds[index].id
        recordGaps(holdID: holdID, through: day, calendar: calendar)
        if openGapCount(holdID: holdID) > 3 {
            throw ContourRefusal.gapsBlockPin
        }
        return try writePages(pages, on: day, holdIndex: index, kind: .pin)
    }

    /// Peel drops the latest TrigMark and rebuilds profileX from the marks that remain.
    /// With no marks left, the traverse clears and the hold folds back to Packed.
    @discardableResult
    mutating func peel() throws -> TrigMark {
        guard let hold = activeHold ?? holds.first(where: { $0.phase == .summited }) else {
            throw ContourRefusal.noActiveHold
        }
        guard let last = trigMarks.last(where: { $0.holdID == hold.id }) else {
            throw ContourRefusal.nothingToPeel
        }
        trigMarks.removeAll { $0.id == last.id }
        guard let index = holds.firstIndex(where: { $0.id == hold.id }) else {
            throw ContourRefusal.missingHold
        }
        applyProgress(holdIndex: index)
        let pagesNow = spentPages(holdID: hold.id)
        let totalPages = holds[index].totalPages
        let holdID = hold.id
        benchmarks.removeAll { mark in
            mark.holdID == holdID && !ContourChart.bandIsEarned(mark.band, pages: pagesNow, total: totalPages)
        }
        if trigMarks.contains(where: { $0.holdID == hold.id }) == false && bridgeMarks.contains(where: { $0.holdID == hold.id }) == false && hollowMarks.contains(where: { $0.holdID == hold.id }) == false {
            holds[index].phase = .packed
            holds[index].profileX = 0
            traverses.removeAll { $0.holdID == hold.id }
        }
        return last
    }

    /// Bridge once per ISO week. Spends twice `pages` and closes the oldest gap,
    /// or writes a HollowMark when no gap is open.
    @discardableResult
    mutating func bridge(pages: Int, on day: Int, calendar: Calendar = .current) throws -> BridgeOutcome {
        guard pages > 0 else { throw ContourRefusal.invalidPages }
        guard let index = holds.firstIndex(where: { $0.phase == .active }) else {
            throw ContourRefusal.noActiveHold
        }
        let holdID = holds[index].id
        let week = SurveyDay.isoWeek(stamp: day, calendar: calendar)
        let used = bridgeMarks.contains { $0.holdID == holdID && $0.isoWeek == week }
            || hollowMarks.contains { $0.holdID == holdID && $0.isoWeek == week }
        if used { throw ContourRefusal.bridgeAlreadyUsed }
        let product = pages.multipliedReportingOverflow(by: 2)
        guard !product.overflow else { throw ContourRefusal.invalidPages }
        let spent = product.partialValue
        _ = try writePages(spent, on: day, holdIndex: index, kind: .bridge)
        let open = gapSegments
            .filter { $0.holdID == holdID && !$0.closed }
            .sorted { $0.day < $1.day }
        if let oldest = open.first, let gapIndex = gapSegments.firstIndex(where: { $0.id == oldest.id }) {
            gapSegments[gapIndex].closed = true
            let mark = BridgeMark(
                id: UUID(),
                holdID: holdID,
                day: day,
                isoWeek: week,
                pagesSpent: spent,
                closedGapID: oldest.id
            )
            bridgeMarks.append(mark)
            return .closed(mark)
        }
        let hollow = HollowMark(id: UUID(), holdID: holdID, day: day, isoWeek: week, pagesSpent: spent)
        hollowMarks.append(hollow)
        return .hollow(hollow)
    }

    /// When more than three gaps are open, push the summit day and close the extras
    /// so Pin is allowed again.
    @discardableResult
    mutating func recenter(on day: Int, calendar: Calendar = .current) throws -> RecenterMark {
        guard let index = holds.firstIndex(where: { $0.phase == .active }) else {
            throw ContourRefusal.noActiveHold
        }
        let holdID = holds[index].id
        let open = openGapCount(holdID: holdID)
        guard open > 3 else { throw ContourRefusal.recenterNotNeeded }
        let previous = holds[index].plannedSummitDay
        let pushed = SurveyDay.adding(days: open, to: previous, calendar: calendar)
        holds[index].plannedSummitDay = max(pushed, day)
        var extras = gapSegments
            .filter { $0.holdID == holdID && !$0.closed }
            .sorted { $0.day < $1.day }
        let overflow = extras.count - 3
        if overflow > 0 {
            extras = Array(extras.prefix(overflow))
            let closing = Set(extras.map(\.id))
            for gapIndex in gapSegments.indices where closing.contains(gapSegments[gapIndex].id) {
                gapSegments[gapIndex].closed = true
            }
        }
        let mark = RecenterMark(
            id: UUID(),
            holdID: holdID,
            day: day,
            previousSummitDay: previous,
            plannedSummitDay: holds[index].plannedSummitDay
        )
        recenterMarks.append(mark)
        return mark
    }

    func driftAngle(for holdID: UUID, on day: Int, calendar: Calendar = .current) -> Double {
        guard let hold = holds.first(where: { $0.id == holdID }) else { return 0 }
        let lastEnd = trigMarks.last { $0.holdID == holdID }?.endPage ?? 0
        let elapsed = max(0, SurveyDay.span(from: hold.openedDay, to: day, calendar: calendar))
        let planned = max(0, SurveyDay.span(from: hold.openedDay, to: hold.plannedSummitDay, calendar: calendar))
        let progress = ProfileDrift.progress(elapsedDays: elapsed, plannedSpanDays: planned)
        return ProfileDrift.driftAngle(
            lastEndPage: Double(lastEnd),
            totalPages: Double(hold.totalPages),
            progress: progress
        )
    }

    mutating func remember(_ record: MoorRecord) {
        if let index = moorings.firstIndex(where: { $0.isbn == record.isbn && !record.isbn.isEmpty }) {
            moorings[index] = record
            return
        }
        if let index = moorings.firstIndex(where: { $0.id == record.id }) {
            moorings[index] = record
            return
        }
        moorings.append(record)
    }

    func localMoorings(matching query: String) -> [MoorRecord] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return moorings }
        return moorings.filter { record in
            record.title.localizedCaseInsensitiveContains(needle)
                || record.isbn.localizedCaseInsensitiveContains(needle)
                || record.author.localizedCaseInsensitiveContains(needle)
        }
    }

    private enum PageKind {
        case pin
        case bridge
    }

    private mutating func writePages(_ pages: Int, on day: Int, holdIndex: Int, kind: PageKind) throws -> TrigMark {
        let holdID = holds[holdIndex].id
        let total = holds[holdIndex].totalPages
        guard total > 0 else { throw ContourRefusal.invalidPages }
        let before = spentPages(holdID: holdID)
        let after = before + pages
        if kind == .pin {
            let end = (trigMarks.last { $0.holdID == holdID }?.endPage ?? 0) + pages
            let mark = TrigMark(id: UUID(), holdID: holdID, day: day, pages: pages, endPage: end)
            trigMarks.append(mark)
            applyProgress(holdIndex: holdIndex)
            spawnBenchmarks(holdID: holdID, day: day, before: before, after: after, total: total)
            return mark
        }
        applyProgress(holdIndex: holdIndex, extraBridgePages: pages)
        spawnBenchmarks(holdID: holdID, day: day, before: before, after: after, total: total)
        let end = (trigMarks.last { $0.holdID == holdID }?.endPage ?? 0)
        return TrigMark(id: UUID(), holdID: holdID, day: day, pages: pages, endPage: end)
    }

    private mutating func applyProgress(holdIndex: Int, extraBridgePages: Int = 0) {
        let holdID = holds[holdIndex].id
        let total = holds[holdIndex].totalPages
        let pages = spentPages(holdID: holdID) + extraBridgePages
        if total <= 0 {
            holds[holdIndex].profileX = 0
            return
        }
        let fraction = min(1, Double(pages) / Double(total))
        holds[holdIndex].profileX = fraction
        if fraction >= 1 {
            holds[holdIndex].phase = .summited
        } else if holds[holdIndex].phase == .summited {
            holds[holdIndex].phase = .active
        }
    }

    private func spentPages(holdID: UUID) -> Int {
        let pinned = trigMarks.filter { $0.holdID == holdID }.reduce(0) { $0 + $1.pages }
        let bridged = bridgeMarks.filter { $0.holdID == holdID }.reduce(0) { $0 + $1.pagesSpent }
        let hollow = hollowMarks.filter { $0.holdID == holdID }.reduce(0) { $0 + $1.pagesSpent }
        return pinned + bridged + hollow
    }

    private mutating func spawnBenchmarks(holdID: UUID, day: Int, before: Int, after: Int, total: Int) {
        let owned = Set(benchmarks.filter { $0.holdID == holdID }.map(\.band))
        for band in 1...10 {
            let earnedBefore = Self.bandIsEarned(band, pages: before, total: total)
            let earnedAfter = Self.bandIsEarned(band, pages: after, total: total)
            if earnedAfter && !earnedBefore && !owned.contains(band) {
                benchmarks.append(Benchmark(id: UUID(), holdID: holdID, day: day, band: band))
            }
        }
    }

    private static func bandIsEarned(_ band: Int, pages: Int, total: Int) -> Bool {
        guard total > 0, band >= 1, band <= 10 else { return false }
        return pages * 10 >= band * total
    }
}

enum BridgeOutcome: Sendable, Equatable {
    case closed(BridgeMark)
    case hollow(HollowMark)
}

enum ContourRefusal: Error, Equatable, Sendable {
    case invalidPages
    case missingHold
    case secondOpen
    case pinOnPacked
    case noActiveHold
    case gapsBlockPin
    case nothingToPeel
    case bridgeAlreadyUsed
    case recenterNotNeeded
}
