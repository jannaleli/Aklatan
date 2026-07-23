import SwiftUI

struct SettingsView: View {
    @Binding var accent: AccentTheme
    @Binding var displayStyle: DisplayStyle
    @Binding var gamified: Bool
    @Binding var fullScreenReading: Bool
    @Binding var cacheSize: Double

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                DisplayText("Settings", size: 32).padding(.horizontal, 4)
                SettingsSection("Appearance") {
                    Menu { ForEach(AccentTheme.allCases) { item in Button(item.label) { accent = item } } } label: {
                        SettingsRow(icon: "paintpalette.fill", color: Palette.rust, title: "Accent color", value: accent.label, chevron: true)
                    }
                    Divider().padding(.leading, 52)
                    Menu { ForEach(DisplayStyle.allCases) { item in Button(item.label) { displayStyle = item } } } label: {
                        SettingsRow(icon: "textformat", color: Color(hex: "6F7F8C"), title: "Display type", value: displayStyle.label, chevron: true)
                    }
                    Divider().padding(.leading, 52)
                    SettingsToggle(icon: "flame.fill", color: Palette.clay, title: "Reading streak", isOn: $gamified)
                    Divider().padding(.leading, 52)
                    SettingsToggle(icon: "arrow.up.left.and.arrow.down.right", color: accent.color, title: "Full-screen reading", isOn: $fullScreenReading)
                }
                SettingsSection("Storage") {
                    Button { cacheSize = 0 } label: {
                        SettingsRow(icon: "internaldrive.fill", color: Color(hex: "A98F52"), title: "Clear cache", value: cacheSize == 0 ? "Cleared" : String(format: "%.1f MB", cacheSize), chevron: true)
                    }.buttonStyle(.plain)
                }
                SettingsSection("About") {
                    SettingsRow(icon: "info.circle.fill", color: Color(hex: "6F7F8C"), title: "Version", value: "1.4.0")
                    Divider().padding(.leading, 52)
                    SettingsRow(icon: "star.fill", color: Color(hex: "A98F52"), title: "Rate Marginalia", chevron: true)
                    Divider().padding(.leading, 52)
                    SettingsRow(icon: "hand.raised.fill", color: accent.color, title: "Privacy Policy", chevron: true)
                }
                Text("API CREDITS").sectionLabel.padding(.top, 24).padding(.leading, 4)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Book data & cover art provided by **Open Library**, a project of the Internet Archive.").font(.system(size: 13)).foregroundStyle(Palette.body).lineSpacing(4)
                    Text("openlibrary.org · CC-licensed metadata").font(.system(size: 11)).foregroundStyle(Palette.muted2)
                }.padding(16).cardStyle(radius: 16).padding(.top, 8)
                Text("Marginalia — made for slow readers").font(.system(size: 15, design: .serif).italic()).foregroundStyle(Palette.muted).frame(maxWidth: .infinity).padding(.top, 28)
            }.padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 120)
        }.background(Palette.settingsBackground)
    }
}
