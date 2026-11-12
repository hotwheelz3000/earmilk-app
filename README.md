# Earmilk

An unofficial native SwiftUI reader for the [Earmilk feed](https://hotwheelz3000.github.io/earmilk/). It loads `posts.json` from the `hotwheelz3000/earmilk` GitHub Pages site and lists each post's artwork, song, artist, genre and date.

## Features

- **Song list** with pull to refresh, a genre bar and filter menu, and search by artist or song.
- **Saved songs:** swipe right on a song, long-press it, or tap the star on its page. **⋯ → Saved Only** shows them. Saved songs are kept on the phone.
- **Song page:**
  - **Play 30-sec Preview**: Apple's free preview (iTunes Search API), or Deezer's when Apple doesn't have the song. The artist and title must both match. Plays with the silent switch on and stops when you leave the page.
  - **Open in Spotify**: opens the Spotify app to a search for the song (the feed has no Spotify links), or the website if the app isn't installed.
  - **Apple Music**: opens the exact song in the Music app when Apple's catalog has it, otherwise Apple Music's web search.
  - **YouTube**: opens the YouTube app to a search for the song, or the website.
  - **Read on Earmilk**: the original article.
- **Appearance:** System, Light or Dark from the **⋯** menu.

## Look and accessibility

Colours follow earmilk.com: a charcoal background in dark mode with white titles and grey secondary text, a solid header with a heavy rounded EARMILK title, and header buttons in the same colour (`Theme.swift`). Genre colours keep their families, with lighter shades in dark mode and deeper ones in light mode so they stay readable (`GenrePill.swift`). iOS 26's Liquid Glass look is turned off (`UIDesignRequiresCompatibility` in `Earmilk-Info.plist`).

Accessibility: Dynamic Type throughout, VoiceOver reads each song as one item with Save and Open in Spotify actions, WCAG AA text contrast in light and dark mode, tap targets of at least 44pt, and Reduce Motion respected.

## Install

Download the IPA from the release page, sign it (e.g. with Signulous or Sideloadly) and install it:

```
https://github.com/hotwheelz3000/earmilk-app/releases/latest
```

Every build has the same file name for a given version, so delete the old IPA before downloading a new one.

## How it's built

- Built with [xtool](https://xtool.sh) (SwiftPM, no Xcode project). `xtool.yml` sets the bundle ID, app icon (`Resources/AppIcon.png`, 1024×1024, no transparency) and `Earmilk-Info.plist`.
- Every push to `main` runs `.github/workflows/build-ipa.yml` on a macOS runner. It builds an unsigned IPA and publishes it as the `latest` GitHub release, titled with the version. Compiler errors show on the run's summary page.
- The version is `CFBundleShortVersionString` in `Earmilk-Info.plist`; it names the release ("Earmilk 1.0") and the file (`Earmilk-1.0.ipa`). Release notes come from `RELEASE_NOTES.md`.
- The feed URL is `FeedStore.feedURL` in `Sources/Earmilk/FeedStore.swift`.
- `.claude/skills/using-xtool/` has xtool reference notes for Claude Code.
