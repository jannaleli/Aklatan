import SwiftUI

struct ContentView: View {
    @StateObject private var library = LibraryStore()
    @StateObject private var activity = ReadingActivityStore()
    @State private var navigationPath = NavigationPath()
    @State private var selectedTab: AppTab = .home
    @State private var bookDetailViewModel: BookDetailViewModel?
    @State private var accent: AccentTheme = .sage
    @State private var displayStyle: DisplayStyle = .serif
    @State private var gamified = true
    @State private var fullScreenReading = true
    @State private var cacheSize = 48.2

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Group {
                    switch selectedTab {
                    case .home:
                        HomeView(
                            gamified: gamified,
                            openSearch: { selectedTab = .search },
                            openDiscovery: { navigationPath.append($0) },
                            openBook: openBook
                        )
                    case .search:
                        SearchView(openBook: openBook)
                    case .library:
                        LibraryView(
                            openSearch: { selectedTab = .search },
                            openBook: openBook
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
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeMood.self) { mood in
                DiscoveryView(mood: mood, openBook: openBook)
                    .environment(\.accentTheme, accent)
                    .environment(\.displayStyle, displayStyle)
                    .environmentObject(library)
                    .environmentObject(activity)
            }
        }
        .background((selectedTab == .settings ? Palette.settingsBackground : Palette.background).ignoresSafeArea())
        .preferredColorScheme(.light)
        .fullScreenCover(item: $bookDetailViewModel) { viewModel in
            BookDetailView(viewModel: viewModel)
                .environment(\.accentTheme, accent)
                .environment(\.displayStyle, displayStyle)
                .environmentObject(library)
                .environmentObject(activity)
        }
    }

    private func openBook(_ book: Book) {
        let viewModel = BookDetailViewModel(book: book)
        bookDetailViewModel = viewModel
    }
}
