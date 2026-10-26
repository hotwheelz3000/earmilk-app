import Foundation

/// The top-level shape of posts.json: `{ "updated": "...", "posts": [...] }`.
struct Feed: Decodable, Sendable {
    let updated: String?
    let posts: [Post]
}

struct Post: Decodable, Hashable, Identifiable, Sendable {
    let artist: String
    let song: String
    let genre: String
    /// Display date, e.g. "Aug 15".
    let date: String
    /// Sortable date, e.g. "20260815".
    let sortDate: String
    /// The Earmilk article.
    let url: URL?
    let artwork: URL?

    // A few articles cover several songs, so the URL alone isn't unique.
    var id: String { (url?.absoluteString ?? "") + "|" + artist + "|" + song }

    /// Spotify has no link in the feed, so search for the track, as the website does.
    var spotifyURL: URL? {
        let query = [artist, song].filter { !$0.isEmpty }.joined(separator: " ")
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        return URL(string: "https://open.spotify.com/search/" + encoded)
    }

    /// Apple artwork URLs end in a size like "400x400bb.jpg"; ask for a bigger one.
    var largeArtwork: URL? {
        guard let artwork, artwork.host()?.hasSuffix("mzstatic.com") == true else { return artwork }
        let path = artwork.absoluteString.replacingOccurrences(
            of: #"/\d+x\d+bb\.(jpg|png)$"#,
            with: "/1000x1000bb.$1",
            options: .regularExpression
        )
        return URL(string: path) ?? artwork
    }

    enum CodingKeys: String, CodingKey {
        case artist, song, genre, date, url, artwork
        case sortDate = "sort_date"
    }

    // Decode leniently so one odd entry can't break the whole feed.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        artist = (try? c.decode(String.self, forKey: .artist)) ?? ""
        song = (try? c.decode(String.self, forKey: .song)) ?? ""
        genre = (try? c.decode(String.self, forKey: .genre)) ?? ""
        date = (try? c.decode(String.self, forKey: .date)) ?? ""
        sortDate = (try? c.decode(String.self, forKey: .sortDate)) ?? ""
        url = (try? c.decode(String.self, forKey: .url)).flatMap(URL.init(string:))
        artwork = (try? c.decode(String.self, forKey: .artwork)).flatMap(URL.init(string:))
    }
}
