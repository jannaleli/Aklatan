import SwiftUI

struct PlaceholderView: View {
    @Environment(\.accentTheme) private var theme
    let tab: AppTab
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: tab.icon).font(.system(size: 34)).foregroundStyle(theme.color)
            DisplayText(tab.label, size: 32)
            Text("This screen is ready for the next design round.").font(.system(size: 14)).foregroundStyle(Palette.muted)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.bottom, 70).background(Palette.background)
    }
}
