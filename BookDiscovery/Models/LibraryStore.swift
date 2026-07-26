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
            records = Self.normalized(savedRecords)
        } else {
            records = seedWithSamples ? Self.sampleRecords : [:]
        }
    }

    func books(on shelf: Shelf, sortedBy sort: LibrarySort = .recent) -> [Book] {
        let matchingRecords = records.values.filter { $0.shelves.contains(shelf) }
        return matchingRecords.sorted { lhs, rhs in
            switch sort {
            case .recent: lhs.relevantDate(for: shelf) > rhs.relevantDate(for: shelf)
            case .title: lhs.book.title.localizedCaseInsensitiveCompare(rhs.book.title) == .orderedAscending
            case .author: lhs.book.author.localizedCaseInsensitiveCompare(rhs.book.author) == .orderedAscending
            case .progress: lhs.book.progress > rhs.book.progress
            }
        }.map(\.book.domainBook)
    }

    func count(on shelf: Shelf) -> Int {
        records.values.reduce(into: 0) { count, record in
            if record.shelves.contains(shelf) { count += 1 }
        }
    }

    func contains(_ book: Book, on shelf: Shelf) -> Bool {
        records[book.id]?.shelves.contains(shelf) == true
    }

    func book(id: String) -> Book? {
        records[id]?.book.domainBook
    }

    func resolvedBook(_ book: Book) -> Book {
        guard let stored = records[book.id]?.book.domainBook else { return book }
        return Book(
            id: book.id,
            title: book.title,
            authors: book.authors,
            firstPublishYear: book.firstPublishYear,
            editionCount: book.editionCount,
            subjects: book.subjects.isEmpty ? stored.subjects : book.subjects,
            coverURL: book.coverURL ?? stored.coverURL,
            color: book.color,
            progress: stored.progress
        )
    }

    func status(of book: Book) -> ReadingStatus? {
        guard let shelves = records[book.id]?.shelves else { return nil }
        if shelves.contains(.finished) { return .finished }
        if shelves.contains(.reading) { return .reading }
        if shelves.contains(.wanted) { return .wanted }
        return nil
    }

    func setStatus(_ status: ReadingStatus?, for book: Book) {
        var record = records[book.id] ?? LibraryRecord(
            book: StoredBook(book),
            shelves: [],
            dateAdded: .now,
            lastReadAt: nil,
            finishedAt: nil
        )
        record.book = StoredBook(resolvedBook(book))
        record.shelves.subtract([.wanted, .reading, .finished])

        if let status {
            record.shelves.insert(status.shelf)
            if status == .reading { record.lastReadAt = .now }
            if status == .finished { record.finishedAt = .now }
        }

        if record.shelves.isEmpty {
            records.removeValue(forKey: book.id)
        } else {
            records[book.id] = record
        }
        persist()
    }

    func mostRecentReadingBook() -> Book? {
        records.values
            .filter { $0.shelves.contains(.reading) }
            .max { $0.relevantDate(for: .reading) < $1.relevantDate(for: .reading) }?
            .book.domainBook
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
            dateAdded: .now,
            lastReadAt: nil,
            finishedAt: nil
        )
        record.book = StoredBook(resolvedBook(book))
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

    func updateProgress(for book: Book, progress: Double) {
        let progress = min(max(progress, 0), 1)
        let updated = Book(
            id: book.id,
            title: book.title,
            authors: book.authors,
            firstPublishYear: book.firstPublishYear,
            editionCount: book.editionCount,
            subjects: book.subjects,
            coverURL: book.coverURL,
            color: book.color,
            progress: progress
        )
        var record = records[book.id] ?? LibraryRecord(
            book: StoredBook(updated),
            shelves: [],
            dateAdded: .now,
            lastReadAt: nil,
            finishedAt: nil
        )
        record.book = StoredBook(updated)
        record.shelves.subtract([.wanted, .reading, .finished])
        record.shelves.insert(progress >= 1 ? .finished : .reading)
        record.lastReadAt = .now
        record.finishedAt = progress >= 1 ? .now : nil
        records[book.id] = record
        persist()
    }

    func markFinished(_ book: Book) {
        let resolved = resolvedBook(book)
        updateProgress(for: resolved, progress: 1)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static var sampleRecords: [String: LibraryRecord] {
        let memberships: [(Book, Set<Shelf>)] = [
            (.longWay, [.reading]),
            (.weightOfSalt, [.reading]),
            (.quietHarbor, [.finished, .favorites]),
            (.paperMoons, [.finished, .favorites]),
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
                    dateAdded: Date(timeIntervalSince1970: TimeInterval(index)),
                    lastReadAt: shelves.contains(.reading) ? Date(timeIntervalSince1970: TimeInterval(index)) : nil,
                    finishedAt: shelves.contains(.finished) ? Date(timeIntervalSince1970: TimeInterval(index)) : nil
                )
            )
        })
    }

    private static func normalized(_ records: [String: LibraryRecord]) -> [String: LibraryRecord] {
        records.mapValues { record in
            var record = record
            if record.shelves.contains(.finished) {
                record.shelves.subtract([.reading, .wanted])
            } else if record.shelves.contains(.reading) {
                record.shelves.remove(.wanted)
            }
            return record
        }
    }
}

private struct LibraryRecord: Codable {
    var book: StoredBook
    var shelves: Set<Shelf>
    var dateAdded: Date
    var lastReadAt: Date?
    var finishedAt: Date?

    func relevantDate(for shelf: Shelf) -> Date {
        switch shelf {
        case .reading: lastReadAt ?? dateAdded
        case .finished: finishedAt ?? dateAdded
        case .wanted, .favorites: dateAdded
        }
    }
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

    var author: String {
        authors.isEmpty ? "Unknown author" : authors.joined(separator: ", ")
    }

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
