import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
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

    private let service: any BookCatalogService
    private let pageSize: Int
    private var loadTask: Task<Void, Never>?

    convenience init() {
        self.init(service: OpenLibraryService())
    }

    init(
        service: any BookCatalogService,
        selectedMood: HomeMood = .fiction,
        pageSize: Int = 12
    ) {
        self.service = service
        self.selectedMood = selectedMood
        self.pageSize = pageSize
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await loadSelectedMood()
    }

    func select(_ mood: HomeMood) async {
        guard mood != selectedMood else { return }
        selectedMood = mood
        await loadSelectedMood()
    }

    func retry() async {
        await loadSelectedMood()
    }

    private func loadSelectedMood() async {
        loadTask?.cancel()
        let mood = selectedMood
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
                state = page.books.isEmpty ? .empty : .loaded
            } catch is CancellationError {
                return
            } catch {
                guard mood == selectedMood else { return }
                books = []
                state = .failed(message: error.localizedDescription)
            }
        }

        loadTask = task
        await task.value
    }
}
