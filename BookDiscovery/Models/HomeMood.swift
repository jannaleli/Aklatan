import Foundation

enum HomeMood: String, CaseIterable, Identifiable, Sendable {
    case fiction
    case mystery
    case memoir
    case poetry
    case scienceFiction

    var id: Self {
        self
    }

    var label: String {
        switch self {
        case .fiction:
            "Fiction"
        case .mystery:
            "Mystery"
        case .memoir:
            "Memoir"
        case .poetry:
            "Poetry"
        case .scienceFiction:
            "Sci-Fi"
        }
    }

    var searchQuery: String {
        switch self {
        case .fiction:
            "subject:fiction"
        case .mystery:
            "subject:mystery"
        case .memoir:
            "subject:memoir"
        case .poetry:
            "subject:poetry"
        case .scienceFiction:
            "subject:science_fiction"
        }
    }
}
