import XCTest
@testable import Cordillera

final class CordilleraTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar = gregorian
    }

    // driftAngle = (lastEndPage/total − progress)×45. profileX is route x.
    func testDriftAngleFamilyInvariant() {
        let progress = ProfileDrift.progress(elapsedDays: 1, plannedSpanDays: 4)
        let angle = ProfileDrift.driftAngle(lastEndPage: 50, totalPages: 100, progress: progress)
        XCTAssertEqual(progress, 0.25, accuracy: 0.0001)
        XCTAssertEqual(angle, 11.25, accuracy: 0.0001)

        var chart = ContourChart.bare
        let hold = try? chart.moor(title: "Ridge", isbn: "9780000000001", totalPages: 100, on: 20260901)
        XCTAssertNotNil(hold)
        _ = try? chart.open(holdID: hold?.id ?? UUID(), on: 20260901, plannedSummitDay: 20260905)
        _ = try? chart.pin(pages: 50, on: 20260902, calendar: calendar)
        let derived = chart.driftAngle(for: hold?.id ?? UUID(), on: 20260902, calendar: calendar)
        XCTAssertEqual(derived, 11.25, accuracy: 0.0001)
        XCTAssertEqual(chart.activeHold?.profileX ?? 0, 0.5, accuracy: 0.0001)
    }

    func testEmptyPackIsBareAndPinOnPackedIsRefused() {
        let chart = ContourChart.bare
        XCTAssertEqual(chart.fold, .bare)
        var packed = chart
        let hold = try? packed.moor(title: "Pack", isbn: "", totalPages: 40, on: 20260901)
        XCTAssertEqual(packed.fold, .packed)
        XCTAssertThrowsError(try packed.pin(pages: 4, on: 20260901, calendar: calendar)) { error in
            XCTAssertEqual(error as? ContourRefusal, .pinOnPacked)
        }
        XCTAssertThrowsError(try packed.moor(title: "Zero", isbn: "", totalPages: 0, on: 20260901)) { error in
            XCTAssertEqual(error as? ContourRefusal, .invalidPages)
        }
        XCTAssertNotNil(hold)
    }

    func testPinAdvancesProfileAndWritesDecileBenchmark() throws {
        var chart = ContourChart.bare
        let hold = try chart.moor(title: "Summit", isbn: "1", totalPages: 100, on: 20260901)
        _ = try chart.open(holdID: hold.id, on: 20260901, plannedSummitDay: 20260920)
        let mark = try chart.pin(pages: 10, on: 20260901, calendar: calendar)
        XCTAssertEqual(mark.pages, 10)
        XCTAssertEqual(mark.endPage, 10)
        XCTAssertEqual(chart.holds[0].profileX, 0.1, accuracy: 0.0001)
        XCTAssertEqual(chart.benchmarks.map(\.band), [1])
        _ = try chart.pin(pages: 15, on: 20260901, calendar: calendar)
        XCTAssertEqual(chart.holds[0].profileX, 0.25, accuracy: 0.0001)
        XCTAssertEqual(chart.benchmarks.map(\.band).sorted(), [1, 2])
    }

    func testTwistGapsBridgeHollowRecenterAndSummit() throws {
        var chart = ContourChart.bare
        let first = try chart.moor(title: "One", isbn: "a", totalPages: 100, on: 20260901)
        let second = try chart.moor(title: "Two", isbn: "b", totalPages: 80, on: 20260901)
        _ = try chart.open(holdID: first.id, on: 20260901, plannedSummitDay: 20260910)
        XCTAssertThrowsError(try chart.open(holdID: second.id, on: 20260902, plannedSummitDay: 20260912)) { error in
            XCTAssertEqual(error as? ContourRefusal, .secondOpen)
        }
        _ = try chart.pin(pages: 10, on: 20260901, calendar: calendar)
        XCTAssertThrowsError(try chart.pin(pages: 5, on: 20260906, calendar: calendar)) { error in
            XCTAssertEqual(error as? ContourRefusal, .gapsBlockPin)
        }
        XCTAssertEqual(chart.openGapCount(holdID: first.id), 4)
        XCTAssertEqual(chart.holds[0].profileX, 0.1, accuracy: 0.0001)

        let closed = try chart.bridge(pages: 5, on: 20260907, calendar: calendar)
        guard case .closed(let bridge) = closed else {
            XCTFail("Expected a gap to close")
            return
        }
        XCTAssertEqual(bridge.pagesSpent, 10)
        XCTAssertEqual(chart.openGapCount(holdID: first.id), 3)
        XCTAssertEqual(chart.holds[0].profileX, 0.2, accuracy: 0.0001)
        XCTAssertThrowsError(try chart.bridge(pages: 5, on: 20260908, calendar: calendar)) { error in
            XCTAssertEqual(error as? ContourRefusal, .bridgeAlreadyUsed)
        }

        chart.recordGaps(holdID: first.id, through: 20260909, calendar: calendar)
        XCTAssertGreaterThan(chart.openGapCount(holdID: first.id), 3)
        let beforeSummit = chart.holds[0].plannedSummitDay
        let recenter = try chart.recenter(on: 20260907, calendar: calendar)
        XCTAssertGreaterThan(recenter.plannedSummitDay, beforeSummit)
        XCTAssertEqual(chart.openGapCount(holdID: first.id), 3)
        _ = try chart.pin(pages: 80, on: 20260907, calendar: calendar)
        XCTAssertEqual(chart.holds[0].phase, .summited)
        XCTAssertEqual(chart.holds[0].profileX, 1, accuracy: 0.0001)
        XCTAssertEqual(chart.fold, .packed)
        XCTAssertEqual(SummitRegistry.make(from: chart).entries.count, 1)

        _ = try chart.open(holdID: second.id, on: 20260908, plannedSummitDay: 20260920)
        let hollow = try chart.bridge(pages: 4, on: 20260908, calendar: calendar)
        guard case .hollow(let mark) = hollow else {
            XCTFail("Expected a hollow bridge")
            return
        }
        XCTAssertEqual(mark.pagesSpent, 8)
        _ = try chart.pin(pages: 4, on: 20260908, calendar: calendar)
        let peeled = try chart.peel()
        XCTAssertEqual(peeled.pages, 4)
        XCTAssertEqual(chart.holds.first { $0.id == second.id }?.phase, .active)
        XCTAssertEqual(chart.trigMarks.filter { $0.holdID == second.id }.count, 0)
    }

    func testArchitectureFoldPackedActiveSummited() throws {
        var chart = ContourChart.bare
        XCTAssertEqual(chart.fold, .bare)
        let hold = try chart.moor(title: "Fold", isbn: "", totalPages: 20, on: 20260101)
        XCTAssertEqual(chart.fold, .packed)
        _ = try chart.open(holdID: hold.id, on: 20260101, plannedSummitDay: 20260108)
        XCTAssertEqual(chart.fold, .active)
        XCTAssertEqual(chart.traverses.count, 1)
        XCTAssertEqual(chart.traverses[0].summitPages, 20)
        _ = try chart.pin(pages: 20, on: 20260101, calendar: calendar)
        XCTAssertEqual(chart.fold, .summited)
        XCTAssertEqual(chart.benchmarks.map(\.band).sorted(), Array(1...10))
        let removed = try chart.peel()
        XCTAssertEqual(removed.pages, 20)
        XCTAssertEqual(chart.fold, .packed)
        XCTAssertTrue(chart.traverses.isEmpty)
    }

    func testPersistenceRoundTripAndCorruptRecovery() async throws {
        let suiteName = "cordillera-" + UUID().uuidString
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            UserDefaults().removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: folder)
        }
        func suite() throws -> UserDefaults {
            try XCTUnwrap(UserDefaults(suiteName: suiteName))
        }
        let store = ContourStore(defaults: try suite(), folder: folder)
        let hold = try await store.moor(title: "Saved", isbn: "999", totalPages: 50, on: 20260901)
        _ = try await store.open(holdID: hold.id, on: 20260901, plannedSummitDay: 20260911)
        _ = try await store.pin(pages: 5, on: 20260901, calendar: calendar)
        await store.flush()

        let reloaded = ContourStore(defaults: try suite(), folder: folder)
        let snap = await reloaded.snapshot()
        XCTAssertEqual(snap.trigMarks.count, 1)
        XCTAssertEqual(snap.holds.first?.profileX ?? 0, 0.1, accuracy: 0.0001)
        XCTAssertEqual(snap.schemaVersion, 1)
        let file = folder.appendingPathComponent("contour.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))

        try suite().set(Data("not-json".utf8), forKey: ContourStore.storageKey)
        let recovered = ContourStore(defaults: try suite(), folder: folder)
        let restored = await recovered.snapshot()
        XCTAssertEqual(restored.trigMarks.count, 1)
        let note = await recovered.recoveryNote
        XCTAssertNotNil(note)

        try suite().set(Data("still-bad".utf8), forKey: ContourStore.storageKey)
        try suite().set(Data("also-bad".utf8), forKey: ContourStore.backupKey)
        try Data("nope".utf8).write(to: file, options: .atomic)
        let backup = file.appendingPathExtension("backup")
        if FileManager.default.fileExists(atPath: backup.path) {
            try Data("nope".utf8).write(to: backup, options: .atomic)
        }
        let bare = ContourStore(defaults: try suite(), folder: folder)
        let empty = await bare.snapshot()
        XCTAssertEqual(empty.fold, .bare)
        let bareNote = await bare.recoveryNote
        XCTAssertNotNil(bareNote)

        await bare.resetAllData()
        XCTAssertNil(try suite().data(forKey: ContourStore.storageKey))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    func testReviewLaunchParsesScreenArgument() {
        XCTAssertEqual(ReviewLaunch.screen(in: ["Cordillera", "-ReviewScreen", "today"]), "today")
        XCTAssertEqual(ReviewLaunch.screen(in: ["Cordillera", "-ReviewScreen", "log"]), "log")
        XCTAssertEqual(ReviewLaunch.screen(in: ["Cordillera", "-ReviewScreen", "goals"]), "goals")
        XCTAssertEqual(ReviewLaunch.screen(in: ["Cordillera", "-ReviewScreen", "pack"]), "pack")
        XCTAssertNil(ReviewLaunch.screen(in: ["Cordillera"]))
        XCTAssertNil(ReviewLaunch.screen(in: ["Cordillera", "-ReviewScreen"]))
        XCTAssertNil(ReviewLaunch.screen(in: ["Cordillera", "-ReviewScreen", "-Other"]))
    }

    func testOpenLibraryDecodesNumberOrStringAndStatusZero() async throws {
        let client = OpenLibraryClient { request in
            let path = request.url?.path ?? ""
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), OpenLibraryClient.userAgent)
            if path.contains("search.json") {
                let body = #"{"docs":[{"title":"Cairn","author_name":["Survey"],"isbn":["9781"],"number_of_pages_median":"240"}],"status":1}"#
                return (Data(body.utf8), 200)
            }
            let body = #"{"title":"Bolt","number_of_pages":128,"publishers":["Press"]}"#
            return (Data(body.utf8), 200)
        }
        let found = try await client.searchTitles("cairn")
        XCTAssertEqual(found.first?.pageCount, 240)
        XCTAssertEqual(found.first?.title, "Cairn")
        let isbn = try await client.resolveISBN("9781")
        XCTAssertEqual(isbn.pageCount, 128)

        let missing = OpenLibraryClient { _ in
            (Data(#"{"status":0,"title":""}"#.utf8), 200)
        }
        do {
            _ = try await missing.resolveISBN("000")
            XCTFail("Expected not found")
        } catch OpenLibraryError.notFound {
        } catch {
            XCTFail("Unexpected \(error)")
        }

        let broken = OpenLibraryClient { _ in (Data("{".utf8), 200) }
        do {
            _ = try await broken.searchTitles("x")
            XCTFail("Expected decode")
        } catch OpenLibraryError.decode {
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testSearchDoesNotRetryNotFoundAndRetriesTransportOnce() async {
        let attempts = AttemptBox()
        let client = OpenLibraryClient { _ in
            let count = await attempts.add()
            if count == 1 { throw URLError(.timedOut) }
            return (Data(#"{"docs":[]}"#.utf8), 200)
        }
        let rows = try? await client.searchTitles("ridge")
        XCTAssertEqual(rows?.count, 0)
        let total = await attempts.value()
        XCTAssertEqual(total, 2)

        let missing = OpenLibraryClient { _ in (Data("{}".utf8), 404) }
        do {
            _ = try await missing.searchTitles("gone")
            XCTFail("Expected not found")
        } catch OpenLibraryError.notFound {
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testUPCAPadsToEANAndQRRunsStayIntact() {
        XCTAssertEqual(ISBNCapture.isbnDigits(from: "012345678905"), "0012345678905")
        XCTAssertEqual(ISBNCapture.isbnDigits(from: "9780141185381"), "9780141185381")
        XCTAssertEqual(ISBNCapture.isbnDigits(from: "https://openlibrary.org/isbn/9780141185381"), "9780141185381")
        XCTAssertEqual(ISBNCapture.isbnDigits(from: "pack 12345678 and 9780140255089"), "9780140255089")
        XCTAssertNil(ISBNCapture.isbnDigits(from: "12345"))
    }

    func testReplacingTheQueryCancelsThePreviousSearch() async {
        let gate = QueryGate()
        let client = OpenLibraryClient { request in
            let query = URLComponents(url: request.url ?? URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false)?
                .queryItems?
                .first { $0.name == "q" }?
                .value ?? ""
            try await gate.wait(query)
            let body = #"{"docs":[{"title":"\#(query)","number_of_pages_median":12}]}"#
            return (Data(body.utf8), 200)
        }
        let search = TitleSearch(client: client, debounce: .milliseconds(20))
        let first = Task { try await search.replaceQuery("alpha") }
        try? await Task.sleep(for: .milliseconds(30))
        let second = try? await search.replaceQuery("beta")
        let firstResult = await first.result
        XCTAssertEqual(second?.first?.title, "beta")
        if case .failure = firstResult {
        } else {
            XCTFail("Stale search should have been cancelled")
        }
    }
}

private actor AttemptBox {
    private var count = 0
    func add() -> Int {
        count += 1
        return count
    }
    func value() -> Int { count }
}

private actor QueryGate {
    func wait(_ query: String) async throws {
        if query == "alpha" {
            try await Task.sleep(for: .milliseconds(400))
        }
    }
}
