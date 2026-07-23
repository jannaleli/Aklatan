import SwiftUI

struct LibraryView: View {
    @Environment(\.accentTheme) private var theme
    @State private var shelf: Shelf = .reading
    let openBook: (Book) -> Void
    private let columns = [GridItem(.flexible(), spacing: 18), GridItem(.flexible())]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                DisplayText("Library", size: 32)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Shelf.allCases) { item in
                            Button { shelf = item } label: {
                                Text(item.label).font(.system(size: 13, weight: item == shelf ? .semibold : .medium))
                                    .foregroundStyle(item == shelf ? Palette.background : Palette.ink2)
                                    .padding(.horizontal, 15).frame(height: 34)
                                    .background(item == shelf ? theme.color : Palette.surface, in: Capsule())
                                    .overlay(Capsule().stroke(item == shelf ? .clear : Palette.hairline))
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(.top, 20)
                LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                    ForEach(shelf.books) { book in
                        Button { openBook(book) } label: {
                            VStack(alignment: .leading, spacing: 0) {
                                BookCover(book: book, width: nil, height: nil).aspectRatio(2/3, contentMode: .fit)
                                Text(book.title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink).lineLimit(2).padding(.top, 9)
                                Text(book.author).font(.system(size: 12)).foregroundStyle(Palette.muted2).padding(.top, 2)
                                if shelf == .reading { ProgressBar(value: book.progress, color: book.color).padding(.top, 8) }
                            }
                        }.buttonStyle(.plain)
                    }
                }.padding(.top, 24)
            }.padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 120)
        }.background(Palette.background)
    }
}
