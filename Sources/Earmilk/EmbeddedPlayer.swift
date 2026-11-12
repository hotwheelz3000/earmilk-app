import SwiftUI
import WebKit

/// A Spotify or SoundCloud web player embedded in the song page.
struct EmbeddedPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.scrollView.backgroundColor = .clear
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        if web.url == nil { web.load(URLRequest(url: url)) }
    }

    static func dismantleUIView(_ web: WKWebView, coordinator: ()) {
        // Stop playback when leaving the song page.
        web.loadHTMLString("", baseURL: nil)
    }
}
