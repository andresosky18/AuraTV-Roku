<div align="center">

<p align="center">
  <img src="images/aura_logo_inner.png" alt="Aura TV" width="120" />
</p>

# AuraTV — Roku OS

**A free, open-source media & live TV app for Roku Smart TVs and Roku Streaming Players.**  
Bring your own sources (M3U, Xtream Codes & Stremio-compatible Add-ons) and turn them into a unified 10-foot **OLED Black (`#000000`)** cinema interface built natively in **BrightScript & Roku SceneGraph (RSG)**.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform](https://img.shields.io/badge/Platform-Roku%20OS%20%7C%20Roku%20TV-662D91?logo=roku&logoColor=white)](https://github.com/andresosky18/AuraTV-Roku)
[![Release](https://img.shields.io/badge/Version-v2.1-ffffff?style=flat-square)](https://github.com/andresosky18/AuraTV-Roku/releases)
[![Portal](https://img.shields.io/badge/Web%20Portal-auratv.site.je-8B5CF6)](https://auratv.site.je)

<p align="center">
  <a href="https://auratv.site.je">Website</a> ·
  <a href="https://github.com/andresosky18/AuraTV-Roku/releases">GitHub Releases</a> ·
  <a href="https://auratv.site.je/#device">Link My TV</a> ·
  <a href="https://github.com/andresosky18/AuraTV-Android">Android TV Repo</a> ·
  <a href="https://github.com/andresosky18/AuraTV-Samsung">Samsung Tizen Repo</a>
</p>

</div>

---

## Overview

**AuraTV (`AuraTV-Roku`)** is the official **Roku OS** client for the Aura TV ecosystem. Engineered from the ground up using native **BrightScript** and **Roku SceneGraph (`roSGScreen`)**, it delivers hardware-accelerated live TV and VOD playback, instant channel switching, and cloud playlist synchronization without requiring external transcoding servers.

---

## Key Features

- **Bring Your Own Sources:** Connect any **M3U / M3U8 URL**, **Xtream Codes API** credentials, or external community **VOD Add-ons** seamlessly.
- **10-Foot OLED Black (`#000000`) Interface:**
  - Pure `#000000` OLED canvas across all screens (Splash, Playbox-style Home Launcher with status pills, Live TV 3-column guide, Movies & Series, Add-ons, Playlists, Search, and Settings).
  - Slate/Silver translucent player OSD banner (`#DCE3EF` with high-contrast `#182235` typography) that auto-hides after 8 seconds.
- **Native Roku `Video` Node Engine:**
  - Direct hardware-decoded playback for `.m3u8` (HLS), `.ts`, and `.mp4` streams using custom `roHttpAgent` (`VLC/3.0.9 LibVLC/3.0.9`) and `common:/certs/ca-bundle.crt` TLS certificates.
  - **Auto-Reconnection & Watchdog:** Automatically detects stalled or dropped live broadcasts and reconnects after 4 seconds with a clean on-screen notice (`Canal no disponible en el momento`).
  - **Live Resolution Detector & Aspect Modes:** Real-time stream quality badges (`4K`, `1080p`, `720p`, `SD`) and instant aspect-ratio switching (`16:9` / `FIT` / `ZOOM`).
- **9 Pro Live TV Enhancements:**
  1. **Channel Logos (`tvg-logo` / `stream_icon`):** Rendered directly in the channel list and player OSD banner.
  2. **In-Player Lateral Mini-Guide (`◄ Left`):** Browse and switch channels in fullscreen without interrupting playback.
  3. **Direct Numeric Zapping (`0–9`):** Type any channel number on the remote to jump after 1.5 seconds.
  4. **Persistent Favorites (`★`) & Recent History (`↺`):** Saved locally in `roRegistrySection("AuraTVRegistry")` and accessible as virtual categories.
  5. **Last Channel Recall (`► Right`):** Jump back to the previous channel with a single click in fullscreen.
  6. **Active Channel & Category Counters:** Live pill indicator displaying active/total channels and categories.
  7. **Instant Search (`*` / Search View):** Filter channels by name, number, or category.
  8. **Background Cloud Sync (3s Polling):** Real-time playlist and add-on sync with [auratv.site.je](https://auratv.site.je) with animated sync indicator.
  9. **Multi-Language & Parental PIN:** Full localization in **Spanish**, **English**, and **Chinese** (`ES` / `EN` / `ZH`), plus PIN protection.

---

## Download & Installation (Roku Developer Mode)

1. Download **`AURA_TV_v2.1.zip`** from the [**Releases**](https://github.com/andresosky18/AuraTV-Roku/releases) page, directly from this repository, or from [auratv.site.je](https://auratv.site.je/#downloads).
2. Enable **Developer Mode** on your Roku device:
   - Using your Roku remote, press: **`Home` (×3) → `Up` (×2) → `Right` → `Left` → `Right` → `Left` → `Right`**.
   - Note the local IP address displayed on screen, enable the installer, set a developer password, and reboot the Roku.
3. Open a web browser on your PC or phone (connected to the same Wi-Fi network) and visit:
   ```text
   http://<YOUR_ROKU_IP>
   ```
4. Log in with username **`rokudev`** and the password you set.
5. Click **Upload**, select **`AURA_TV_v2.1.zip`**, and click **Install**. Aura TV will launch automatically on your TV.

---

## Build & Package from Source

To create the sideloadable `.zip` package directly from source (note: `manifest` must reside at the root of the archive):

```bash
git clone https://github.com/andresosky18/AuraTV-Roku.git
cd AuraTV-Roku
zip -r AURA_TV_v2.1.zip manifest source/ components/ images/
```

---

## Project Structure

```text
AuraTV-Roku/
├── manifest                       # Roku OS channel manifest (HD UI, #000000 OLED splash)
├── source/
│   └── main.brs                   # roSGScreen bootstrap & main message loop
├── components/
│   ├── MainScene.xml              # Full 10-foot SceneGraph layout (OLED Black #000000)
│   ├── MainScene.brs              # Core IPTV engine, Live TV, Mini-Guide, Zapping & Cloud Sync
│   ├── MoviesModule.brs           # VOD catalog, detail modal & stream selection
│   ├── AddonsModule.brs           # Stremio-compatible Add-ons manager & diagnostic engine
│   ├── BackendTask.xml            # Asynchronous network Task node definition
│   └── BackendTask.brs            # roUrlTransfer HTTP/HTTPS client & diagnostic inspector
├── images/                        # Channel icons, OLED splash screens & UI assets
├── .github/workflows/
│   └── build-roku.yml             # Automated CI XML validation & .zip packaging workflow
├── AURA_TV_v2.1.zip               # Ready-to-install Roku Developer Mode package
└── LICENSE                        # GNU GPL v3.0
```

---

## Ecosystem Repositories

- **Android TV / Google TV / Fire TV:** [andresosky18/AuraTV-Android](https://github.com/andresosky18/AuraTV-Android)
- **Samsung Smart TV (Tizen OS):** [andresosky18/AuraTV-Samsung](https://github.com/andresosky18/AuraTV-Samsung)
- **Roku OS (BrightScript / SceneGraph):** [andresosky18/AuraTV-Roku](https://github.com/andresosky18/AuraTV-Roku)

---

## Contributors

- **Andres Aragon** ([@andresosky18](https://github.com/andresosky18)) — *Founder & Lead Developer*

---

## License

Every AuraTV app is public on GitHub under the **GNU General Public License v3.0 (GPLv3)**. Read it, build it yourself, or send a patch. See [LICENSE](LICENSE) for full details.

---

## Disclaimer

- **Client-Side Only:** AuraTV is strictly a client-side media player and interface. It **does not host, store, provide, or distribute** any media content, television channels, movies, or streams.
- **User-Provided Sources:** Users must configure their own authorized M3U playlists, Xtream Codes servers, or third-party add-ons.
- **No Affiliation:** AuraTV is an independent open-source project and is not affiliated with or endorsed by Roku, Inc. or any third-party content providers.
