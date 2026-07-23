import Foundation

protocol BookCatalogService {
    func searchBooks(query: String, page: Int, limit: Int) async throws -> BookSearchPage
    func workDetails(id: String) async throws -> BookWorkDetails
}

struct OpenLibraryService: BookCatalogService {
    private let client: any HTTPClient
    private let configuration: OpenLibraryConfiguration

    init(
        client: any HTTPClient = URLSessionHTTPClient(),
        configuration: OpenLibraryConfiguration = .production
    ) {
        self.client = client
        self.configuration = configuration
    }

    func searchBooks(query: String, page: Int = 1, limit: Int = 20) async throws -> BookSearchPage {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return BookSearchPage(books: [], page: 1, totalResults: 0) }

        let request = try OpenLibraryEndpoint.search(query: trimmedQuery, page: page, limit: limit)
            .request(configuration: configuration)
        let response: OpenLibrarySearchResponseDTO = try await client.send(request)
        return BookSearchPage(
            books: response.docs.map { $0.toDomain(configuration: configuration) },
            page: max(1, page),
            totalResults: response.numFound
        )
    }

    func workDetails(id: String) async throws -> BookWorkDetails {
        let normalizedID = id.replacingOccurrences(of: "/works/", with: "")
        let request = try OpenLibraryEndpoint.work(id: normalizedID).request(configuration: configuration)
        let response: OpenLibraryWorkDTO = try await client.send(request)
        return BookWorkDetails(
            id: response.key,
            title: response.title,
            description: response.description?.value,
            subjects: response.subjects ?? [],
            coverURL: response.covers?.first.flatMap { configuration.coverURL(id: $0, size: .large) }
        )
    }
}

private extension OpenLibraryBookDTO {
    func toDomain(configuration: OpenLibraryConfiguration) -> Book {
        Book(
            id: key,
            title: title,
            authors: authorNames ?? [],
            firstPublishYear: firstPublishYear,
            editionCount: editionCount ?? 0,
            subjects: subjects ?? [],
            coverURL: coverID.flatMap { configuration.coverURL(id: $0, size: .medium) }
        )
    }
}

extension OpenLibraryConfiguration {
    enum CoverSize: String { case small = "S", medium = "M", large = "L" }

    func coverURL(id: Int, size: CoverSize) -> URL? {
        URL(string: "b/id/\(id)-\(size.rawValue).jpg?default=false", relativeTo: coversBaseURL)?.absoluteURL
    }
}
