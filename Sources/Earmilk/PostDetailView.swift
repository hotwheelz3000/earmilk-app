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
            VStack(spacing: 0) {
                ArtworkHeader(post: post, isSaved: saved, large: true)
                    .frame(maxWidth: 700)
                    .accessibilityElement(children: .combine)

                VStack(spacing: 12) {
                    previewButton

                    if post.spotifyURL != nil {
                        Button {
                            openURL.open(app: post.spotifyAppURL, web: post.spotifyURL)
                        } label: {
                            Label("Open in Spotify", systemImage: "play.circle.fill")
                        }
                        .buttonStyle(EarmilkButtonStyle(prominent: true))
                    }

                    if post.appleMusicURL != nil {
                        Button {
                            Task {
                                // The exact song's Apple Music link opens it in the Music app;
                                // fall back to Apple Music's web search if it isn't found.
                                let page = await lookUp()?.page
                                openURL.open(app: page, web: post.appleMusicURL)
                            }
                        } label: {
                            Label("Apple Music", systemImage: "music.note")
                        }
                        .buttonStyle(EarmilkButtonStyle())
                    }

                    if post.youTubeURL != nil {
                        Button {
                            openURL.open(app: post.youTubeAppURL, web: post.youTubeURL)
                        } label: {
                            Label("YouTube", systemImage: "play.rectangle.fill")
                        }
                        .buttonStyle(EarmilkButtonStyle())
                    }

                    if let article = post.url {
                        Link(destination: article) {
                            Label("Read on Earmilk", systemImage: "doc.text")
                        }
                        .buttonStyle(EarmilkButtonStyle())
                        .accessibilityHint("Opens the article in your browser")
                    }
                }
                .padding(16)
                .padding(.top, 8)
                .frame(maxWidth: 500)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle(post.song)
        .earmilkNavigationBar()
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
                        ProgressView().tint(.white)
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
        .buttonStyle(EarmilkButtonStyle())
        .disabled(preview.state == .unavailable || preview.state == .loading)
    }
}
