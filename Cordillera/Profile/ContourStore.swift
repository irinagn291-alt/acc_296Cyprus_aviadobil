import Foundation

/// The seam between the contour fold and persistence. The in-memory chart is
/// the source of truth. UserDefaults holds one JSON document under `cdr.contour.v1`,
/// with the previous good JSON beside that key. The same bytes are projected
/// atomically to Application Support. The UI never reads the defaults key itself.
actor ContourStore {
    static let storageKey = "cdr.contour.v1"
    static let backupKey = "cdr.contour.v1.backup"

    private let defaults: UserDefaults
    private let folder: URL
    private var chart: ContourChart
    private var saveTask: Task<Void, Never>?
    private var loaded = false
    private(set) var recoveryNote: String?

    init(defaults: UserDefaults, folder: URL) {
        self.defaults = defaults
        self.folder = folder
        self.chart = .bare
    }

    init() {
        let defaults = UserDefaults.standard
        let folder = ContourStore.supportFolder()
        self.init(defaults: defaults, folder: folder)
    }

    func snapshot() -> ContourChart {
        ensureLoaded()
        return chart
    }

    func moor(title: String, isbn: String, totalPages: Int, on day: Int) throws -> Hold {
        ensureLoaded()
        let hold = try chart.moor(title: title, isbn: isbn, totalPages: totalPages, on: day)
        scheduleSave()
        return hold
    }

    func open(holdID: UUID, on day: Int, plannedSummitDay: Int) throws -> Traverse {
        ensureLoaded()
        let traverse = try chart.open(holdID: holdID, on: day, plannedSummitDay: plannedSummitDay)
        scheduleSave()
        return traverse
    }

    func pin(pages: Int, on day: Int, calendar: Calendar = .current) throws -> TrigMark {
        ensureLoaded()
        do {
            let mark = try chart.pin(pages: pages, on: day, calendar: calendar)
            scheduleSave()
            return mark
        } catch {
            scheduleSave()
            throw error
        }
    }

    func peel() throws -> TrigMark {
        ensureLoaded()
        let mark = try chart.peel()
        scheduleSave()
        return mark
    }

    func bridge(pages: Int, on day: Int, calendar: Calendar = .current) throws -> BridgeOutcome {
        ensureLoaded()
        let outcome = try chart.bridge(pages: pages, on: day, calendar: calendar)
        scheduleSave()
        return outcome
    }

    func recenter(on day: Int, calendar: Calendar = .current) throws -> RecenterMark {
        ensureLoaded()
        let mark = try chart.recenter(on: day, calendar: calendar)
        scheduleSave()
        return mark
    }

    func remember(_ record: MoorRecord) {
        ensureLoaded()
        chart.remember(record)
        scheduleSave()
    }

    /// Search the network, then the local mooring cache. A failure still returns shelf matches.
    func search(query: String, client: OpenLibraryClient) async -> [MoorRecord] {
        ensureLoaded()
        do {
            let found = try await client.searchTitles(query)
            for record in found {
                chart.remember(record)
            }
            scheduleSave()
            return found
        } catch is CancellationError {
            return chart.localMoorings(matching: query)
        } catch {
            return chart.localMoorings(matching: query)
        }
    }

    func resolveISBN(_ isbn: String, client: OpenLibraryClient) async throws -> MoorRecord {
        ensureLoaded()
        do {
            let record = try await client.resolveISBN(isbn)
            chart.remember(record)
            scheduleSave()
            return record
        } catch OpenLibraryError.notFound {
            if let cached = chart.moorings.first(where: { $0.isbn == isbn.filter(\.isNumber) || $0.isbn == isbn }) {
                return cached
            }
            throw OpenLibraryError.notFound
        } catch {
            if let cached = chart.localMoorings(matching: isbn).first {
                return cached
            }
            throw error
        }
    }

    deinit {
        saveTask?.cancel()
    }

    /// Owned debounce task. Replaced on the next mark so rapid pins collapse to one write.
    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(350))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            writeProjection()
        }
    }

    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        ensureLoaded()
        writeProjection()
    }

    /// Removes the defaults key, its backup, and the file projection immediately.
    func resetAllData() {
        saveTask?.cancel()
        saveTask = nil
        chart = .bare
        recoveryNote = nil
        loaded = true
        defaults.removeObject(forKey: Self.storageKey)
        defaults.removeObject(forKey: Self.backupKey)
        let file = folder.appendingPathComponent("contour.json")
        let backup = file.appendingPathExtension("backup")
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }
            if FileManager.default.fileExists(atPath: backup.path) {
                try FileManager.default.removeItem(at: backup)
            }
        } catch {
            recoveryNote = "The contour file could not be removed. The in-memory pack is bare."
        }
    }

    private func ensureLoaded() {
        guard !loaded else { return }
        loaded = true
        switch Self.read(defaults: defaults, folder: folder) {
        case .restored(let chart):
            self.chart = chart
        case .recovered(let chart, let note):
            self.chart = chart
            self.recoveryNote = note
        case .bare(let note):
            self.chart = .bare
            self.recoveryNote = note
        }
    }

    private func writeProjection() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(chart) else {
            recoveryNote = "The contour could not be encoded. The screen still shows the open pack."
            return
        }
        if let previous = defaults.data(forKey: Self.storageKey) {
            defaults.set(previous, forKey: Self.backupKey)
        }
        defaults.set(data, forKey: Self.storageKey)
        do {
            try Self.writeAtomically(data, folder: folder)
        } catch {
            recoveryNote = "The contour file could not be saved. The screen still shows the open pack."
        }
    }

    private static func supportFolder() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return (base ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("Aviadobil", isDirectory: true)
    }

    private static func read(defaults: UserDefaults, folder: URL) -> LoadResult {
        if let data = defaults.data(forKey: storageKey), let chart = decode(data) {
            return .restored(chart)
        }
        if defaults.data(forKey: storageKey) != nil {
            if let backup = defaults.data(forKey: backupKey), let chart = decode(backup) {
                return .recovered(chart, "The latest contour was unreadable. The previous contour is restored.")
            }
        }
        let file = folder.appendingPathComponent("contour.json")
        if let data = try? Data(contentsOf: file), let chart = decode(data) {
            return .recovered(chart, "The saved contour was restored from the file copy.")
        }
        let backupFile = file.appendingPathExtension("backup")
        if let data = try? Data(contentsOf: backupFile), let chart = decode(data) {
            return .recovered(chart, "The contour file was unreadable. The previous file is restored.")
        }
        if defaults.data(forKey: storageKey) != nil || fileExists(file) {
            return .bare("The saved contour could not be read. A bare pack is ready.")
        }
        return .restored(.bare)
    }

    private static func decode(_ data: Data) -> ContourChart? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return try? decoder.decode(ContourChart.self, from: data)
    }

    private static func writeAtomically(_ data: Data, folder: URL) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        var cacheExcluded = URLResourceValues()
        cacheExcluded.isExcludedFromBackup = true
        if let caches = manager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let cacheFolder = caches.appendingPathComponent("Aviadobil", isDirectory: true)
            try manager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
            var cacheURL = cacheFolder
            try cacheURL.setResourceValues(cacheExcluded)
        }
        let file = folder.appendingPathComponent("contour.json")
        let backup = file.appendingPathExtension("backup")
        if manager.fileExists(atPath: file.path) {
            if manager.fileExists(atPath: backup.path) {
                try manager.removeItem(at: backup)
            }
            try manager.copyItem(at: file, to: backup)
        }
        try data.write(to: file, options: .atomic)
    }

    private static func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    private enum LoadResult {
        case restored(ContourChart)
        case recovered(ContourChart, String)
        case bare(String)
    }
}

enum ContourStoreError: Error, Equatable {
    case unknownSchema(Int)
}
