import SwiftUI

struct SettingsToggle: View {
    let icon: String
    let color: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 29, height: 29)
                .background(color, in: RoundedRectangle(cornerRadius: 7))

            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink2)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
    }
}
