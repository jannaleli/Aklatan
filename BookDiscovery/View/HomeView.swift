//
//  HomeView.swift
//  BookDiscovery
//
//  Created by Jann Aleli Zaplan on 2026-07-20.
//

// MARK: - Home
import SwiftUI

struct HomeView: View {
    @Environment(\.accentTheme) private var theme
    @EnvironmentObject private var activity: ReadingActivityStore
    @EnvironmentObject private var library: LibraryStore
    @StateObject private var viewModel = HomeViewModel()
    let gamified: Bool
    let openSearch: () -> Void
    let openDiscovery: (HomeMood) -> Void
    let openBook: (Book) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Sunday · Good evening")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.muted)
                        DisplayText("Hello, Mara", size: 32)
                    }
                    Spacer(minLength: 8)
                    if gamified {
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill").foregroundStyle(Palette.flame)
                            Text("\(activity.currentStreak())").fontWeight(.bold)
                            Text("day streak").font(.system(size: 11, weight: .medium)).foregroundStyle(Palette.clay)
                        }
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.rust)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(Palette.chip, in: Capsule())
                        .overlay(Capsule().stroke(Palette.rust.opacity(0.2)))
                    }
                }

                Button(action: openSearch) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                        Text("Search books, authors…")
                        Spacer()
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.muted2)
                    .padding(.horizontal, 16).frame(height: 47)
                    .cardStyle(radius: 14)
                }
                .buttonStyle(.plain).padding(.top, 20)

                SectionTitle("Continue reading").padding(.top, 26).padding(.bottom, 12)
                if let book = library.mostRecentReadingBook() {
                    Button { openBook(book) } label: {
                    HStack(spacing: 16) {
                        BookCover(book: book, width: 82, height: 123)
                        VStack(alignment: .leading, spacing: 0) {
                            DisplayText(book.title, size: 18)
                            Text(book.author).font(.system(size: 13)).foregroundStyle(Palette.muted).padding(.top, 3)
                            Text("Reading progress").font(.system(size: 12)).foregroundStyle(Palette.muted2).padding(.top, 12)
                            ProgressBar(value: book.progress, color: theme.color).padding(.top, 8)
                            HStack {
                                Text("\(Int(book.progress * 100))%").fontWeight(.semibold).foregroundStyle(theme.ink)
                                Spacer()
                                Text("Log reading")
                            }
                            .font(.system(size: 11)).foregroundStyle(Palette.muted).padding(.top, 7)
                        }
                    }
                    .padding(16).cardStyle(radius: 18)
                    }.buttonStyle(.plain)
                } else {
                    Button(action: openSearch) {
                        HStack {
                            Text("Find a book to start reading")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.ink)
                        .padding(16)
                        .cardStyle(radius: 14)
                    }
                    .buttonStyle(.plain)
                }

                SectionTitle("Browse by mood").padding(.top, 28).padding(.bottom, 12)
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
                }.contentMargins(.horizontal, 0)

                HStack {
                    SectionTitle("Discover")
                    Spacer()
                    Button {
                        openDiscovery(viewModel.selectedMood)
                    } label: {
                        HStack(spacing: 4) {
                            Text("See all")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.ink)
                    }
                    .buttonStyle(.plain)
                }.padding(.top, 28).padding(.bottom, 12)

                discoveryContent
            }
            .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 120)
        }
        .background(Palette.background)
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var discoveryContent: some View {
        switch viewModel.state {
        case .idle where viewModel.books.isEmpty,
             .loading where viewModel.books.isEmpty:
            HStack {
                Spacer()
                ProgressView("Finding books…")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
                Spacer()
            }
            .frame(height: 170)

        case .empty:
            statusCard(
                icon: "books.vertical",
                message: "No books found for this mood. Try another one."
            )

        case .failed(let message):
            VStack(spacing: 10) {
                statusCard(icon: "wifi.exclamationmark", message: message)
                Button("Try again") {
                    Task { await viewModel.retry() }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.ink)
            }

        case .idle, .loading, .loaded:
            VStack(alignment: .leading, spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(viewModel.books) { book in
                            Button { openBook(book) } label: {
                                CompactBook(book: book, width: 96)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if viewModel.state == .loading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func statusCard(icon: String, message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(theme.ink)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 76)
        .cardStyle(radius: 14)
    }
}
