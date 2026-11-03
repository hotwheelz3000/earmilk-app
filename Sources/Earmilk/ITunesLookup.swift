import Foundation

/// A song found on Apple's catalog: its 30-second preview and its Apple Music page.
struct ITunesMatch: Sendable {
    let preview: URL?
    let page: URL?
}

/// Finds a post's song with the free iTunes Search API.
enum ITunesLookup {
    private struct SearchResponse: Decodable {
        let results: [Track]
    }

    private struct Track: Decodable {
        let artistName: String?
        let trackName: String?
        let previewUrl: URL?
        let trackViewUrl: URL?
    }

    /// The song title without "(feat. …)", "ft. …" or "[…]", lowercased.
    static func core(_ title: String) -> String {
        var t = title.lowercased()
        for marker in [" (", " [", " feat", " ft.", " ft "] {
            if let range = t.range(of: marker) {
                t = String(t[..<range.lowerBound])
            }
        }
        return t.trimmingCharacters(in: .whitespaces)
    }

    /// Lowercased letters and digits only.
    private static func norm(_ s: String) -> String {
        String(s.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
    }

    /// True if any of the post's artist names (split on , & x feat. with) matches iTunes' artist.
    static func artistMatches(_ postArtist: String, _ itunesArtist: String) -> Bool {
        let ia = norm(itunesArtist)
        guard ia.count >= 2 else { return false }
        let names = postArtist.replacingOccurrences(
            of: #"\s*(,|&|\+|\band\b|\bx\b|\bfeat\.?|\bft\.?|\bwith\b)\s*"#,
            with: "|",
            options: [.regularExpression, .caseInsensitive]
        ).split(separator: "|")
        return names.contains { name in
            let n = norm(String(name))
            return n.count >= 2 && (ia.contains(n) || n.contains(ia))
        }
    }

    /// The best match, or nil. The artist AND the title must match, so a different
    /// song with a similar title (e.g. "The Way You Love Me" for "The Way You Love")
    /// or another song by the same artist is never used. An exact title wins ties.
    static func match(for post: Post) async -> ITunesMatch? {
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: "\(post.artist) \(core(post.song))"),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "country", value: "US"),
            URLQueryItem(name: "limit", value: "15"),
        ]
        guard let url = components.url,
              let result = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(SearchResponse.self, from: result.0)
        else { return nil }

        let song = core(post.song)
        guard !song.isEmpty else { return nil }

        var best: (score: Int, track: Track)?
        for track in response.results {
            guard let name = track.trackName,
                  artistMatches(post.artist, track.artistName ?? "") else { continue }
            let trackCore = core(name)
            guard !trackCore.isEmpty, trackCore.contains(song) || song.contains(trackCore) else { continue }
            var score = 1
            if trackCore == song { score += 2 }
            if track.previewUrl != nil { score += 1 }
            if best == nil || score > best!.score {
                best = (score, track)
            }
        }
        guard let track = best?.track else { return nil }
        return ITunesMatch(preview: track.previewUrl, page: track.trackViewUrl)
    }
}
