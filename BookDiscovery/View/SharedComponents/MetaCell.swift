import SwiftUI

struct MetaCell: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            DisplayText(value, size: 19)
            Text(label).font(.system(size: 11)).foregroundStyle(Palette.muted2)
        }.frame(maxWidth: .infinity).padding(.vertical, 14)
    }
}
