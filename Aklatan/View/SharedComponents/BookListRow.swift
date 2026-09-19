import SwiftUI

struct BookListRow: View {
    @Environment(\.accentTheme) private var theme

    let book: Book

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            BookCover(book: book, width: 72, height: 108)

            VStack(alignment: .leading, spacing: 4) {
                DisplayText(book.title, size: 17)
                    .lineLimit(2)

                Text(book.author)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
                    .lineLimit(2)

                if let year = book.firstPublishYear, year > 0 {
                    Text("First published \(year.formatted(.number.grouping(.never)))")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.muted2)
                        .padding(.top, 5)
                }

                if let subject = book.subjects.first {
                    Text(subject)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.ink)
                        .lineLimit(1)
                        .padding(.top, 3)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.faint)
                .padding(.top, 4)
        }
        .padding(12)
        .cardStyle(radius: 16)
        .contentShape(Rectangle())
    }
}
