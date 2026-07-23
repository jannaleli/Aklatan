import Foundation

struct OpenLibraryConfiguration: Sendable {
    let apiBaseURL: URL
    let coversBaseURL: URL
    let userAgent: String

    static let production = OpenLibraryConfiguration(
        apiBaseURL: URL(string: "https://openlibrary.org")!,
        coversBaseURL: URL(string: "https://covers.openlibrary.org")!,
        // Add a real contact address before frequent production traffic.
        userAgent: "Marginalia/1.0 (iOS)"
    )
}
