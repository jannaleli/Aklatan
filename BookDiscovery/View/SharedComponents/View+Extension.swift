import SwiftUI

extension View {
    func cardStyle(radius: CGFloat) -> some View {
        background(Palette.surface, in: RoundedRectangle(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Palette.hairline)
            }
            .shadow(color: Palette.ink.opacity(0.045), radius: 8, y: 3)
    }
}
