import SwiftUI

/// Square artwork. Decorative for VoiceOver: the surrounding card or header names the song.
struct ArtworkView: View {
    let url: URL?
    var cornerRadius: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        AsyncImage(
            url: url,
            transaction: Transaction(animation: reduceMotion ? nil : .easeOut(duration: 0.2))
        ) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                ZStack {
                    Rectangle().fill(Color(light: 0xE6E6E6, dark: 0x2E2E2E))
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// Artwork with the genre, title and artist laid over a dark fade, like the post cards
/// and article headers on earmilk.com. At the largest text sizes the text moves below
/// the artwork so nothing gets cut off.
struct ArtworkHeader: View {
    let post: Post
    var isSaved = false
    /// Larger type for the song page.
    var large = false

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                ArtworkView(url: post.largeArtwork)
                details(onImage: false)
                    .padding(.horizontal, large ? 16 : 0)
            }
        } else {
            ArtworkView(url: post.largeArtwork)
                .overlay {
                    // Dark enough behind the text for white text to stay readable on bright artwork.
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.25),
                            .init(color: .black.opacity(0.6), location: 0.55),
                            .init(color: .black.opacity(0.92), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .accessibilityHidden(true)
                }
                .overlay(alignment: .bottomLeading) {
                    details(onImage: true)
                        .padding(large ? 20 : 16)
                }
        }
    }

    private func details(onImage: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                if !post.genre.isEmpty {
                    GenrePill(genre: post.genre)
                }
                Spacer(minLength: 0)
                if isSaved {
                    Image(systemName: "star.fill")
                        .font(.headline)
                        .foregroundStyle(onImage ? Color.yellow : Theme.text)
                        .accessibilityLabel("Saved")
                }
            }
            Text(post.song)
                .font(large ? .largeTitle : .title2)
                .foregroundStyle(onImage ? Color.white : Theme.text)
                .lineLimit(onImage ? 3 : nil)
                .accessibilityAddTraits(large ? .isHeader : [])
            Text(post.artist)
                .font(large ? .title3.weight(.semibold) : .headline)
                .foregroundStyle(onImage ? Color.white : Theme.text)
                .lineLimit(onImage ? 2 : nil)
            if !post.date.isEmpty {
                Text(post.date)
                    .earmilkMeta(.caption)
                    .foregroundStyle(onImage ? Color.white.opacity(0.85) : Theme.secondaryText)
            }
        }
        .multilineTextAlignment(.leading)
        .shadow(color: .black.opacity(onImage ? 0.5 : 0), radius: 3, y: 1)
    }
}
