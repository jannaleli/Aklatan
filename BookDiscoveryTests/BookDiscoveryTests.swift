//
//  BookDiscoveryTests.swift
//  BookDiscoveryTests
//
//  Created by Jann Aleli Zaplan on 2026-07-20.
//

import Foundation
import Testing
@testable import BookDiscovery

struct BookDiscoveryTests {
    @Test @MainActor
    func homepageLoadsBooksForDefaultMood() async {
        let book = Book(id: "/works/OL1W", title: "A Test Book", authors: ["A. Writer"])
        let service = BookCatalogServiceStub(results: [.success(Self.page(with: [book]))])
        let viewModel = HomeViewModel(service: service)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == HomeViewModel.State.loaded)
        #expect(viewModel.books == [book])
        #expect(await service.queries == ["subject:fiction"])
    }

    @Test @MainActor
    func homepageReportsEmptyResults() async {
        let service = BookCatalogServiceStub(results: [.success(Self.page(with: []))])
        let viewModel = HomeViewModel(service: service)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == HomeViewModel.State.empty)
        #expect(viewModel.books.isEmpty)
    }

    @Test @MainActor
    func selectingMoodLoadsItsQuery() async {
        let service = BookCatalogServiceStub(results: [.success(Self.page(with: []))])
        let viewModel = HomeViewModel(service: service)

        await viewModel.select(HomeMood.mystery)

        #expect(viewModel.selectedMood == HomeMood.mystery)
        #expect(await service.queries == ["subject:mystery"])
    }

    @Test @MainActor
    func retryRecoversAfterFailure() async {
        let book = Book(id: "/works/OL2W", title: "Recovered")
        let service = BookCatalogServiceStub(results: [
            .failure(TestError.offline),
            .success(Self.page(with: [book]))
        ])
        let viewModel = HomeViewModel(service: service)

        await viewModel.loadIfNeeded()
        guard case .failed = viewModel.state else {
            Issue.record("Expected the first request to fail")
            return
        }

        await viewModel.retry()

        #expect(viewModel.state == HomeViewModel.State.loaded)
        #expect(viewModel.books == [book])
        #expect(await service.queries.count == 2)
    }

    @Test @MainActor
    func detailLoadsWorkDescriptionAndLargeCover() async {
        let book = Book(id: "/works/OL3W", title: "Search Title", authors: ["B. Author"])
        let coverURL = URL(string: "https://covers.example/large.jpg")!
        let details = BookWorkDetails(
            id: book.id,
            title: "Canonical Title",
            description: "A real description.",
            subjects: ["Fantasy"],
            coverURL: coverURL
        )
        let service = BookCatalogServiceStub(
            results: [],
            workResults: [.success(details)]
        )
        let viewModel = BookDetailViewModel(book: book, service: service)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == BookDetailViewModel.State.loaded)
        #expect(viewModel.description == "A real description.")
        #expect(viewModel.displayBook.title == "Canonical Title")
        #expect(viewModel.displayBook.coverURL == coverURL)
        #expect(await service.workIDs == [book.id])
    }

    @Test @MainActor
    func localDetailDoesNotMakeNetworkRequest() async {
        let service = BookCatalogServiceStub(results: [])
        let viewModel = BookDetailViewModel(book: Book.longWay, service: service)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == BookDetailViewModel.State.loaded)
        #expect(await service.workIDs.isEmpty)
    }

    @Test @MainActor
    func searchLoadsMatchingBooks() async {
        let book = Book(id: "/works/OL4W", title: "The Swift Book")
        let service = BookCatalogServiceStub(results: [
            .success(BookSearchPage(books: [book], page: 1, totalResults: 1))
        ])
        let viewModel = SearchViewModel(service: service)

        await viewModel.search(query: "  swift  ")

        #expect(viewModel.state == SearchViewModel.State.loaded)
        #expect(viewModel.books == [book])
        #expect(viewModel.currentQuery == "swift")
        #expect(await service.requests == [
            SearchRequest(query: "swift", page: 1, limit: 20)
        ])
    }

    @Test @MainActor
    func clearingSearchResetsResults() async {
        let book = Book(id: "/works/OL5W", title: "Temporary Result")
        let service = BookCatalogServiceStub(results: [
            .success(BookSearchPage(books: [book], page: 1, totalResults: 1))
        ])
        let viewModel = SearchViewModel(service: service)

        await viewModel.search(query: "temporary")
        await viewModel.search(query: "   ")

        #expect(viewModel.state == SearchViewModel.State.idle)
        #expect(viewModel.books.isEmpty)
        #expect(viewModel.currentQuery.isEmpty)
    }

    @Test @MainActor
    func stopWordOnlySearchUsesTitleQuery() async {
        let service = BookCatalogServiceStub(results: [
            .success(BookSearchPage(books: [], page: 1, totalResults: 0))
        ])
        let viewModel = SearchViewModel(service: service)

        await viewModel.search(query: "The")

        #expect(viewModel.currentQuery == "The")
        #expect(await service.requests == [
            SearchRequest(query: "title:The", page: 1, limit: 20)
        ])
    }

    @Test @MainActor
    func searchLoadsNextPageAtEndOfResults() async {
        let first = Book(id: "/works/OL6W", title: "First")
        let second = Book(id: "/works/OL7W", title: "Second")
        let service = BookCatalogServiceStub(results: [
            .success(BookSearchPage(books: [first], page: 1, totalResults: 2)),
            .success(BookSearchPage(books: [second], page: 2, totalResults: 2))
        ])
        let viewModel = SearchViewModel(service: service, pageSize: 1)

        await viewModel.search(query: "series")
        await viewModel.loadMoreIfNeeded(currentBook: first)

        #expect(viewModel.books == [first, second])
        #expect(viewModel.canLoadMore == false)
        #expect(await service.requests == [
            SearchRequest(query: "series", page: 1, limit: 1),
            SearchRequest(query: "series", page: 2, limit: 1)
        ])
    }

    @Test @MainActor
    func discoveryLoadsSelectedMoodAndNextPage() async {
        let first = Book(id: "/works/OL12W", title: "First Discovery Book")
        let second = Book(id: "/works/OL13W", title: "Second Discovery Book")
        let service = BookCatalogServiceStub(results: [
            .success(BookSearchPage(books: [first], page: 1, totalResults: 2)),
            .success(BookSearchPage(books: [second], page: 2, totalResults: 2))
        ])
        let viewModel = DiscoveryViewModel(
            service: service,
            selectedMood: .mystery,
            pageSize: 1
        )

        await viewModel.loadIfNeeded()
        await viewModel.loadMoreIfNeeded(currentBook: first)

        #expect(viewModel.state == DiscoveryViewModel.State.loaded)
        #expect(viewModel.books == [first, second])
        #expect(viewModel.canLoadMore == false)
        #expect(await service.requests == [
            SearchRequest(query: "subject:mystery", page: 1, limit: 1),
            SearchRequest(query: "subject:mystery", page: 2, limit: 1)
        ])
    }

    @Test @MainActor
    func libraryPersistsBookAndShelfMembership() throws {
        let suiteName = "BookDiscoveryTests.Library.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let book = Book(
            id: "/works/OL8W",
            title: "Saved Book",
            authors: ["Library Author"],
            coverURL: URL(string: "https://covers.example/saved.jpg")
        )

        let library = LibraryStore(
            defaults: defaults,
            storageKey: "library",
            seedWithSamples: false
        )
        library.add(book, to: .wanted)

        let restoredLibrary = LibraryStore(
            defaults: defaults,
            storageKey: "library",
            seedWithSamples: false
        )

        #expect(restoredLibrary.contains(book, on: .wanted))
        #expect(restoredLibrary.books(on: .wanted).first?.title == "Saved Book")
        #expect(restoredLibrary.books(on: .wanted).first?.coverURL == book.coverURL)
    }

    @Test @MainActor
    func removingOneShelfPreservesOtherMemberships() throws {
        let suiteName = "BookDiscoveryTests.Shelves.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let book = Book(id: "/works/OL9W", title: "Two Shelves")
        let library = LibraryStore(
            defaults: defaults,
            storageKey: "library",
            seedWithSamples: false
        )

        library.add(book, to: .wanted)
        library.add(book, to: .favorites)
        library.remove(book, from: .wanted)

        #expect(!library.contains(book, on: .wanted))
        #expect(library.contains(book, on: .favorites))
        #expect(library.count(on: .favorites) == 1)
    }

    @Test @MainActor
    func readingStatusesAreMutuallyExclusiveAndPreserveFavorites() throws {
        let suiteName = "BookDiscoveryTests.Status.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let book = Book(id: "/works/OL10W", title: "Status Book")
        let library = LibraryStore(
            defaults: defaults,
            storageKey: "library",
            seedWithSamples: false
        )

        library.setStatus(.wanted, for: book)
        library.toggle(book, on: .favorites)
        library.setStatus(.reading, for: book)

        #expect(library.status(of: book) == .reading)
        #expect(!library.contains(book, on: .wanted))
        #expect(library.contains(book, on: .favorites))
    }

    @Test @MainActor
    func resolvingSearchResultPreservesStoredProgress() throws {
        let suiteName = "BookDiscoveryTests.Resolution.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let searchBook = Book(id: "/works/OL11W", title: "Progress Book")
        let library = LibraryStore(
            defaults: defaults,
            storageKey: "library",
            seedWithSamples: false
        )

        library.updateProgress(for: searchBook, progress: 0.55)
        let refreshedSearchBook = Book(id: searchBook.id, title: searchBook.title)

        #expect(library.resolvedBook(refreshedSearchBook).progress == 0.55)
    }

    @Test @MainActor
    func readingActivityCalculatesMinutesDaysAndStreak() throws {
        let suiteName = "BookDiscoveryTests.Activity.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let today = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 26, hour: 12)))
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let twoDaysAgo = try #require(calendar.date(byAdding: .day, value: -2, to: today))
        let store = ReadingActivityStore(
            defaults: defaults,
            storageKey: "activity",
            calendar: calendar
        )

        store.logSession(for: .longWay, minutes: 20, progressAfter: 0.2, date: twoDaysAgo)
        store.logSession(for: .longWay, minutes: 30, progressAfter: 0.3, date: yesterday)
        store.logSession(for: .longWay, minutes: 40, progressAfter: 0.4, date: today)

        let start = try #require(calendar.date(byAdding: .day, value: -3, to: today))
        let end = try #require(calendar.date(byAdding: .day, value: 1, to: today))
        #expect(store.minutes(from: start, to: end) == 90)
        #expect(store.activeDays(from: start, to: end) == 3)
        #expect(store.currentStreak(asOf: today) == 3)
    }

    @Test @MainActor
    func completionIsCountedOncePerBookAndYear() throws {
        let suiteName = "BookDiscoveryTests.Completion.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = ReadingActivityStore(defaults: defaults, storageKey: "activity")
        let date = Date.now

        store.markFinished(.longWay, at: date)
        store.markFinished(.longWay, at: date)

        #expect(store.completions.count == 1)
    }

    private static func page(with books: [Book]) -> BookSearchPage {
        BookSearchPage(books: books, page: 1, totalResults: books.count)
    }
}

