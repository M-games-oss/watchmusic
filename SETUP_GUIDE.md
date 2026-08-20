# WatchMusic — Full Setup Guide

This covers three phases:
1. **Server** — your local machine runs yt-dlp and serves search/download over HTTP.
2. **App build** — Codemagic builds the watchOS app in the cloud (no Mac needed).
3. **Install** — Sideloadly puts the unsigned build on your iPhone, then the
   iPhone's Watch app pushes it to your Apple Watch.

Quick correction from earlier: this app is **native Swift/SwiftUI, not
Flutter**. WatchOS isn't a Flutter compile target — Flutter only outputs to
iOS, Android, web, and desktop — so watch apps have to be written natively
regardless of what you use elsewhere.

---

## Phase 1 — Set up the server

You're running this on your Windows PC, same machine that already hosts
VinylWave/Vinyl.

### 1. Install prerequisites

- **Node.js** (18+): https://nodejs.org — grab the LTS Windows installer.
- **yt-dlp**: download `yt-dlp.exe` from https://github.com/yt-dlp/yt-dlp/releases
  and put it somewhere on your `PATH` (e.g. `C:\Windows\` or a folder you add
  to PATH manually via System Properties → Environment Variables).
- **ffmpeg**: yt-dlp needs this to extract/convert audio. Download a Windows
  build from https://www.gyan.dev/ffmpeg/builds/ (the "essentials" zip is
  fine), unzip it, and add the `bin` folder to your `PATH` too.

Verify both are on PATH:
```powershell
yt-dlp --version
ffmpeg -version
```
If either command isn't found, the PATH edit didn't take — reopen your
terminal (or reboot) after editing environment variables.

### 2. Install the server

```powershell
cd server
npm install
copy .env.example .env
```

Open `.env` and, if you want auth, set `AUTH_USERNAME` and `AUTH_PASSWORD`.
Leave them blank if the server will only ever be reachable inside your home
network.

### 3. Run it

```powershell
npm start
```
You should see `yt-dlp server running on http://localhost:3000`.

### 4. Test it

```powershell
curl "http://localhost:3000/api/search?q=daft%20punk%20one%20more%20time"
```
You should get back a JSON array of songs. Grab one `id` from the response
and test the download endpoint:
```powershell
curl "http://localhost:3000/api/download/<id>" --output test.m4a
```
Play `test.m4a` to confirm audio actually comes through end to end.

### 5. Expose it to your iPhone/Watch

Since your Watch/iPhone won't be on the same LAN as your PC when you're out
and about, you need the same tunnel setup you already use for VinylWave:

```powershell
cloudflared tunnel --url http://localhost:3000
```
This gives you a public `https://xxxxx.trycloudflare.com` URL. For something
more permanent (a stable hostname instead of a random one each restart), set
up a named Cloudflare Tunnel the same way you did for VinylWave.

**Enable auth before exposing this publicly** — set `AUTH_USERNAME`/
`AUTH_PASSWORD` in `.env` and restart the server. Downloading arbitrary
YouTube audio through an open, unauthenticated endpoint on the public
internet is asking for random traffic to find and hammer it.

---

## Phase 2 — Build the app on Codemagic

### 1. Push the Xcode project to GitHub

```powershell
cd WatchMusic
git init
git add .
git commit -m "Initial WatchMusic app"
```
Create a new (private is fine) repo on GitHub, then:
```powershell
git remote add origin https://github.com/yourusername/watchmusic.git
git branch -M main
git push -u origin main
```

### 2. Connect it to Codemagic

1. Log into https://codemagic.io (free tier works for this).
2. **Add application** → pick the `watchmusic` repo.
3. Codemagic will detect the `codemagic.yaml` at the repo root automatically.
4. Select the **watchmusic-unsigned** workflow → **Start new build**.

### 3. Grab the build artifact

Once the build finishes (a few minutes), open the build → **Artifacts** →
download `WatchMusic-unsigned.ipa`. Save it somewhere easy to find on your
Windows PC.

If the build fails, the most likely culprit is an XcodeGen/project.yml typo —
check the "Generate Xcode project" step's log first.

---

## Phase 3 — Get it onto your iPhone, then your Watch

### 1. Install Sideloadly

Download it from https://sideloadly.io (Windows build). No Mac, no Xcode.

### 2. Sideload the IPA

1. Plug your iPhone into your PC via USB and unlock it (tap **Trust** if
   prompted).
2. Open Sideloadly, drag `WatchMusic-unsigned.ipa` into it.
3. Enter your Apple ID email — this can be any free Apple ID, no paid
   Developer Program needed. Sideloadly will prompt for your password (and
   2FA code) to generate a free signing certificate on the fly.
4. Click **Start**. Sideloadly signs the IPA and installs it on your phone.
5. On the iPhone: **Settings → General → VPN & Device Management** → tap
   your Apple ID's developer profile → **Trust**. Without this the app
   refuses to launch even though it's installed.

### 3. Push it to your Watch

1. Open the **Watch** app on your iPhone.
2. Scroll down to **Available Apps**.
3. WatchMusic should be listed — tap **Install**.
4. Give it a minute to transfer over Bluetooth/Wi-Fi to your Apple Watch.

### 4. Configure and use it

1. Open WatchMusic on your Watch.
2. Go to the **Settings** tab, enter your Cloudflare Tunnel URL and, if you
   set one, your auth username/password.
3. Search tab → search a song → tap the download icon.
4. Once downloaded (checkmark appears), tap the row to start playing, or
   find it later in the **Library** tab — playback works with your phone
   nowhere nearby, since the audio file lives on the watch itself.

### 5. The weekly catch

Free Apple ID signatures expire after **7 days**. When that happens the app
just won't open — no data loss, nothing broken, it just needs re-signing:

1. Plug the iPhone back into your PC.
2. Open Sideloadly, drag the same `.ipa` in again, sign in again, hit Start.
3. Re-trust the developer profile if iOS asks again.

You don't need to rebuild on Codemagic unless you've actually changed code —
just re-run Sideloadly with the same IPA file each week.
