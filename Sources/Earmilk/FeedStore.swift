import Foundation
import Observation

@MainActor
@Observable
final class FeedStore {
    static let feedURL = URL(string: "https://hotwheelz3000.github.io/earmilk/posts.json")!

    private(set) var posts: [Post] = []
    private(set) var updated: String?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Genres ordered by how many posts use them, most common first.
    var genres: [String] {
        var counts: [String: Int] = [:]
        for post in posts where !post.genre.isEmpty {
            counts[post.genre, default: 0] += 1
        }
        return counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.map(\.key)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var request = URLRequest(url: Self.feedURL)
            // The feed updates hourly; always ask for a fresh copy.
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            let feed = try JSONDecoder().decode(Feed.self, from: data)
            // Newest first, keeping the feed's own order within a day.
            posts = feed.posts.enumerated()
                .sorted { $0.element.sortDate != $1.element.sortDate
                    ? $0.element.sortDate > $1.element.sortDate
                    : $0.offset < $1.offset }
                .map(\.element)
            updated = feed.updated
            errorMessage = nil
        } catch is CancellationError {
            // Pull-to-refresh was cancelled; keep what we have.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
