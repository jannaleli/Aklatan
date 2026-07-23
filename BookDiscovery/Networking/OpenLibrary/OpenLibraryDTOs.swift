import Foundation

struct OpenLibrarySearchResponseDTO: Decodable, Sendable {
    let start: Int
    let numFound: Int
    let docs: [OpenLibraryBookDTO]

    enum CodingKeys: String, CodingKey {
        case start
        case numFound = "num_found"
        case docs
    }
}

struct OpenLibraryBookDTO: Decodable, Sendable {
    let key: String
    let title: String
    let authorNames: [String]?
    let coverID: Int?
    let firstPublishYear: Int?
    let editionCount: Int?
    let subjects: [String]?

    enum CodingKeys: String, CodingKey {
        case key, title
        case authorNames = "author_name"
        case coverID = "cover_i"
        case firstPublishYear = "first_publish_year"
        case editionCount = "edition_count"
        case subjects = "subject"
    }
}

struct OpenLibraryWorkDTO: Decodable, Sendable {
    let key: String
    let title: String
    let description: OpenLibraryDescriptionDTO?
    let covers: [Int]?
    let subjects: [String]?
}

enum OpenLibraryDescriptionDTO: Decodable, Sendable {
    case text(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
            return
        }
        let value = try container.decode(ValueContainer.self)
        self = .text(value.value)
    }

    var value: String {
        switch self { case .text(let text): text }
    }

    private struct ValueContainer: Decodable { let value: String }
}
