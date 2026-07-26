import SwiftUI

struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        DisplayText(title, size: 19)
    }
}
