import SwiftUI

enum AccentTheme: String, CaseIterable, Identifiable {
    case sage, terracotta, blue, plum
    var id: String { rawValue }
    var label: String { switch self { case .sage: "Sage"; case .terracotta: "Terracotta"; case .blue: "Dusty Blue"; case .plum: "Plum" } }
    var color: Color { switch self { case .sage: Color(hex: "6F7D5E"); case .terracotta: Color(hex: "B0674A"); case .blue: Color(hex: "5F7480"); case .plum: Color(hex: "7D6274") } }
    var ink: Color { switch self { case .sage: Color(hex: "5C6A4D"); case .terracotta: Color(hex: "9C4F36"); case .blue: Color(hex: "4D616C"); case .plum: Color(hex: "684F60") } }
}

private struct AccentThemeKey: EnvironmentKey { static let defaultValue = AccentTheme.sage }

extension EnvironmentValues {
    var accentTheme: AccentTheme {
        get { self[AccentThemeKey.self] }
        set { self[AccentThemeKey.self] = newValue }
    }
}
