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
