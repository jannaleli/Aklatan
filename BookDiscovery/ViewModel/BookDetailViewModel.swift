import Combine
import Foundation

@MainActor
final class BookDetailViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(message: String)
    }

    let book: Book
    @Published private(set) var details: BookWorkDetails?
    @Published private(set) var state: State = .idle

    private let service: any BookCatalogService

    convenience init(book: Book) {
        self.init(book: book, service: OpenLibraryService())
    }

    init(book: Book, service: any BookCatalogService) {
        self.book = book
        self.service = service
    }

    var displayBook: Book {
        Book(
            id: book.id,
            title: details?.title ?? book.title,
            authors: book.authors,
            firstPublishYear: book.firstPublishYear,
            editionCount: book.editionCount,
            subjects: details?.subjects ?? book.subjects,
            coverURL: details?.coverURL ?? book.coverURL,
            color: book.color,
            progress: book.progress
        )
    }

    var description: String? {
        details?.description?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var primarySubject: String {
        (details?.subjects.first ?? book.subjects.first) ?? "Unknown"
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func retry() async {
        await load()
    }

    private func load() async {
        guard book.id.hasPrefix("/works/") else {
            state = .loaded
            return
        }

        state = .loading
        do {
            details = try await service.workDetails(id: book.id)
            state = .loaded
        } catch is CancellationError {
            return
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
