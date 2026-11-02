import SwiftUI

struct ContentView: View {
    @State private var store = FeedStore()
    @State private var favorites = Favorites()
    @State private var path: [Post] = []
    @State private var selectedGenre: String?
    @State private var savedOnly = false
    @State private var searchText = ""
    @AppStorage("appearance") private var appearance = Appearance.system
    @Environment(\.openURL) private var openURL

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var visiblePosts: [Post] {
        var posts = store.posts
        if savedOnly {
            posts = posts.filter { favorites.contains($0) }
        }
        if let selectedGenre {
            posts = posts.filter { $0.genre == selectedGenre }
        }
        let query = trimmedSearch
        if !query.isEmpty {
            posts = posts.filter {
                $0.artist.localizedCaseInsensitiveContains(query)
                    || $0.song.localizedCaseInsensitiveContains(query)
            }
        }
        return posts
    }

    private func accessibilityValue(for post: Post, saved: Bool) -> String {
        [post.genre, post.date, saved ? "Saved" : ""].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if !store.genres.isEmpty {
                    genreBar
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Theme.background)
                }
                if savedOnly {
                    Text("Saved songs")
                        .earmilkLabel(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                        .accessibilityAddTraits(.isHeader)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Theme.background)
                }
                ForEach(visiblePosts) { post in
                    let saved = favorites.contains(post)
                    Button {
                        path.append(post)
                    } label: {
                        ArtworkHeader(post: post, isSaved: saved)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Theme.background)
                    .accessibilityLabel("\(post.song), by \(post.artist)")
                    .accessibilityValue(accessibilityValue(for: post, saved: saved))
                    .accessibilityHint("Opens the song page")
                    .accessibilityAction(named: Text(saved ? "Unsave" : "Save")) {
                        favorites.toggle(post)
                    }
                    .accessibilityAction(named: Text("Open in Spotify")) {
                        openURL.open(app: post.spotifyAppURL, web: post.spotifyURL)
                    }
                    .contextMenu {
                        Button {
                            favorites.toggle(post)
                        } label: {
                            Label(saved ? "Unsave" : "Save", systemImage: saved ? "star.slash" : "star")
                        }
                        Button {
                            openURL.open(app: post.spotifyAppURL, web: post.spotifyURL)
                        } label: {
                            Label("Open in Spotify", systemImage: "play.circle")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            favorites.toggle(post)
                        } label: {
                            Label(saved ? "Unsave" : "Save", systemImage: saved ? "star.slash" : "star")
                        }
                        .tint(Theme.saveAction)
                    }
                }
                if let updated = store.updated, !visiblePosts.isEmpty {
                    Text("Updated \(updated)")
                        .earmilkMeta(.caption2)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Theme.background)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .searchable(text: $searchText, prompt: "Artist or song")
            .navigationTitle(selectedGenre ?? (savedOnly ? "Saved" : "Earmilk"))
            .earmilkNavigationBar()
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
            .overlay { statusOverlay }
            .refreshable { await store.load() }
            .task {
                if store.posts.isEmpty { await store.load() }
            }
            .toolbar {
                ToolbarItem(placement: .principal) { Wordmark() }
                ToolbarItem(placement: .primaryAction) { filterMenu }
                ToolbarItem(placement: .secondaryAction) {
                    Toggle(isOn: $savedOnly) {
                        Label("Saved Only", systemImage: "star")
                    }
                }
                ToolbarItem(placement: .secondaryAction) { appearanceMenu }
            }
        }
        .tint(Theme.text)
        .environment(favorites)
        .preferredColorScheme(appearance.colorScheme)
    }

    private var genreBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                genreButton(title: "All", genre: nil)
                ForEach(store.genres, id: \.self) { genre in
                    genreButton(title: genre, genre: genre)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    /// A genre label with a 44pt-tall tap area. Selected = filled; others = outlined.
    private func genreButton(title: String, genre: String?) -> some View {
        let isSelected = selectedGenre == genre
        return Button {
            selectedGenre = (genre == nil || isSelected) ? nil : genre
        } label: {
            GenrePill(genre: title, filled: isSelected)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(genre == nil ? "All genres" : title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var filterMenu: some View {
        Menu {
            Picker("Genre", selection: $selectedGenre) {
                Text("All genres").tag(String?.none)
                ForEach(store.genres, id: \.self) { genre in
                    Text(genre).tag(String?.some(genre))
                }
            }
        } label: {
            Label("Filter",
                  systemImage: selectedGenre == nil
                      ? "line.3.horizontal.decrease.circle"
                      : "line.3.horizontal.decrease.circle.fill")
        }
    }

    private var appearanceMenu: some View {
        Menu {
            Picker("Appearance", selection: $appearance) {
                ForEach(Appearance.allCases) { option in
                    Label(option.title, systemImage: option.symbol).tag(option)
                }
            }
        } label: {
            Label("Appearance", systemImage: "circle.lefthalf.filled")
        }
    }

    @ViewBuilder
    private var statusOverlay: some View {
        if store.posts.isEmpty {
            if store.isLoading {
                ProgressView("Loading feed…")
            } else if let error = store.errorMessage {
                ContentUnavailableView {
                    Label("Couldn't load the feed", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") { Task { await store.load() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        } else if visiblePosts.isEmpty {
            if !trimmedSearch.isEmpty {
                ContentUnavailableView.search(text: trimmedSearch)
            } else if savedOnly {
                ContentUnavailableView(
                    "No saved songs",
                    systemImage: "star",
                    description: Text("Swipe right on a song, or tap the star on its page, to save it.")
                )
            } else if let selectedGenre {
                ContentUnavailableView("No \(selectedGenre) posts", systemImage: "music.note.list")
            }
        }
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
