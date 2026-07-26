import SwiftUI

struct MoodChip: View {
    @Environment(\.accentTheme) private var theme

    let text: String
    let active: Bool

    init(_ text: String, active: Bool = false) {
        self.text = text
        self.active = active
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: active ? .semibold : .medium))
            .foregroundStyle(active ? Palette.background : Palette.ink2)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(active ? theme.color : Palette.surface, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(active ? .clear : Palette.hairline)
            }
    }
}
