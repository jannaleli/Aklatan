import Foundation

enum Shelf: String, CaseIterable, Codable, Identifiable, Sendable {
    case reading, wanted, finished, favorites
    var id: String { rawValue }
    var label: String {
        switch self {
        case .reading: "Reading"
        case .wanted: "Want to Read"
        case .finished: "Finished"
        case .favorites: "Favorites"
        }
    }
}

enum ReadingStatus: String, CaseIterable, Identifiable, Sendable {
    case wanted
    case reading
    case finished

    var id: Self { self }
    var label: String {
        switch self {
        case .wanted: "Want to Read"
        case .reading: "Reading"
        case .finished: "Finished"
        }
    }
    var icon: String {
        switch self {
        case .wanted: "bookmark"
        case .reading: "book.pages"
        case .finished: "checkmark.circle"
        }
    }
    var shelf: Shelf {
        switch self {
        case .wanted: .wanted
        case .reading: .reading
        case .finished: .finished
        }
    }
}

enum LibrarySort: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case title = "Title"
    case author = "Author"
    case progress = "Progress"
    var id: Self { self }
}
