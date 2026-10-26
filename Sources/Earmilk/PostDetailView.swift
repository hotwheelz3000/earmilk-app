import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ArtworkView(url: post.largeArtwork, cornerRadius: 16)
                    .frame(maxWidth: 500)
                    .shadow(color: .black.opacity(0.25), radius: 16, y: 8)

                VStack(spacing: 6) {
                    Text(post.song)
                        .font(.title.bold())
                    Text(post.artist)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        if !post.genre.isEmpty {
                            GenrePill(genre: post.genre)
                        }
                        Text(post.date)
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 4)
                }
                .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    if let spotify = post.spotifyURL {
                        Button {
                            openURL(spotify)
                        } label: {
                            Label("Open in Spotify", systemImage: "play.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.11, green: 0.73, blue: 0.33))
                        .buttonBorderShape(.capsule)
                    }
                    if let article = post.url {
                        Link(destination: article) {
                            Label("Read on Earmilk", systemImage: "doc.text")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                }
                .frame(maxWidth: 500)
            }
            .padding()
        }
        .navigationTitle(post.song)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
