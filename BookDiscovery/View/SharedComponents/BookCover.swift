import SwiftUI

struct BookCover: View {
    let book: Book
    let width: CGFloat?
    let height: CGFloat?

    var body: some View {
        ZStack {
            placeholder

            if let coverURL = book.coverURL {
                AsyncImage(
                    url: coverURL,
                    transaction: Transaction(animation: .easeInOut(duration: 0.2))
                ) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .transition(.opacity)
                    }
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .shadow(color: Palette.ink.opacity(0.18), radius: 7, y: 5)
    }

    private var placeholder: some View {
        VStack(alignment: .leading) {
            DisplayText(book.title, size: width.map { $0 > 120 ? 20 : ($0 > 90 ? 16 : 14) } ?? 20).foregroundStyle(Palette.surface)
            Spacer()
            Text(book.author.uppercased()).font(.system(size: 8, weight: .medium)).tracking(1).opacity(0.84)
        }.foregroundStyle(Palette.surface).padding(width.map { $0 > 120 ? 16 : 11 } ?? 16)
            .frame(width: width, height: height, alignment: .leading).background(book.color)
    }
}
