import Foundation

enum Shelf: String, CaseIterable, Identifiable {
    case reading, wanted, finished, favorites
    var id: String { rawValue }
    var label: String { switch self { case .reading: "Reading  3"; case .wanted: "Want to Read  18"; case .finished: "Finished  64"; case .favorites: "Favorites" } }
    var books: [Book] { switch self { case .reading: Book.library; case .wanted: Book.similar + [.weightOfSalt]; case .finished: Book.recent; case .favorites: [.quietHarbor, .paperMoons] } }
}
