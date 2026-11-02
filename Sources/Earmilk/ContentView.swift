import SwiftUI

struct ContentView: View {
    @State private var store = FeedStore()
    @State private var favorites = Favorites()
    @State private var selectedGenre: String?
    @State private var savedOnly = false
    @State private var searchText = ""
    @AppStorage("appearance") private var appearance = Appearance.system

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

    var body: some View {
        NavigationStack {
            List {
                if !store.genres.isEmpty {
                    genreBar
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
                ForEach(visiblePosts) { post in
                    let saved = favorites.contains(post)
                    NavigationLink(value: post) {
                        PostRow(post: post, isSaved: saved)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            favorites.toggle(post)
                        } label: {
                            Label(saved ? "Unsave" : "Save", systemImage: saved ? "star.slash" : "star")
                        }
                        .tint(.yellow)
                    }
                }
                if let updated = store.updated, !visiblePosts.isEmpty {
                    Text("Updated \(updated)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Artist or song")
            .navigationTitle(selectedGenre ?? (savedOnly ? "Saved" : "Earmilk"))
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
            .overlay { statusOverlay }
            .refreshable { await store.load() }
            .task {
                if store.posts.isEmpty { await store.load() }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) { filterMenu }
                ToolbarItem(placement: .secondaryAction) {
                    Toggle(isOn: $savedOnly) {
                        Label("Saved Only", systemImage: "star")
                    }
                }
                ToolbarItem(placement: .secondaryAction) { appearanceMenu }
            }
        }
        .environment(favorites)
        .tint(.green)
        .preferredColorScheme(appearance.colorScheme)
    }

    private var genreBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button { selectedGenre = nil } label: {
                    GenrePill(genre: "All", isSelected: selectedGenre == nil)
                }
                ForEach(store.genres, id: \.self) { genre in
                    Button {
                        selectedGenre = selectedGenre == genre ? nil : genre
                    } label: {
                        GenrePill(genre: genre, isSelected: selectedGenre == genre)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
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

struct PostRow: View {
    let post: Post
    var isSaved = false

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(url: post.artwork)
                .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 3) {
                Text(post.song)
                    .font(.headline)
                    .lineLimit(2)
                Text(post.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if !post.genre.isEmpty {
                        GenrePill(genre: post.genre)
                    }
                    Text(post.date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    if isSaved {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
        .padding(.vertical, 2)
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
