import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(\.openURL) private var openURL
    @Environment(Favorites.self) private var favorites
    @State private var preview = PreviewPlayer()

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
                    previewButton

                    if post.spotifyURL != nil {
                        Button {
                            open(app: post.spotifyAppURL, web: post.spotifyURL)
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

                    HStack(spacing: 12) {
                        if post.appleMusicURL != nil {
                            Button {
                                open(app: post.appleMusicAppURL, web: post.appleMusicURL)
                            } label: {
                                Label("Apple Music", systemImage: "music.note")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .tint(Color(red: 0.98, green: 0.24, blue: 0.33))
                        }
                        if post.youTubeURL != nil {
                            Button {
                                open(app: post.youTubeAppURL, web: post.youTubeURL)
                            } label: {
                                Label("YouTube", systemImage: "play.rectangle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .tint(.red)
                        }
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                let saved = favorites.contains(post)
                Button {
                    favorites.toggle(post)
                } label: {
                    Label(saved ? "Unsave" : "Save", systemImage: saved ? "star.fill" : "star")
                }
                .tint(.yellow)
            }
        }
        .onDisappear { preview.stop() }
    }

    @ViewBuilder
    private var previewButton: some View {
        Button {
            Task { await preview.toggle(for: post) }
        } label: {
            Group {
                switch preview.state {
                case .loading:
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Finding preview…")
                    }
                case .playing:
                    Label("Pause Preview", systemImage: "pause.fill")
                case .paused:
                    Label("Resume Preview", systemImage: "play.fill")
                case .unavailable:
                    Label("No preview available", systemImage: "speaker.slash")
                case .idle:
                    Label("Play 30-sec Preview", systemImage: "play.fill")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .disabled(preview.state == .unavailable || preview.state == .loading)
    }

    /// Tries the app link first and falls back to the website if the app isn't installed.
    private func open(app: URL?, web: URL?) {
        guard let web else { return }
        guard let app else {
            openURL(web)
            return
        }
        openURL(app) { accepted in
            if !accepted { openURL(web) }
        }
    }
}
