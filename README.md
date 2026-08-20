# WatchMusic

A watchOS app that talks to your own local yt-dlp server, lets you search for
songs, download them to the watch, and play them fully offline (no phone or
internet needed once downloaded).

## Project layout

```
WatchMusic/
├── project.yml                  # XcodeGen spec — generates the .xcodeproj
├── codemagic.yaml                # CI workflow, produces an unsigned .ipa
└── WatchMusic/
    ├── WatchMusic/                # iOS host app (required container, does nothing else)
    └── WatchMusicWatch/           # The actual watch app
        ├── Models/Song.swift
        ├── Services/
        │   ├── NetworkService.swift      # talks to your server
        │   ├── DownloadManager.swift     # saves audio to watch storage
        │   └── AudioPlayerManager.swift  # offline playback via AVAudioPlayer
        └── Views/
            ├── ContentView.swift   # tab container
            ├── SearchView.swift
            ├── LibraryView.swift
            ├── PlayerView.swift    # now-playing screen w/ Digital Crown scrubbing
            ├── SettingsView.swift
            └── SongRowView.swift
```

## Server contract

The app expects two endpoints on your local yt-dlp server:

```
GET  /api/search?q={query}     -> JSON array of songs
GET  /api/download/{videoId}   -> raw audio bytes (m4a/mp3)
```

Expected JSON shape per song:
```json
{ "id": "dQw4w9WgXcQ", "title": "...", "artist": "...", "thumbnail": "https://...", "duration": 213 }
```

If your existing server (e.g. your VinylWave/Vinyl backend) uses different field
names or paths, just tweak `Song.swift`'s `CodingKeys` and the paths in
`NetworkService.swift` — everything else is unaffected.

If you're exposing the server via Cloudflare Tunnel with HTTP Basic Auth like
your other projects, put the tunnel URL + username/password into the watch
app's Settings tab and it'll attach the `Authorization` header automatically.

## Building locally (if you have Xcode)

```bash
brew install xcodegen
cd WatchMusic
xcodegen generate
open WatchMusic.xcodeproj
```

Pick the `WatchMusic` scheme, choose your paired Watch as the run destination,
and hit Run.

## Building on Codemagic (no Mac needed)

`codemagic.yaml` is already wired up:
1. Push this repo to GitHub.
2. Add it in Codemagic, it'll auto-detect `codemagic.yaml`.
3. Run the `watchmusic-unsigned` workflow.
4. It installs XcodeGen, generates the project, builds with code signing
   disabled, and zips an unsigned `WatchMusic-unsigned.ipa` as a build artifact.

This mirrors the same unsigned-IPA approach you used for Teach Swap /
AlwaysSalah — no Apple Developer Program membership required to build.

## Getting it onto your Watch for free (no Mac)

See **SETUP_GUIDE.md** at the repo root for the full walkthrough. Short
version: Codemagic builds an unsigned `.ipa` in the cloud, then
[Sideloadly](https://sideloadly.io) (Windows/Mac/Linux) signs it with a free
Apple ID and installs it on your iPhone over USB — no Xcode, no Mac. Once
it's on the iPhone, the Watch app's "Available Apps" list lets you push it to
your Apple Watch. Free Apple ID signatures expire every 7 days, so you
re-run Sideloadly weekly — no rebuild needed unless you changed code.
