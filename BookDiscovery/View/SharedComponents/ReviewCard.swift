import SwiftUI

struct ReviewCard: View {
    let name: String
    let initial: String
    let color: Color
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(initial)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(color, in: Circle())

                VStack(alignment: .leading) {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))

                    Text("2 weeks ago")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.muted2)
                }

                Spacer()

                HStack(spacing: 1) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(Palette.star)
            }

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Palette.body)
                .lineSpacing(4)
        }
        .padding(15)
        .cardStyle(radius: 16)
    }
}
