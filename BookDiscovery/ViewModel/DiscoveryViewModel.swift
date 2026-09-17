import Combine
import Foundation

@MainActor
final class DiscoveryViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed(message: String)
    }

    @Published private(set) var books: [Book] = []
    @Published private(set) var state: State = .idle
    @Published private(set) var selectedMood: HomeMood
    @Published private(set) var totalResults = 0
    @Published private(set) var isLoadingMore = false
    @Published private(set) var paginationError: String?

    private let service: any BookCatalogService
    private let pageSize: Int
    private var currentPage = 0
    private var loadTask: Task<Void, Never>?

    convenience init(mood: HomeMood) {
        self.init(service: OpenLibraryService(), selectedMood: mood)
    }

    init(
        service: any BookCatalogService,
        selectedMood: HomeMood,
        pageSize: Int = 20
    ) {
        self.service = service
        self.selectedMood = selectedMood
        self.pageSize = pageSize
    }

    var canLoadMore: Bool {
        !books.isEmpty && books.count < totalResults
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await loadFirstPage()
    }

    func select(_ mood: HomeMood) async {
        guard mood != selectedMood else { return }
        selectedMood = mood
        await loadFirstPage()
    }

    func retry() async {
        await loadFirstPage()
    }

    func loadMoreIfNeeded(currentBook: Book) async {
        guard currentBook.id == books.last?.id,
              canLoadMore,
              !isLoadingMore,
              state == .loaded else {
            return
        }

        let mood = selectedMood
        isLoadingMore = true
        paginationError = nil
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let page = try await service.searchBooks(
                query: mood.searchQuery,
                page: nextPage,
                limit: pageSize
            )
            try Task.checkCancellation()
            guard mood == selectedMood else { return }

            let existingIDs = Set(books.map(\.id))
            books.append(contentsOf: page.books.filter { !existingIDs.contains($0.id) })
            currentPage = page.page
            totalResults = page.totalResults
        } catch is CancellationError {
            return
        } catch {
            guard mood == selectedMood else { return }
            paginationError = error.localizedDescription
        }
    }

    private func loadFirstPage() async {
        loadTask?.cancel()
        let mood = selectedMood
        books = []
        currentPage = 0
        totalResults = 0
        isLoadingMore = false
        paginationError = nil
        state = .loading

        let task = Task { [service, pageSize] in
            do {
                let page = try await service.searchBooks(
                    query: mood.searchQuery,
                    page: 1,
                    limit: pageSize
                )
                try Task.checkCancellation()
                guard mood == selectedMood else { return }

                books = page.books
                currentPage = page.page
                totalResults = page.totalResults
                state = page.books.isEmpty ? .empty : .loaded
            } catch is CancellationError {
                return
            } catch {
                guard mood == selectedMood else { return }
                state = .failed(message: error.localizedDescription)
            }
        }

        loadTask = task
        await task.value
    }
}
