import SwiftUI

struct DisplayText: View {
    @Environment(\.displayStyle) private var style
    let text: String
    let size: CGFloat
    init(_ text: String, size: CGFloat) { self.text = text; self.size = size }
    var body: some View {
        Text(text).font(style == .serif ? .system(size: size, weight: .medium, design: .serif) : .system(size: size, weight: .medium)).foregroundStyle(Palette.ink).tracking(-0.2)
    }
}
