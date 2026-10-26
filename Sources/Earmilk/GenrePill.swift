import SwiftUI

/// Genre colours, grouped the same way as the Earmilk website.
enum GenreStyle {
    static func color(for genre: String) -> Color {
        let g = genre.lowercased()
        if g.contains("hip") || g.contains("rap") { return .orange }
        if g.contains("electro") || g.contains("house") || g.contains("dance") || g.contains("ambient") { return .blue }
        if g.contains("folk") || g.contains("americana") || g.contains("country") { return Color(red: 0.45, green: 0.62, blue: 0.2) }
        if g.contains("rock") || g.contains("alt") { return Color(red: 0.9, green: 0.4, blue: 0.15) }
        if g.contains("r&b") || g.contains("soul") || g.contains("jazz") { return .purple }
        if g.contains("pop") { return .pink }
        if g.contains("indie") { return .green }
        return .gray
    }
}

struct GenrePill: View {
    let genre: String
    var isSelected = false

    var body: some View {
        let color = GenreStyle.color(for: genre)
        Text(genre)
            .font(.caption.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(isSelected ? Color.white : color)
            .background(isSelected ? color : color.opacity(0.16), in: Capsule())
    }
}
