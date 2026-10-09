import Foundation

/// Debounces title search by about 300ms and cancels the previous query so a
/// stale Open Library response cannot replace a newer one.
actor TitleSearch {
    private let client: OpenLibraryClient
    private let debounce: Duration
    private var task: Task<[MoorRecord], Error>?

    init(client: OpenLibraryClient, debounce: Duration = .milliseconds(300)) {
        self.client = client
        self.debounce = debounce
    }

    func replaceQuery(_ query: String) async throws -> [MoorRecord] {
        task?.cancel()
        let client = client
        let debounce = debounce
        let task = Task<[MoorRecord], Error> {
            try await Task.sleep(for: debounce)
            try Task.checkCancellation()
            return try await client.searchTitles(query)
        }
        self.task = task
        return try await task.value
    }
}
