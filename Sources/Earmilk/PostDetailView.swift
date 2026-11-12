import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(\.openURL) private var openURL
    @Environment(Favorites.self) private var favorites
    @State private var preview = PreviewPlayer()
    @State private var match: ITunesMatch?
    @State private var didLookUp = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let saved = favorites.contains(post)
        ScrollView {
            VStack(spacing: 20) {
                ArtworkView(url: post.largeArtwork, cornerRadius: 16, article: post.url)
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
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.spotify)
                        .buttonBorderShape(.capsule)
                    }

                    appleMusicButton
                    youTubeButton

                    if let article = post.url {
                        Link(destination: article) {
                            Label("Read on Earmilk", systemImage: "doc.text")
                                .font(.headline)
                                .foregroundStyle(Theme.text)
                                .frame(maxWidth: .infinity)
                        }
                        // Header colours: page background with header-coloured lettering,
                        // plus a thin outline so the button's shape still shows.
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(Theme.background)
                        .overlay(Capsule().strokeBorder(Theme.divider, lineWidth: 1))
                        .accessibilityHint("Opens the article in your browser")
                    }
                }
                // All buttons share one width (the widest label, about the Spotify button's size)
                // instead of stretching across the screen; .large keeps them 44pt+ tall.
                // At the largest text sizes they use the full width so labels aren't cut off.
                .controlSize(.large)
                .fixedSize(horizontal: !typeSize.isAccessibilitySize, vertical: false)
                .frame(maxWidth: 500)
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(post.song)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .solidHeader()
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
                .font(.headline)
                .frame(maxWidth: .infinity)
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
                .font(.headline)
                .frame(maxWidth: .infinity)
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
            // Every possible label is laid out invisibly underneath, so the button is always
            // as wide as its longest label and the column doesn't jump when the text changes.
            ZStack {
                ForEach(PreviewPlayer.State.allCases, id: \.self) { state in
                    previewLabel(for: state).hidden()
                }
                previewLabel(for: preview.state)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(Theme.accent)
        .disabled(preview.state == .unavailable || preview.state == .loading)
    }

    @ViewBuilder
    private func previewLabel(for state: PreviewPlayer.State) -> some View {
        switch state {
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
}
