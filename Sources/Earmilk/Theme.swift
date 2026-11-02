import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Colours styled after earmilk.com: charcoal background, white titles, grey body text.
/// Text colours meet WCAG AA contrast (4.5:1) on their backgrounds in light and dark mode.
enum Theme {
    static let background = Color(light: 0xFFFFFF, dark: 0x222222)
    static let divider = Color(light: 0xC8C8C8, dark: 0x4A4A4A)
    /// Main text: #111 on white (18:1), white on #222 (15.9:1).
    static let text = Color(light: 0x111111, dark: 0xFFFFFF)
    /// Secondary text: #555 on white (7.5:1), #B3B3B3 on #222 (7.6:1).
    static let secondaryText = Color(light: 0x555555, dark: 0xB3B3B3)
    /// Swipe-action background for Save; white text on it is 4.7:1.
    static let saveAction = Color(hex: 0x8A6500)
    /// App tint (links, toolbar icons, bordered buttons): green that reads on both backgrounds.
    static let accent = Color(light: 0x15803D, dark: 0x4ADE80)
    /// Saved-song star.
    static let star = Color(light: 0x9A6700, dark: 0xFFD60A)
    /// Button tints for Apple Music and YouTube, readable on both backgrounds.
    static let appleMusic = Color(light: 0xC81E3A, dark: 0xFF6B7F)
    static let youTube = Color(light: 0xC4161C, dark: 0xFF6B6B)
    /// Spotify green; black text on it is 8.6:1.
    static let spotify = Color(hex: 0x1ED760)
}

private func components(_ hex: UInt32) -> (red: Double, green: Double, blue: Double) {
    (Double((hex >> 16) & 0xFF) / 255, Double((hex >> 8) & 0xFF) / 255, Double(hex & 0xFF) / 255)
}

extension Color {
    init(hex: UInt32) {
        let c = components(hex)
        self.init(red: c.red, green: c.green, blue: c.blue)
    }

    /// A colour that follows light/dark mode (including the app's own Appearance setting).
    init(light: UInt32, dark: UInt32) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            let c = components(traits.userInterfaceStyle == .dark ? dark : light)
            return UIColor(red: c.red, green: c.green, blue: c.blue, alpha: 1)
        })
        #else
        self.init(hex: dark)
        #endif
    }
}

extension View {
    /// A solid header in the page's background colour (no see-through blur when scrolling).
    func solidHeader() -> some View {
        #if os(iOS)
        return self
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        #else
        return self
        #endif
    }
}

extension OpenURLAction {
    /// Tries the app link first and falls back to the website if the app isn't installed.
    func open(app: URL?, web: URL?) {
        guard let web else {
            if let app { callAsFunction(app) }
            return
        }
        guard let app else {
            callAsFunction(web)
            return
        }
        callAsFunction(app) { accepted in
            if !accepted { callAsFunction(web) }
        }
    }
}

/// The heavy rounded "EARMILK" title at the top of the list.
struct Wordmark: View {
    var body: some View {
        Text("EARMILK")
            .font(.system(.title2, design: .rounded, weight: .black))
            .tracking(-0.5)
            .foregroundStyle(Theme.text)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityLabel("Earmilk")
            .accessibilityAddTraits(.isHeader)
    }
}
