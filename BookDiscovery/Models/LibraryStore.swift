import Combine
import Foundation

@MainActor
final class LibraryStore: ObservableObject {
    @Published private var records: [String: LibraryRecord]

    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "marginalia.library.v1",
        seedWithSamples: Bool = true
    ) {
        self.defaults = defaults
        self.storageKey = storageKey

        if let data = defaults.data(forKey: storageKey),
           let savedRecords = try? JSONDecoder().decode([String: LibraryRecord].self, from: data) {
            records = savedRecords
        } else {
            records = seedWithSamples ? Self.sampleRecords : [:]
        }
    }

    func books(on shelf: Shelf) -> [Book] {
        records.values
            .filter { $0.shelves.contains(shelf) }
            .sorted { $0.dateAdded > $1.dateAdded }
            .map(\.book.domainBook)
    }

    func count(on shelf: Shelf) -> Int {
        records.values.reduce(into: 0) { count, record in
            if record.shelves.contains(shelf) { count += 1 }
        }
    }

    func contains(_ book: Book, on shelf: Shelf) -> Bool {
        records[book.id]?.shelves.contains(shelf) == true
    }

    func toggle(_ book: Book, on shelf: Shelf) {
        if contains(book, on: shelf) {
            remove(book, from: shelf)
        } else {
            add(book, to: shelf)
        }
    }

    func add(_ book: Book, to shelf: Shelf) {
        var record = records[book.id] ?? LibraryRecord(
            book: StoredBook(book),
            shelves: [],
            dateAdded: .now
        )
        record.book = StoredBook(book)
        record.shelves.insert(shelf)
        record.dateAdded = .now
        records[book.id] = record
        persist()
    }

    func remove(_ book: Book, from shelf: Shelf) {
        guard var record = records[book.id] else { return }
        record.shelves.remove(shelf)

        if record.shelves.isEmpty {
            records.removeValue(forKey: book.id)
        } else {
            records[book.id] = record
        }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static var sampleRecords: [String: LibraryRecord] {
        let memberships: [(Book, Set<Shelf>)] = [
            (.longWay, [.reading]),
            (.weightOfSalt, [.reading, .wanted]),
            (.quietHarbor, [.reading, .finished, .favorites]),
            (.paperMoons, [.reading, .finished, .favorites]),
            (.lantern, [.finished]),
            (.orchard, [.wanted]),
            (.north, [.wanted])
        ]

        return Dictionary(uniqueKeysWithValues: memberships.enumerated().map { index, value in
            let (book, shelves) = value
            return (
                book.id,
                LibraryRecord(
                    book: StoredBook(book),
                    shelves: shelves,
                    dateAdded: Date(timeIntervalSince1970: TimeInterval(index))
                )
            )
        })
    }
}

private struct LibraryRecord: Codable {
    var book: StoredBook
    var shelves: Set<Shelf>
    var dateAdded: Date
}

private struct StoredBook: Codable {
    let id: String
    let title: String
    let authors: [String]
    let firstPublishYear: Int?
    let editionCount: Int
    let subjects: [String]
    let coverURL: URL?
    let progress: Double

    init(_ book: Book) {
        id = book.id
        title = book.title
        authors = book.authors
        firstPublishYear = book.firstPublishYear
        editionCount = book.editionCount
        subjects = book.subjects
        coverURL = book.coverURL
        progress = book.progress
    }

    var domainBook: Book {
        Book(
            id: id,
            title: title,
            authors: authors,
            firstPublishYear: firstPublishYear,
            editionCount: editionCount,
            subjects: subjects,
            coverURL: coverURL,
            progress: progress
        )
    }
}
