import Combine
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed(message: String)
    }

    @Published private(set) var books: [Book] = []
    @Published private(set) var state: State = .idle
    @Published private(set) var isLoadingMore = false
    @Published private(set) var paginationError: String?

    private(set) var currentQuery = ""
    private(set) var totalResults = 0

    private let service: any BookCatalogService
    private let pageSize: Int
    private var currentPage = 0
    private var requestQuery = ""
    private var searchTask: Task<Void, Never>?

    convenience init() {
        self.init(service: OpenLibraryService())
    }

    init(service: any BookCatalogService, pageSize: Int = 20) {
        self.service = service
        self.pageSize = pageSize
    }

    var canLoadMore: Bool {
        !books.isEmpty && books.count < totalResults
    }

    func search(query: String) async {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedQuery.isEmpty else {
            reset()
            return
        }

        if normalizedQuery == currentQuery {
            guard case .failed = state else { return }
        }

        searchTask?.cancel()
        currentQuery = normalizedQuery
        requestQuery = Self.apiQuery(for: normalizedQuery)
        currentPage = 0
        totalResults = 0
        books = []
        paginationError = nil
        state = .loading

        let apiQuery = requestQuery
        let task = Task { [service, pageSize] in
            do {
                let page = try await service.searchBooks(
                    query: apiQuery,
                    page: 1,
                    limit: pageSize
                )
                try Task.checkCancellation()
                guard currentQuery == normalizedQuery else { return }

                books = page.books
                currentPage = page.page
                totalResults = page.totalResults
                state = page.books.isEmpty ? .empty : .loaded
            } catch is CancellationError {
                return
            } catch {
                guard currentQuery == normalizedQuery else { return }
                state = .failed(message: error.localizedDescription)
            }
        }

        searchTask = task
        await task.value
    }

    func retry() async {
        let query = currentQuery
        currentQuery = ""
        await search(query: query)
    }

    func loadMoreIfNeeded(currentBook: Book) async {
        guard currentBook.id == books.last?.id,
              canLoadMore,
              !isLoadingMore,
              state == .loaded else {
            return
        }

        isLoadingMore = true
        paginationError = nil
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let page = try await service.searchBooks(
                query: requestQuery,
                page: nextPage,
                limit: pageSize
            )
            try Task.checkCancellation()

            let existingIDs = Set(books.map(\.id))
            books.append(contentsOf: page.books.filter { !existingIDs.contains($0.id) })
            currentPage = page.page
            totalResults = page.totalResults
        } catch is CancellationError {
            return
        } catch {
            paginationError = error.localizedDescription
        }
    }

    private func reset() {
        searchTask?.cancel()
        currentQuery = ""
        requestQuery = ""
        currentPage = 0
        totalResults = 0
        books = []
        paginationError = nil
        state = .idle
    }

    private static func apiQuery(for query: String) -> String {
        let words = query
            .lowercased()
            .split(whereSeparator: { !$0.isLetter })
            .map(String.init)

        guard !words.isEmpty, words.allSatisfy(stopWords.contains) else {
            return query
        }

        return "title:\(query)"
    }

    private static let stopWords: Set<String> = [
        "a", "an", "and", "are", "as", "at", "be", "but", "by", "for",
        "if", "in", "into", "is", "it", "no", "not", "of", "on", "or",
        "such", "that", "the", "their", "then", "there", "these", "they",
        "this", "to", "was", "will", "with"
    ]
}
