import SwiftUI

enum DisplayStyle: String, CaseIterable, Identifiable {
    case serif
    case grotesk

    var id: String {
        rawValue
    }

    var label: String {
        self == .serif ? "Editorial serif" : "Modern grotesk"
    }
}

private struct DisplayStyleKey: EnvironmentKey {
    static let defaultValue = DisplayStyle.serif
}

extension EnvironmentValues {
    var displayStyle: DisplayStyle {
        get { self[DisplayStyleKey.self] }
        set { self[DisplayStyleKey.self] = newValue }
    }
}
