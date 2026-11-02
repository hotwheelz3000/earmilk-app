import AVFoundation
import Foundation
import Observation

/// Plays Apple's free 30-second preview of a song.
@MainActor
@Observable
final class PreviewPlayer {
    enum State: CaseIterable { case idle, loading, playing, paused, unavailable }

    private(set) var state: State = .idle

    @ObservationIgnored private var player: AVPlayer?
    @ObservationIgnored private var endObserver: NSObjectProtocol?

    /// Play, pause or resume. `loadURL` finds the preview the first time.
    func toggle(loadURL: () async -> URL?) async {
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
            let url = await loadURL()
            // Don't start if the page was closed while searching.
            guard state == .loading else { return }
            guard let url else {
                state = .unavailable
                return
            }
            start(url)
        }
    }

    private func start(_ url: URL) {
        #if os(iOS)
        // .playback so the preview is heard with the silent switch on, and (with the
        // "audio" background mode in Earmilk-Info.plist) keeps playing when you leave the app.
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
}