private actor BookCatalogServiceStub: BookCatalogService {
    private(set) var queries: [String] = []
    private(set) var requests: [SearchRequest] = []
    private(set) var workIDs: [String] = []
    private var results: [Result<BookSearchPage, Error>]
    private var workResults: [Result<BookWorkDetails, Error>]

    init(
        results: [Result<BookSearchPage, Error>],
        workResults: [Result<BookWorkDetails, Error>] = []
    ) {
        self.results = results
        self.workResults = workResults
    }

    func searchBooks(query: String, page: Int, limit: Int) async throws -> BookSearchPage {
        queries.append(query)
        requests.append(SearchRequest(query: query, page: page, limit: limit))
        guard !results.isEmpty else { throw TestError.missingResult }
        return try results.removeFirst().get()
    }

    func workDetails(id: String) async throws -> BookWorkDetails {
        workIDs.append(id)
        guard !workResults.isEmpty else { throw TestError.missingResult }
        return try workResults.removeFirst().get()
    }
}

private struct SearchRequest: Equatable, Sendable {
    let query: String
    let page: Int
    let limit: Int
}

private enum TestError: LocalizedError {
    case offline
    case missingResult

    var errorDescription: String? {
        switch self {
        case .offline: "You appear to be offline."
        case .missingResult: "No stub result was configured."
        }
    }
}
