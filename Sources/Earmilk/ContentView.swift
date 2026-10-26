import SwiftUI

struct ContentView: View {
    @State private var store = FeedStore()
    @State private var selectedGenre: String?
    @AppStorage("appearance") private var appearance = Appearance.system

    private var visiblePosts: [Post] {
        guard let selectedGenre else { return store.posts }
        return store.posts.filter { $0.genre == selectedGenre }
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
                    NavigationLink(value: post) {
                        PostRow(post: post)
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
            .navigationTitle(selectedGenre ?? "Earmilk")
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
                ToolbarItem(placement: .secondaryAction) { appearanceMenu }
            }
        }
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
        } else if visiblePosts.isEmpty, let selectedGenre {
            ContentUnavailableView("No \(selectedGenre) posts", systemImage: "music.note.list")
        }
    }
}

struct PostRow: View {
    let post: Post

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
