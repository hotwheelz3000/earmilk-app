import Foundation

/// What the app can learn from a post's Earmilk article page:
/// - the Spotify track or album the article embeds (checked against the song title)
///   and its 30-second preview,
/// - the best picture: the Spotify cover, else the article's own featured image.
/// The feed can't always include these (earmilk.com blocks GitHub's servers), but the phone can load them.
struct ArticleInfo: Sendable {
    enum SpotifyKind: String, Sendable { case track, album }

    var spotifyKind: SpotifyKind?
    var spotifyID: String?
    /// Spotify's 30-second preview MP3, played by the app's own preview button.
    var spotifyPreview: URL?
    var image: URL?

    /// Opens this exact song in the Spotify app.
    var spotifyAppURL: URL? {
        guard let spotifyKind, let spotifyID else { return nil }
        return URL(string: "spotify:\(spotifyKind.rawValue):\(spotifyID)")
    }

    var spotifyWebURL: URL? {
        guard let spotifyKind, let spotifyID else { return nil }
        return URL(string: "https://open.spotify.com/\(spotifyKind.rawValue)/\(spotifyID)")
    }
}

/// Loads and remembers each article's ArticleInfo while the app is open.
actor ArticleCache {
    static let shared = ArticleCache()

    private var found: [String: ArticleInfo] = [:]
    private var inFlight: [String: Task<ArticleInfo, Never>] = [:]

    func info(for post: Post) async -> ArticleInfo? {
        guard let article = post.url else { return nil }
        let key = post.id
        if let cached = found[key] { return cached }
        if let task = inFlight[key] { return await task.value }
        let task = Task { await Self.load(article: article, song: post.song) }
        inFlight[key] = task
        let result = await task.value
        found[key] = result
        inFlight[key] = nil
        return result
    }

    // MARK: - Loading

    private static func get(_ url: URL) async -> Data? {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        guard let result = try? await URLSession.shared.data(for: request),
              (result.1 as? HTTPURLResponse)?.statusCode ?? 200 < 400
        else { return nil }
        return result.0
    }

    private static func matches(_ pattern: String, in text: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { match in
            (0..<match.numberOfRanges).map { i in
                Range(match.range(at: i), in: text).map { String(text[$0]) } ?? ""
            }
        }
    }

    private struct SpotifyOEmbed: Decodable {
        let title: String?
        let thumbnail_url: String?
    }

    private static func load(article: URL, song: String) async -> ArticleInfo {
        var info = ArticleInfo()
        guard let data = await get(article) else { return info }
        let html = String(decoding: data.prefix(600_000), as: UTF8.self)
            .replacingOccurrences(of: "&amp;", with: "&")

        // Spotify: the page may also link other tracks or playlists (e.g. in a sidebar),
        // so only accept one whose title matches this post's song.
        var seen = Set<String>()
        let songCore = ITunesLookup.core(song)
        for m in matches(#"open\.spotify\.com/(?:embed/)?(track|album)/([A-Za-z0-9]{22})"#, in: html) {
            let kind = m[1].lowercased(), id = m[2]
            guard seen.insert(id).inserted, seen.count <= 6,
                  let oembedURL = URL(string: "https://open.spotify.com/oembed?url=https://open.spotify.com/\(kind)/\(id)"),
                  let json = await get(oembedURL),
                  let oembed = try? JSONDecoder().decode(SpotifyOEmbed.self, from: json),
                  let title = oembed.title
            else { continue }
            let titleCore = ITunesLookup.core(title)
            guard !titleCore.isEmpty, !songCore.isEmpty,
                  titleCore.contains(songCore) || songCore.contains(titleCore)
            else { continue }
            info.spotifyKind = ArticleInfo.SpotifyKind(rawValue: kind)
            info.spotifyID = id
            info.image = oembed.thumbnail_url.flatMap(URL.init(string:))
            // Spotify's embed page lists the preview MP3 (p.scdn.co/mp3-preview/…).
            if let embedURL = URL(string: "https://open.spotify.com/embed/\(kind)/\(id)"),
               let embed = await get(embedURL) {
                let page = String(decoding: embed, as: UTF8.self)
                    .replacingOccurrences(of: "\\/", with: "/")
                    .replacingOccurrences(of: "\\u0026", with: "&")
                if let m = matches(#"(https://p\.scdn\.co/mp3-preview/[A-Za-z0-9]+(?:\?[A-Za-z0-9=&_.%-]*)?)"#, in: page).first {
                    info.spotifyPreview = URL(string: m[1])
                }
            }
            break
        }

        // Picture fallback: the article's own featured image.
        if info.image == nil {
            for pattern in [
                #"<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)"#,
                #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']"#,
            ] {
                if let m = matches(pattern, in: html).first, let url = URL(string: m[1].trimmingCharacters(in: .whitespaces)) {
                    info.image = url
                    break
                }
            }
        }
        return info
    }
}
