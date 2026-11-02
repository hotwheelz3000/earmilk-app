import SwiftUI

/// Genre colours, grouped the same way as the Earmilk website.
/// Same colour families as before, lightened so black text on them is easy to read
/// (every colour here gives at least 8:1 contrast with black text).
enum GenreStyle {
    static func color(for genre: String) -> Color {
        let g = genre.lowercased()
        if g.contains("hip") || g.contains("rap") { return Color(hex: 0xFFA726) }        // orange
        if g.contains("electro") || g.contains("house") || g.contains("dance") || g.contains("ambient") {
            return Color(hex: 0x4FC3F7)                                                     // blue
        }
        if g.contains("folk") || g.contains("americana") || g.contains("country") { return Color(hex: 0xAED581) } // olive green
        if g.contains("rock") || g.contains("alt") { return Color(hex: 0xFF8A65) }        // red-orange
        if g.contains("r&b") || g.contains("soul") || g.contains("jazz") { return Color(hex: 0xCE93D8) } // purple
        if g.contains("pop") { return Color(hex: 0xF48FB1) }                                // pink
        if g.contains("indie") { return Color(hex: 0x81C784) }                              // green
        return Color(hex: 0xBDBDBD)                                                         // grey
    }
}

/// A square genre label in spaced capitals.
/// Filled: genre colour with black text. Outline (unselected in the genre bar): genre-colour border.
struct GenrePill: View {
    let genre: String
    var filled = true

    var body: some View {
        let color = GenreStyle.color(for: genre)
        Text(genre)
            .earmilkLabel(.caption2)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .foregroundStyle(filled ? Color.black : Theme.text)
            .background(filled ? color : Color.clear)
            .overlay(Rectangle().strokeBorder(color, lineWidth: filled ? 0 : 2))
    }
}
