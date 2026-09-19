import SwiftUI

struct DiscoveryView: View {
    @Environment(\.accentTheme) private var theme
    @StateObject private var viewModel: DiscoveryViewModel

    let openBook: (Book) -> Void

    init(mood: HomeMood, openBook: @escaping (Book) -> Void) {
        _viewModel = StateObject(wrappedValue: DiscoveryViewModel(mood: mood))
        self.openBook = openBook
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            moodPicker
            content
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await viewModel.loadIfNeeded() }
    }

    private var moodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HomeMood.allCases) { mood in
                    Button {
                        Task { await viewModel.select(mood) }
                    } label: {
                        MoodChip(mood.label, active: viewModel.selectedMood == mood)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 22)
        }
        .contentMargins(.horizontal, 0)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            statusView {
                ProgressView("Finding books…")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
            }

        case .empty:
            statusView {
                Label("No books found for this mood.", systemImage: "books.vertical")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.muted)
            }

        case .failed(let message):
            statusView {
                VStack(spacing: 14) {
                    Label(message, systemImage: "wifi.exclamationmark")
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.center)

                    Button("Try again") {
                        Task { await viewModel.retry() }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.ink)
                }
            }

        case .loaded:
            resultsList
        }
    }

    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    DisplayText("\(viewModel.selectedMood.label) for you", size: 19)
                    Spacer()
                    Text("\(viewModel.totalResults.formatted()) books")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.muted)
                }

                ForEach(viewModel.books) { book in
                    Button { openBook(book) } label: { BookListRow(book: book) }
                        .buttonStyle(.plain)
                        .task {
                            await viewModel.loadMoreIfNeeded(currentBook: book)
                        }
                }

                paginationFooter
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 28)
        }
        .refreshable { await viewModel.retry() }
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if viewModel.isLoadingMore {
            ProgressView()
                .padding(.vertical, 12)
        } else if let paginationError = viewModel.paginationError {
            VStack(spacing: 8) {
                Text(paginationError)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)

                Button("Try again") {
                    guard let lastBook = viewModel.books.last else { return }
                    Task { await viewModel.loadMoreIfNeeded(currentBook: lastBook) }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.ink)
            }
            .padding(.vertical, 12)
        }
    }

    private func statusView<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 36)
            .padding(.bottom, 60)
    }
}
