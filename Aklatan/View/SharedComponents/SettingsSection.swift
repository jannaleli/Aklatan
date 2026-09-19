import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .sectionLabel
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .cardStyle(radius: 18)
        }
        .padding(.top, 24)
    }
}
