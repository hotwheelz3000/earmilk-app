import Foundation

/// For posts with no cover art: finds the Earmilk article's own featured image
/// (its og:image) and remembers it while the app is open. Earmilk blocks GitHub's
/// servers, so the feed can't always include these; the phone can load them.
actor ArticleImageCache {
    static let shared = ArticleImageCache()

    private var found: [URL: URL?] = [:]
    private var inFlight: [URL: Task<URL?, Never>] = [:]

    func image(for article: URL) async -> URL? {
        if let cached = found[article] { return cached }
        if let task = inFlight[article] { return await task.value }
        let task = Task { await Self.ogImage(of: article) }
        inFlight[article] = task
        let result = await task.value
        found[article] = result
        inFlight[article] = nil
        return result
    }

    private static func ogImage(of article: URL) async -> URL? {
        var request = URLRequest(url: article, timeoutInterval: 15)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        guard let result = try? await URLSession.shared.data(for: request) else { return nil }
        let html = String(decoding: result.0.prefix(300_000), as: UTF8.self)
        let patterns = [
            #"<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  let range = Range(match.range(at: 1), in: html)
            else { continue }
            let link = html[range]
                .replacingOccurrences(of: "&amp;", with: "&")
                .trimmingCharacters(in: .whitespaces)
            if let url = URL(string: link) { return url }
        }
        return nil
    }
}
