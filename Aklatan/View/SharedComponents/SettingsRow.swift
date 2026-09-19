import SwiftUI

struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    var value: String? = nil
    var chevron = false

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

            if let value {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.muted)
            }

            if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.faint)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .contentShape(Rectangle())
    }
}
