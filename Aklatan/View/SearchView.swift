import SwiftUI

struct SearchView: View {
    @Environment(\.accentTheme) private var theme
    @StateObject private var viewModel = SearchViewModel()
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    let openBook: (Book) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DisplayText("Search", size: 32)
                .padding(.horizontal, 22)

            searchField
                .padding(.horizontal, 22)
                .padding(.top, 18)

            content
        }
        .padding(.top, 18)
        .background(Palette.background)
        .onAppear { searchFocused = true }
        .task(id: query) {
            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
            }
            await viewModel.search(query: query)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.muted2)

            TextField("Search books, authors…", text: $query)
                .focused($searchFocused)
                .font(.system(size: 15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.search(query: query) }
                }

            if !query.isEmpty {
                Button {
                    query = ""
                    searchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.muted2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 47)
        .cardStyle(radius: 14)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            messageView(
                icon: "text.magnifyingglass",
                title: "Find your next book",
                message: "Search by title, author, or subject."
            )

        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                Text("Searching Open Library…")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 90)

        case .empty:
            messageView(
                icon: "books.vertical",
                title: "No books found",
                message: "Try a different title, author, or spelling."
            )

        case .failed(let message):
            VStack(spacing: 14) {
                messageView(
                    icon: "wifi.exclamationmark",
                    title: "Search unavailable",
                    message: message
                )
                .frame(maxHeight: 260)

                Button("Try again") {
                    Task { await viewModel.retry() }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.ink)

                Spacer()
            }

        case .loaded:
            resultsList
        }
    }

    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                HStack {
                    Text("\(viewModel.totalResults.formatted()) results")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.muted)
                    Spacer()
                }

                ForEach(viewModel.books) { book in
                    Button { openBook(book) } label: { BookListRow(book: book) }
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.loadMoreIfNeeded(currentBook: book)
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, 12)
                } else if let paginationError = viewModel.paginationError {
                    Text(paginationError)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 120)
        }
    }

    private func messageView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(theme.color)
            DisplayText(title, size: 21)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 36)
        .padding(.bottom, 90)
    }
}
