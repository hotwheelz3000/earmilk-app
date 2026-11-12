import SwiftUI

/// Square artwork. Decorative for VoiceOver: the row or page around it names the song.
struct ArtworkView: View {
    let url: URL?
    var cornerRadius: CGFloat = 8
    /// The Earmilk article; its own image is shown when there's no cover art.
    var article: URL? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var articleImage: URL?

    var body: some View {
        AsyncImage(
            url: url ?? articleImage,
            transaction: Transaction(animation: reduceMotion ? nil : .easeOut(duration: 0.2))
        ) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                ZStack {
                    Rectangle().fill(Color(light: 0xE6E6E6, dark: 0x2E2E2E))
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
        .task(id: url) {
            guard url == nil, let article else { return }
            articleImage = await ArticleImageCache.shared.image(for: article)
        }
    }
}
