import SwiftUI

@MainActor
struct BookDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accentTheme) private var theme

    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var activity: ReadingActivityStore

    @State private var viewModel: BookDetailViewModel

    @State private var descriptionExpanded = false
    @State private var showingLogReading = false

    init(viewModel: BookDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    hero
                    metadata
                    logReadingButton
                    about
                }
            }

            actionBar
        }
        .overlay(alignment: .top) {
            HStack {
                CircleButton(icon: "chevron.left") { dismiss() }
                Spacer()
                CircleButton(icon: favorite ? "heart.fill" : "heart") {
                    library.toggle(viewModel.displayBook, on: .favorites)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .task { await viewModel.loadIfNeeded() }
        .sheet(isPresented: $showingLogReading) {
            LogReadingSheet(book: libraryBook)
                .environment(\.accentTheme, theme)
                .environmentObject(library)
                .environmentObject(activity)
        }
    }

    private var hero: some View {
        let book = viewModel.displayBook
        return VStack(spacing: 0) {
            BookCover(book: book, width: 158, height: 237)
                .shadow(color: Palette.rust.opacity(0.3), radius: 17, y: 12)
            DisplayText(book.title, size: 26)
                .multilineTextAlignment(.center)
                .padding(.top, 22)
            Text(byline(for: book))
                .font(.system(size: 14))
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .padding(.top, 58)
        .padding(.bottom, 26)
        .background(
            LinearGradient(
                colors: [Palette.progressTrack, Palette.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var metadata: some View {
        HStack(spacing: 0) {
            MetaCell(
                value: viewModel.book.firstPublishYear.map(String.init) ?? "—",
                label: "First published"
            )
            Divider().frame(height: 48)
            MetaCell(value: viewModel.primarySubject, label: "Subject")
            Divider().frame(height: 48)
            MetaCell(
                value: viewModel.book.editionCount > 0 ? String(viewModel.book.editionCount) : "—",
                label: "Editions"
            )
        }
        .cardStyle(radius: 16)
        .padding(.horizontal, 24)
    }

    private var logReadingButton: some View {
        Button {
            showingLogReading = true
        } label: {
            Label("Log Reading", systemImage: "book.pages")
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(theme.ink)
                .cardStyle(radius: 14)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var about: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle("About this book")

            switch viewModel.state {
            case .idle, .loading:
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Loading book details…")
                }
                .font(.system(size: 13))
                .foregroundStyle(Palette.muted)
                .padding(.top, 14)

            case .failed(let message):
                VStack(alignment: .leading, spacing: 10) {
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.muted)
                    Button("Try again") {
                        Task { await viewModel.retry() }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.ink)
                }
                .padding(.top, 10)

            case .loaded:
                if let description = viewModel.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 14.5))
                        .foregroundStyle(Palette.body)
                        .lineSpacing(7)
                        .lineLimit(descriptionExpanded ? nil : 6)
                        .padding(.top, 8)

                    Button(descriptionExpanded ? "Show less" : "Read more") {
                        withAnimation { descriptionExpanded.toggle() }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.ink)
                    .padding(.top, 5)
                } else {
                    Text("No description is available for this book.")
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.muted)
                        .padding(.top, 8)
                }
            }

            if !viewModel.displayBook.subjects.isEmpty {
                SectionTitle("Subjects")
                    .padding(.top, 26)
                    .padding(.bottom, 12)
                subjectChips
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 116)
    }

    private var subjectChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.displayBook.subjects.prefix(8)), id: \.self) { subject in
                    Text(subject)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.ink2)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Palette.surface, in: Capsule())
                        .overlay(Capsule().stroke(Palette.hairline))
                }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(ReadingStatus.allCases) { status in
                    Button {
                        library.setStatus(status, for: libraryBook)
                    } label: {
                        Label(status.label, systemImage: status.icon)
                    }
                }
                if readingStatus != nil {
                    Divider()
                    Button(role: .destructive) {
                        library.setStatus(nil, for: libraryBook)
                    } label: {
                        Label("Remove Reading Status", systemImage: "xmark")
                    }
                }
            } label: {
                Label(
                    readingStatus?.label ?? "Add to Library",
                    systemImage: readingStatus?.icon ?? "plus"
                )
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(theme.color, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(Palette.surface)
            }

            Button { library.toggle(viewModel.displayBook, on: .favorites) } label: {
                Image(systemName: favorite ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .frame(width: 52, height: 52)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.hairline))
                    .foregroundStyle(Palette.rust)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

    private func byline(for book: Book) -> String {
        guard let year = book.firstPublishYear else { return book.author }
        return "\(book.author) · \(year)"
    }

    private var libraryBook: Book {
        library.resolvedBook(viewModel.displayBook)
    }

    private var readingStatus: ReadingStatus? {
        library.status(of: viewModel.book)
    }

    private var favorite: Bool {
        library.contains(viewModel.book, on: .favorites)
    }
}
