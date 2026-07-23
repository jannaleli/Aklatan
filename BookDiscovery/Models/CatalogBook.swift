import Foundation

struct BookSearchPage: Sendable {
    let books: [Book]
    let page: Int
    let totalResults: Int
}

struct BookWorkDetails: Equatable, Sendable {
    let id: String
    let title: String
    let description: String?
    let subjects: [String]
    let coverURL: URL?
}
