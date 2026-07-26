import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case search
    case library
    case stats
    case settings

    var id: String {
        rawValue
    }

    var label: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .home:
            "house"
        case .search:
            "magnifyingglass"
        case .library:
            "books.vertical"
        case .stats:
            "chart.bar"
        case .settings:
            "slider.horizontal.3"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home:
            "house.fill"
        case .library:
            "books.vertical.fill"
        case .stats:
            "chart.bar.fill"
        default:
            icon
        }
    }
}
