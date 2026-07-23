import SwiftUI

struct ProgressBar: View {
    let value: Double
    let color: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.progressTrack)
                Capsule().fill(color).frame(width: geo.size.width * value)
            }
        }.frame(height: 6)
    }
}
