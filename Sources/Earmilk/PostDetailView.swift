import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(\.openURL) private var openURL
    @Environment(Favorites.self) private var favorites
    @State private var preview = PreviewPlayer()
    @State private var match: ITunesMatch?
    @State private var didLookUp = false

    var body: some View {
        let saved = favorites.contains(post)
        ScrollView {
            VStack(spacing: 20) {
                ArtworkView(url: post.largeArtwork, cornerRadius: 16)
                    .frame(maxWidth: 500)
                    .shadow(color: .black.opacity(0.25), radius: 16, y: 8)

                VStack(spacing: 8) {
                    Text(post.song)
                        .font(.title.bold())
                        .foregroundStyle(Theme.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(post.artist)
                        .font(.title3)
                        .foregroundStyle(Theme.secondaryText)
                    ViewThatFits {
                        HStack(spacing: 8) { genreAndDate }
                        VStack(spacing: 6) { genreAndDate }
                    }
                    .padding(.top, 4)
                }
                .multilineTextAlignment(.center)
                .accessibilityElement(children: .combine)

                VStack(spacing: 12) {
                    previewButton

                    if post.spotifyURL != nil {
                        Button {
                            openURL.open(app: post.spotifyAppURL, web: post.spotifyURL)
                        } label: {
                            Label("Open in Spotify", systemImage: "play.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.spotify)
                        .buttonBorderShape(.capsule)
                    }

                    // Side by side when they fit; stacked at large text sizes.
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { appleMusicButton; youTubeButton }
                        VStack(spacing: 12) { appleMusicButton; youTubeButton }
                    }

                    if let article = post.url {
                        Link(destination: article) {
                            Label("Read on Earmilk", systemImage: "doc.text")
                                .padding(.horizontal, 4)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .tint(Theme.accent)
                        .accessibilityHint("Opens the article in your browser")
                    }
                }
                // Buttons sized to their labels, not stretched; .large keeps them 44pt+ tall.
                .controlSize(.large)
                .frame(maxWidth: 500)
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(post.song)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    favorites.toggle(post)
                } label: {
                    Label(saved ? "Unsave" : "Save", systemImage: saved ? "star.fill" : "star")
                }
                .accessibilityLabel(saved ? "Saved. Remove from saved songs" : "Save song")
            }
        }
        .task { _ = await lookUp() }
        .onDisappear { preview.stop() }
    }

    @ViewBuilder
    private var genreAndDate: some View {
        if !post.genre.isEmpty {
            GenrePill(genre: post.genre)
        }
        Text(post.date)
            .font(.subheadline)
            .foregroundStyle(Theme.secondaryText)
    }

    private var appleMusicButton: some View {
        Button {
            Task {
                // The exact song's Apple Music link opens it in the Music app;
                // fall back to Apple Music's web search if it isn't found.
                let page = await lookUp()?.page
                openURL.open(app: page, web: post.appleMusicURL)
            }
        } label: {
            Label("Apple Music", systemImage: "music.note")
                .padding(.horizontal, 4)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(Theme.appleMusic)
    }

    private var youTubeButton: some View {
        Button {
            openURL.open(app: post.youTubeAppURL, web: post.youTubeURL)
        } label: {
            Label("YouTube", systemImage: "play.rectangle.fill")
                .padding(.horizontal, 4)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(Theme.youTube)
    }

    /// Finds the song on Apple's catalog once; used by the preview and Apple Music buttons.
    private func lookUp() async -> ITunesMatch? {
        if !didLookUp {
            match = await ITunesLookup.match(for: post)
            didLookUp = true
        }
        return match
    }

    private var previewButton: some View {
        Button {
            Task { await preview.toggle { await lookUp()?.preview } }
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
            .padding(.horizontal, 4)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(Theme.accent)
        .disabled(preview.state == .unavailable || preview.state == .loading)
    }
}
