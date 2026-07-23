import SwiftUI

struct MarginaliaTabBar: View {
    @Environment(\.accentTheme) private var theme
    @Binding var selection: AppTab
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button { selection = tab } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selection == tab ? tab.selectedIcon : tab.icon).font(.system(size: 21))
                        Text(tab.label).font(.system(size: 10, weight: selection == tab ? .semibold : .medium))
                    }.foregroundStyle(selection == tab ? theme.ink : Palette.muted2).frame(maxWidth: .infinity)
                }.buttonStyle(.plain)
            }
        }.padding(.horizontal, 17).padding(.top, 12).padding(.bottom, 8).background(.ultraThinMaterial)
    }
}
