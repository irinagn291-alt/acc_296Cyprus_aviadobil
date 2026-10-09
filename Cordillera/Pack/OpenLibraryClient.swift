import Foundation

/// One client owns both Open Library endpoints: search.json and the ISBN record.
/// Requests identify this app. A missing page count is a normal draft, not an error.
struct OpenLibraryClient: Sendable {
    static let userAgent = "Cordillera/1.0 (iOS; +https://cordillera-profile.pro)"
    static let timeout: TimeInterval = 15

    var fetch: @Sendable (URLRequest) async throws -> (Data, Int)

    static func live(session: URLSession = OpenLibraryClient.makeSession()) -> OpenLibraryClient {
        OpenLibraryClient { request in
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw OpenLibraryError.transport
            }
            return (data, http.statusCode)
        }
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }

    func searchTitles(_ query: String) async throws -> [MoorRecord] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var parts = URLComponents(string: "https://openlibrary.org/search.json")
        parts?.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "limit", value: "20"),
        ]
        guard let url = parts?.url else { throw OpenLibraryError.decode }
        let data = try await load(url)
        let dto = try decode(SearchEnvelope.self, from: data)
        if dto.status == 0 { throw OpenLibraryError.notFound }
        return (dto.docs ?? []).map { doc in
            MoorRecord(
                id: UUID(),
                isbn: doc.isbn?.first ?? "",
                title: doc.title ?? "",
                author: doc.author_name?.first ?? "",
                pageCount: doc.number_of_pages_median?.value
            )
        }
    }

    func resolveISBN(_ isbn: String) async throws -> MoorRecord {
        let digits = isbn.filter { $0.isNumber || $0 == "X" || $0 == "x" }
        guard !digits.isEmpty else { throw OpenLibraryError.notFound }
        guard let url = URL(string: "https://openlibrary.org/isbn/\(digits).json") else {
            throw OpenLibraryError.notFound
        }
        let data = try await load(url)
        let dto = try decode(ISBNEnvelope.self, from: data)
        if dto.status == 0 { throw OpenLibraryError.notFound }
        let title = dto.title ?? ""
        if title.isEmpty { throw OpenLibraryError.notFound }
        return MoorRecord(
            id: UUID(),
            isbn: digits,
            title: title,
            author: dto.publishers?.first ?? "",
            pageCount: dto.number_of_pages?.value
        )
    }

    private func load(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = Self.timeout
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            return try await send(request, allowRetry: true)
        } catch is CancellationError {
            throw OpenLibraryError.cancelled
        }
    }

    private func send(_ request: URLRequest, allowRetry: Bool) async throws -> Data {
        do {
            let (data, status) = try await fetch(request)
            if status == 404 { throw OpenLibraryError.notFound }
            if status == 0 { throw OpenLibraryError.notFound }
            if status >= 500 || status == 408 || status == 429 {
                throw OpenLibraryError.transport
            }
            if !(200...299).contains(status) {
                throw OpenLibraryError.badStatus(status)
            }
            return data
        } catch let error as OpenLibraryError {
            if case .notFound = error { throw error }
            if case .badStatus = error { throw error }
            if allowRetry, case .transport = error {
                return try await send(request, allowRetry: false)
            }
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch is URLError {
            if allowRetry {
                return try await send(request, allowRetry: false)
            }
            throw OpenLibraryError.transport
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw OpenLibraryError.decode
        }
    }
}

enum OpenLibraryError: Error, Equatable, Sendable {
    case notFound
    case transport
    case decode
    case badStatus(Int)
    case cancelled
}

/// Accepts a JSON number or a numeric string. A missing or blank value stays nil.
struct FlexCount: Decodable, Sendable, Equatable {
    var value: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let whole = try? container.decode(Int.self) {
            value = whole
            return
        }
        if let fraction = try? container.decode(Double.self) {
            value = Int(fraction)
            return
        }
        if let text = try? container.decode(String.self) {
            let digits = text.filter(\.isNumber)
            value = digits.isEmpty ? nil : Int(digits)
            return
        }
        value = nil
    }
}

struct SearchEnvelope: Decodable, Sendable {
    var status: Int?
    var docs: [SearchDoc]?
}

struct SearchDoc: Decodable, Sendable {
    var title: String?
    var isbn: [String]?
    var author_name: [String]?
    var number_of_pages_median: FlexCount?
}

struct ISBNEnvelope: Decodable, Sendable {
    var status: Int?
    var title: String?
    var number_of_pages: FlexCount?
    var publishers: [String]?
}
