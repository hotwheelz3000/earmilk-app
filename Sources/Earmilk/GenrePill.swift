import SwiftUI

/// Genre colours, grouped the same way as the Earmilk website.
/// Same colour families as before, adjusted to stay readable: lighter shades in dark mode,
/// deeper shades in light mode (text contrast at least 4.5:1 either way).
enum GenreStyle {
    static func color(for genre: String) -> Color {
        let g = genre.lowercased()
        if g.contains("hip") || g.contains("rap") { return Color(light: 0x9A4A06, dark: 0xFFA726) }   // orange
        if g.contains("electro") || g.contains("house") || g.contains("dance") || g.contains("ambient") {
            return Color(light: 0x0369A1, dark: 0x4FC3F7)                                                // blue
        }
        if g.contains("folk") || g.contains("americana") || g.contains("country") {
            return Color(light: 0x3F6212, dark: 0xAED581)                                                // olive green
        }
        if g.contains("rock") || g.contains("alt") { return Color(light: 0xB33A0C, dark: 0xFF8A65) }   // red-orange
        if g.contains("r&b") || g.contains("soul") || g.contains("jazz") {
            return Color(light: 0x7E22CE, dark: 0xCE93D8)                                                // purple
        }
        if g.contains("pop") { return Color(light: 0xBE185D, dark: 0xF48FB1) }                         // pink
        if g.contains("indie") { return Color(light: 0x166534, dark: 0x81C784) }                       // green
        return Color(light: 0x525252, dark: 0xBDBDBD)                                                  // grey
    }

    /// Text on a filled (selected) pill: white on the deep light-mode shades, black on the light dark-mode shades.
    static let selectedText = Color(light: 0xFFFFFF, dark: 0x000000)
}

struct GenrePill: View {
    let genre: String
    var isSelected = false

    var body: some View {
        let color = GenreStyle.color(for: genre)
        Text(genre)
            .earmilkLabel(.caption2)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(isSelected ? GenreStyle.selectedText : color)
            .background(isSelected ? color : color.opacity(0.12), in: Capsule())
    }
}
