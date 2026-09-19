import SwiftUI

struct CompactBook: View {
    let book: Book
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BookCover(book: book, width: width, height: width * 1.5)

            Text(book.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Palette.ink2)
                .lineLimit(2)
                .padding(.top, 8)

            Text(book.author)
                .font(.system(size: 11))
                .foregroundStyle(Palette.muted2)
                .lineLimit(1)
                .padding(.top, 2)
        }
        .frame(width: width, alignment: .leading)
    }
}
