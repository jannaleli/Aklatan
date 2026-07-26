import SwiftUI

struct ContentView: View {
    @StateObject private var library = LibraryStore()
    @StateObject private var activity = ReadingActivityStore()
    @State private var selectedTab: AppTab = .home
    @State private var selectedBook: Book?
    @State private var accent: AccentTheme = .sage
    @State private var displayStyle: DisplayStyle = .serif
    @State private var gamified = true
    @State private var fullScreenReading = true
    @State private var cacheSize = 48.2

    var body: some View {
        ZStack {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        gamified: gamified,
                        openSearch: { selectedTab = .search },
                        openBook: { selectedBook = $0 }
                    )
                case .search:
                    SearchView(openBook: { selectedBook = $0 })
                case .library:
                    LibraryView(
                        openSearch: { selectedTab = .search },
                        openBook: { selectedBook = $0 }
                    )
                case .stats: StatsView()
                case .settings:
                    SettingsView(accent: $accent, displayStyle: $displayStyle, gamified: $gamified, fullScreenReading: $fullScreenReading, cacheSize: $cacheSize)
                }
            }
            .environment(\.accentTheme, accent)
            .environment(\.displayStyle, displayStyle)
            .environmentObject(library)
            .environmentObject(activity)

            VStack {
                Spacer()
                MarginaliaTabBar(selection: $selectedTab)
            }
        }
        .background((selectedTab == .settings ? Palette.settingsBackground : Palette.background).ignoresSafeArea())
        .preferredColorScheme(.light)
        .fullScreenCover(item: $selectedBook) { book in
            BookDetailView(book: book)
                .environment(\.accentTheme, accent)
                .environment(\.displayStyle, displayStyle)
                .environmentObject(library)
                .environmentObject(activity)
        }
    }
}
