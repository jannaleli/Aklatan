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

    private static func page(with books: [Book]) -> BookSearchPage {
        BookSearchPage(books: books, page: 1, totalResults: books.count)
    }
}

private actor BookCatalogServiceStub: BookCatalogService {
    private(set) var queries: [String] = []
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
        guard !results.isEmpty else { throw TestError.missingResult }
        return try results.removeFirst().get()
    }

    func workDetails(id: String) async throws -> BookWorkDetails {
        workIDs.append(id)
        guard !workResults.isEmpty else { throw TestError.missingResult }
        return try workResults.removeFirst().get()
    }
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
