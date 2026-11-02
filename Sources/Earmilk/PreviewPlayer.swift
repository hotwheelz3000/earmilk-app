import AVFoundation
import Foundation
import Observation

/// Plays Apple's free 30-second preview of a song, found with the iTunes Search API.
@MainActor
@Observable
final class PreviewPlayer {
    enum State { case idle, loading, playing, paused, unavailable }

    private(set) var state: State = .idle

    @ObservationIgnored private var player: AVPlayer?
    @ObservationIgnored private var endObserver: NSObjectProtocol?

    func toggle(for post: Post) async {
        switch state {
        case .playing:
            player?.pause()
            state = .paused
        case .paused:
            player?.play()
            state = .playing
        case .loading, .unavailable:
            return
        case .idle:
            state = .loading
            guard let url = await Self.previewURL(for: post) else {
                state = .unavailable
                return
            }
            // Don't start if the page was closed while searching.
            guard state == .loading else { return }
            #if os(iOS)
            // .playback so the preview is heard even with the ring/silent switch on silent.
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
            #endif
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            endObserver = NotificationCenter.default.addObserver(
                forName: AVPlayerItem.didPlayToEndTimeNotification,
                object: item,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.stop() }
            }
            self.player = player
            player.play()
            state = .playing
        }
    }

    /// Stops playback and returns to the start, e.g. when leaving the page.
    func stop() {
        player?.pause()
        player = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
        if state != .unavailable {
            state = .idle
        }
    }

    // MARK: - iTunes Search

    private struct SearchResponse: Decodable {
        let results: [Track]
    }

    private struct Track: Decodable {
        let artistName: String?
        let trackName: String?
        let previewUrl: URL?
    }

    /// The song title without "(feat. …)", "ft. …" or "[…]", lowercased.
    private static func core(_ title: String) -> String {
        var t = title.lowercased()
        for marker in [" (", " [", " feat", " ft.", " ft "] {
            if let range = t.range(of: marker) {
                t = String(t[..<range.lowerBound])
            }
        }
        return t.trimmingCharacters(in: .whitespaces)
    }

    private static func previewURL(for post: Post) async -> URL? {
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
        let artist = post.artist.lowercased()
        // The title must match, so a wrong song is never played; a matching artist wins ties.
        var best: (score: Int, url: URL)?
        for track in response.results {
            guard let preview = track.previewUrl, let name = track.trackName else { continue }
            let trackCore = core(name)
            guard !song.isEmpty, trackCore.contains(song) || song.contains(trackCore) else { continue }
            let trackArtist = (track.artistName ?? "").lowercased()
            var score = 1
            if !trackArtist.isEmpty, artist.contains(trackArtist) || trackArtist.contains(artist) {
                score += 2
            }
            if trackCore == song { score += 1 }
            if best == nil || score > best!.score {
                best = (score, preview)
            }
        }
        return best?.url
    }
}
