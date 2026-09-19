import SwiftUI

struct Book: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let authors: [String]
    let firstPublishYear: Int?
    let editionCount: Int
    let subjects: [String]
    let coverURL: URL?
    let color: Color
    let progress: Double

    var author: String {
        authors.isEmpty ? "Unknown author" : authors.joined(separator: ", ")
    }

    init(
        id: String,
        title: String,
        authors: [String] = [],
        firstPublishYear: Int? = nil,
        editionCount: Int = 0,
        subjects: [String] = [],
        coverURL: URL? = nil,
        color: Color? = nil,
        progress: Double = 0
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.firstPublishYear = firstPublishYear
        self.editionCount = editionCount
        self.subjects = subjects
        self.coverURL = coverURL
        self.color = color ?? Self.placeholderColors[Self.stableColorIndex(for: id)]
        self.progress = progress
    }

    private static let placeholderColors: [Color] = [
        Color(hex: "6F7D5E"),
        Color(hex: "A5583F"),
        Color(hex: "B07A5E"),
        Color(hex: "6F7F8C"),
        Color(hex: "A98F52"),
        Color(hex: "7D6274")
    ]

    private static func stableColorIndex(for id: String) -> Int {
        id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % placeholderColors.count }
    }

    static let longWay = Book(
        id: "local/long-way",
        title: "Long Way to Morning",
        authors: ["Ada Rourke"],
        color: Color(hex: "6F7D5E"),
        progress: 0.62
    )

    static let weightOfSalt = Book(
        id: "local/weight-of-salt",
        title: "The Weight of Salt",
        authors: ["Nora Beck"],
        color: Color(hex: "A5583F"),
        progress: 0.28
    )

    static let lantern = Book(
        id: "local/lantern-keepers",
        title: "The Lantern Keepers",
        authors: ["Elias Vance"],
        color: Color(hex: "B07A5E"),
        progress: 0.7
    )

    static let quietHarbor = Book(
        id: "local/quiet-harbor",
        title: "Quiet Harbor",
        authors: ["M. Okafor"],
        color: Color(hex: "6F7F8C"),
        progress: 0.81
    )

    static let paperMoons = Book(
        id: "local/paper-moons",
        title: "Paper Moons",
        authors: ["Junia Reyes"],
        color: Color(hex: "A98F52"),
        progress: 0.44
    )

    static let orchard = Book(
        id: "local/orchard-index",
        title: "The Orchard Index",
        authors: ["Lena Moss"],
        color: Color(hex: "7D6274")
    )

    static let north = Book(
        id: "local/north-of-stillness",
        title: "North of Stillness",
        authors: ["I. Vale"],
        color: Color(hex: "7C7A4E")
    )

    static let recent = [lantern, quietHarbor, paperMoons]
    static let similar = [orchard, north, lantern]
    static let library = [longWay, weightOfSalt, quietHarbor, paperMoons]
}
