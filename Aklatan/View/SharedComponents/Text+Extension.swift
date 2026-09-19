import SwiftUI

extension Text {
    var sectionLabel: some View {
        font(.system(size: 11, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Palette.muted)
    }
}
