# Retro Game Quickstart

One-script installers for classic games on macOS — Apple Silicon and Intel. Each script downloads the engine, game data, and sets everything up in a single run. Run any of them with a single `curl | bash` command — no clone required (see [Run from the web](#run-from-the-web)).

## Run from the web

No clone needed — run any installer with a single command (macOS, Apple Silicon or Intel). The scripts are self-contained and read prompts from your terminal (`/dev/tty`), so piping over `curl | bash` works exactly like running a local clone.

### Interactive menu

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/quickstart.sh | bash
```

Pick a game directly by number (1-14):

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/quickstart.sh | bash -s -- 3
```

Forward flags to the installer (e.g. unattended mode):

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/quickstart.sh | bash -s -- 3 --yes
```

### Run a specific game directly

```bash
#  1. The Elder Scrolls II: Daggerfall (1996)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-daggerfall.sh | bash

#  2. Diablo (1996)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-diablo.sh | bash

#  3. Duke Nukem 3D (1996)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-duke3d.sh | bash

#  4. Heroes of Might and Magic II (1996)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-homm2.sh | bash

#  5. Heroes of Might and Magic III (1999)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-homm3.sh | bash

#  6. Marathon Trilogy (1994-1996)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-marathon.sh | bash

#  7. OpenRA (C&C, Red Alert, Dune 2000)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-openra.sh | bash

#  8. Quake (1996)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-quake.sh | bash

#  9. Quake II (1997)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-quake2.sh | bash

# 10. Quake III Arena (1999)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-quake3.sh | bash

# 11. Unreal Gold (1998)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-unreal-gold.sh | bash

# 12. Unreal Tournament (1999)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-ut99.sh | bash

# 13. Unreal Tournament 2004
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-ut2004.sh | bash

# 14. Wolfenstein: Enemy Territory (2003)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-et.sh | bash
```

Unattended (skip all confirmation prompts):

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-ut99.sh | bash -s -- --yes
```

| #  | Game                                | Data                                        | One-liner                                     |
|----|-------------------------------------|---------------------------------------------|-----------------------------------------------|
|  1 | The Elder Scrolls II: Daggerfall (1996)   | free, full game                             | `curl -fsSL …/install-daggerfall.sh  \| bash` |
|  2 | Diablo (1996)                  | free demo; full game can also be downloaded | `curl -fsSL …/install-diablo.sh      \| bash` |
|  3 | Duke Nukem 3D (1996)           | free demo; full game needs your files       | `curl -fsSL …/install-duke3d.sh      \| bash` |
|  4 | Heroes of Might and Magic II (1996) | free demo; full game needs your files       | `curl -fsSL …/install-homm2.sh       \| bash` |
|  5 | Heroes of Might and Magic III (1999)      | free demo; full game needs your files       | `curl -fsSL …/install-homm3.sh       \| bash` |
|  6 | Marathon Trilogy (1994-1996)              | free, full game                             | `curl -fsSL …/install-marathon.sh    \| bash` |
|  7 | OpenRA (C&C, Red Alert, Dune 2000)        | free, full game                             | `curl -fsSL …/install-openra.sh      \| bash` |
|  8 | Quake (1996)                              | free demo; full game can also be downloaded | `curl -fsSL …/install-quake.sh       \| bash` |
|  9 | Quake II (1997)                           | free demo; full game can also be downloaded | `curl -fsSL …/install-quake2.sh      \| bash` |
| 10 | Quake III Arena (1999)                    | free, full game                             | `curl -fsSL …/install-quake3.sh      \| bash` |
| 11 | Unreal Gold (1998)                        | free, full game                             | `curl -fsSL …/install-unreal-gold.sh \| bash` |
| 12 | Unreal Tournament (1999)                  | free, full game                             | `curl -fsSL …/install-ut99.sh        \| bash` |
| 13 | Unreal Tournament 2004                    | free, full game                             | `curl -fsSL …/install-ut2004.sh      \| bash` |
| 14 | Wolfenstein: Enemy Territory (2003)       | free, full game                             | `curl -fsSL …/install-et.sh          \| bash` |

> All game data is downloaded, checksum-verified, and cleaned up safely even on Ctrl+C. The menu launcher (`quickstart.sh`) just downloads the chosen installer to a temp dir and runs it, so it stays tiny and always serves the latest version from `main`.

## Installers

| Script                   | Game                                      | Genre    | Game data source                                                                                                               | One-click?                        |
|--------------------------|-------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------------------|-----------------------------------|
| `install-daggerfall.sh`  | The Elder Scrolls II: Daggerfall (1996)   | RPG      | Full game (~107MB, archive.org, free)                                                                                          | Yes                               |
| `install-diablo.sh`      | Diablo (1996)                  | ARPG     | Shareware data (~31MB, DevilutionX releases, free) or full game (~494MB, cdn.pvpgn.pro, for owners)                            | Yes                               |
| `install-duke3d.sh`      | Duke Nukem 3D (1996)           | FPS      | Shareware package (~6MB, archive.org, free)                                                                                    | Yes                               |
| `install-homm2.sh`       | Heroes of Might and Magic II (1996) | TBS      | Official demo (~40MB, archive.org, free)                                                                                       | Yes                               |
| `install-homm3.sh`       | Heroes of Might and Magic III (1999)      | TBS      | Official Mac demo (~105MB, classicmacdemos.com, free) + demo-support mod; or own copy (GOG installer imported by the launcher) | Yes                               |
| `install-marathon.sh`    | Marathon Trilogy (1994-1996)              | FPS      | Bundled with app (free, released by Bungie)                                                                                    | Yes                               |
| `install-openra.sh`      | OpenRA (C&C, Red Alert, Dune 2000)        | RTS      | Quick-install packages (~33MB, OpenRA mirrors)                                                                                 | Yes                               |
| `install-quake.sh`       | Quake (1996)                              | FPS      | Full game (~597MB, archive.org) or Shareware (Episode 1, free)                                                                 | Yes — prompts for legitimate copy |
| `install-quake2.sh`      | Quake II (1997)                           | FPS      | 3.14 demo (~36MB, Yamagi mirror, free) or full game (~897MB, archive.org)                                                      | Yes                               |
| `install-quake3.sh`      | Quake III Arena (1999)                    | FPS      | CD ISO (~530MB, archive.org)                                                                                                   | Yes                               |
| `install-unreal-gold.sh` | Unreal Gold (1998)                        | FPS      | Unreal Gold CD ISO (~645MB, OldUnreal)                                                                                         | Yes                               |
| `install-ut99.sh`        | Unreal Tournament (1999)                  | FPS      | GOTY CD1 ISO (~620MB, OldUnreal)                                                                                               | Yes                               |
| `install-ut2004.sh`      | Unreal Tournament 2004                    | FPS      | DVD ISO (~2.8GB, OldUnreal)                                                                                                    | Yes                               |
| `install-et.sh`          | Wolfenstein: Enemy Territory (2003)       | FPS (MP) | Fully free; original paks pre-installed (~229MB, ET: Legacy official mirror)                                                   | Yes                               |

### Data tiers at a glance

| Tier                              | Meaning                                                                                               | Games                                                                                                            |
|-----------------------------------|-------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| Fully free                        | Nothing to buy, nothing to copy — the script installs the complete game                               | Daggerfall, Marathon Trilogy, OpenRA, Quake III Arena, Unreal Gold, Unreal Tournament (1999), Unreal Tournament 2004, Wolfenstein: Enemy Territory † |
| Free demo; download the full game | A demo or shareware is installed now; if you own the full game, the script downloads its data for you | Diablo, Quake (1996), Quake II                                                                                   |
| Free demo; add your own files     | A demo is installed now; to upgrade, copy files from your own copy — the installer prints the steps   | Duke Nukem 3D, HoMM2, HoMM3                                                                                      |

† OpenRA installs the core game files; FMV videos and CD soundtracks can still be added from the original CDs via the in-game "Manage Content" menu.

## Quick start (local clone)

```bash
./install-daggerfall.sh    # The Elder Scrolls II: Daggerfall (1996)
./install-diablo.sh        # Diablo (1996)
./install-duke3d.sh        # Duke Nukem 3D (1996)
./install-homm2.sh         # Heroes of Might and Magic II (1996)
./install-homm3.sh         # Heroes of Might and Magic III (1999)
./install-marathon.sh      # Marathon Trilogy (1994-1996)
./install-openra.sh        # OpenRA (C&C, Red Alert, Dune 2000)
./install-quake.sh         # Quake (1996)
./install-quake2.sh        # Quake II (1997)
./install-quake3.sh        # Quake III Arena (1999)
./install-unreal-gold.sh   # Unreal Gold (1998)
./install-ut99.sh          # Unreal Tournament (1999)
./install-ut2004.sh        # Unreal Tournament 2004
./install-et.sh            # Wolfenstein: Enemy Territory (2003)
```

Or fully unattended (skip confirmation prompt):

```bash
./install-ut99.sh --yes
```

## Requirements

- macOS (Apple Silicon or Intel, 10.9+ for Unreal/UT99, 10.15+ for UT2004/OpenRA)
- `curl` (pre-installed on macOS)
- Disk space varies per game (see below)
- `7zip` needed for UT99 Bonus Pack 4, Quake shareware, Daggerfall, and Duke Nukem 3D shareware (scripts prompt to `brew install` if missing)
- Daggerfall Unity requires Rosetta 2 on Apple Silicon (script installs it automatically if needed)

All engines are native on both Apple Silicon and Intel - universal binaries everywhere except Daggerfall Unity (x86_64, runs via Rosetta 2) and VCMI (separate native builds per architecture, no Rosetta needed).

---

## The Elder Scrolls II: Daggerfall (1996)

```bash
./install-daggerfall.sh
```

- **Engine**: Daggerfall Unity v1.1.1 (x86_64, runs via Rosetta 2 on Apple Silicon — installed automatically)
- **Game data**: Full Daggerfall game from archive.org (~107MB, released as freeware by Bethesda)
- **Steps**: Install Rosetta 2 if needed → Install engine → Download game data → Extract ARENA2 → Enable portable mode
- **Disk space**: ~200MB
- **Launch**: `open /Applications/DaggerfallUnity.app`
- **Requires**: `7zip` (script prompts to `brew install` if missing)
- **Note**: Game data is bundled inside the .app (portable mode) — no first-run directory selection needed
- **Daggerfall Unity improvements**: Modern resolution and controls, bug fixes, mod support

## Diablo (1996)

```bash
./install-diablo.sh
```

- **Engine**: DevilutionX 1.5.5 (universal 2, signed/notarized official release)
- **Game data (shareware, free)**: `spawn.mpq` (~25MB, SHA256-verified, hosted on the DevilutionX project's own releases) + `devilutionx.mpq` engine assets
- **Game data (full, own copy)**: `DIABDAT.MPQ` (~494MB, SHA256-verified) downloaded from `cdn.pvpgn.pro` after confirming you own the game — includes all 16 dungeon levels
- **Steps**: Install engine → confirm ownership → download shareware or full data → install to Application Support
- **Disk space**: ~100MB (shareware) or ~600MB (full)
- **Launch**: `open /Applications/Diablo/devilutionX.app`
- **Game data location**: `~/Library/Application Support/diasurgical/devilution`
- **Note**: Shareware includes the Cathedral levels; TCP/IP multiplayer works between shareware players out of the box. Upgrade any time by re-running the installer and answering 'y' to the ownership question. Hellfire expansion: copy `HELLFIRE.MPQ` (+ `HFMUSIC.MPQ`, `HFVOICE.MPQ`) from your copy into the data folder.

## Duke Nukem 3D (1996)

```bash
./install-duke3d.sh
```

- **Engine**: Raze 1.11.0 (universal 2, official Raze release from the GZDoom team; SHA256-verified)
- **Game data**: shareware v1.3d, Episode 1 "L.A. Meltdown" (~6MB, archive.org, SHA1-verified; 3D Realms' `.SHR` package extracted with 7zip)
- **Steps**: Install engine → Download shareware → Extract `DUKE3D.GRP` → Create launcher app
- **Disk space**: ~120MB
- **Launch**: `open '/Applications/Duke3D/Duke Nukem 3D.app'`
- **Install location**: `/Applications/Duke3D/` (Raze.app + game data + launcher)
- **Requires**: `7zip` (script prompts to `brew install` if missing)
- **Note**: The created launcher app starts Raze from the data folder, since Raze finds game data in its working directory. Multiplayer is available (basic P2P netcode; direct host/join from the in-game menu). Upgrade to the full game by replacing `DUKE3D.GRP` with one from an owned Atomic Edition copy.

## Heroes of Might and Magic II (1996)

```bash
./install-homm2.sh
```

- **Engine**: fheroes2 1.1.17 (universal 2, signed/notarized Mac Source Ports build)
- **Game data**: the official HoMM2 demo (~40MB, SHA256-verified — same source and checksum as fheroes2's own bundled download script)
- **Steps**: Install engine → Download demo → Extract → Pre-install data and maps
- **Disk space**: ~150MB
- **Launch**: `open /Applications/HoMM2/fheroes2.app`
- **Game data location**: `~/Library/Application Support/fheroes2`
- **Note**: Hot-seat multiplayer (take turns on one Mac). Upgrade to the full game by copying GOG game files (extracted with `innoextract`) into the data folder.
- **Music**: the 1996 demo shipped without any music tracks (the demo's AGG archive contains none), so silence is expected. fheroes2 plays the original opera soundtrack from `~/Library/Application Support/fheroes2/music/` — copy the `MUSIC` folder contents from a GOG full-game install there (`.ogg`/`.mp3`/`.flac`, auto-detected).

## Heroes of Might and Magic III (1999)

```bash
./install-homm3.sh
```

- **Engine**: VCMI — stable 1.7.5 (owned copy) or pinned 1.8.0 development build (demo; SHA256-verified, per your Mac — the same DMGs hosted by Mac Source Ports for stable)
- **Game data (demo, free)**: the official 2000 Mac demo (Complete Edition-based, freely distributed — ~105MB from classicmacdemos.com) plus the "Heroes III Demo" mod from the official VCMI repo (CC BY-SA, checksum-verified, auto-installed and auto-enabled)
- **Game data (full, own copy)**: Heroes of Might and Magic III: Complete Edition on GOG (~$5 on sale) — VCMI's built-in launcher imports the GOG offline installer directly, no extraction tools needed
- **Demo includes**: playable towns Castle, Dungeon and Necropolis; the original demo map "Dead and Buried"; random map generation; partial music
- **Steps (demo)**: Install engine → download + extract demo (requires `unar`, script prompts to `brew install`) → install demo data + mod → play
- **Steps (full)**: Install engine → launch VCMI → import data from the GOG installer (or copy `Data`, `Maps`, `Mp3` folders into the data location, or use the bundled `vcmibuilder` CLI)
- **Disk space**: ~150MB engine; demo data ~190MB; full game data ~1GB
- **Launch**: `open /Applications/HoMM3/VCMI.app` (opens the VCMI launcher which manages data, mods and settings)
- **Game data location**: `~/Library/Application Support/vcmi`
- **Note**: demo data requires VCMI 1.8.0 — the latest stable 1.7.5 crashes on a partially-included creature animation that 1.8.0 handles. The installer pins a known-good 1.8.0 development build; this pin should be replaced with the 1.8.0 stable release when it ships. When upgrading from demo to full game, disable the "Heroes III Demo" mod in the launcher first.
- **Playing with friends**: VCMI has built-in network multiplayer plus hot-seat — host or join from the in-game multiplayer menu

## Marathon Trilogy (1994-1996)

```bash
./install-marathon.sh
```

- **Engine + data**: the three official Aleph One 1.11.1 macOS releases — each a ready-to-run app with the game data bundled inside (SHA256-verified, ~128MB total)
- **Data legitimacy**: all three games were released as freely redistributable data by Bungie
- **Steps**: Download + verify each DMG → copy three apps to `/Applications`
- **Disk space**: ~260MB
- **Three apps installed**:
  - `Classic Marathon.app`
  - `Classic Marathon 2.app`
  - `Classic Marathon Infinity.app`
- **Launch**: `open '/Applications/Classic Marathon.app'` (etc.)
- **Playing with friends**: built-in metaserver (server browser) and full campaign co-op — join games straight from the in-game menu, no setup needed

## OpenRA — Command & Conquer, Red Alert, Dune 2000

```bash
./install-openra.sh
```

- **Engine**: OpenRA release-20250330 (Universal 2, Apple Silicon + Intel)
- **Game data**: Quick-install packages from OpenRA mirrors (~33MB total for all 3 games)
- **Steps**: Install 3 apps → Download game data for C&C, Red Alert, and Dune 2000 → Pre-install to skip first-launch download
- **Disk space**: ~350MB
- **Three apps installed**:
  - `OpenRA - Tiberian Dawn.app` (Command & Conquer)
  - `OpenRA - Red Alert.app`
  - `OpenRA - Dune 2000.app`
- **Launch**: `open '/Applications/OpenRA - Tiberian Dawn.app'` (or Red Alert / Dune 2000)
- **Game data location**: `~/Library/Application Support/OpenRA/Content/`
- **Note**: Core game data only (no FMV videos or music soundtrack). For full content, use "Manage Content" > "Detect Disc or Installation" in-game with original CDs. C&C and Red Alert were released as freeware by EA.

## Quake (1996)

```bash
./install-quake.sh
```

- **Engine**: vkQuake from Mac Source Ports (Universal 2, signed, Vulkan via MoltenVK)
- **Game data**: Full game from archive.org (~597MB, if user owns a legitimate copy) or Shareware (Episode 1, free)
- **Steps**: Install engine → Ask if user owns a legitimate copy → Download full game (all episodes + mission packs + soundtrack) or shareware → Set up game data
- **Disk space**: ~50MB (shareware) or ~700MB (full game)
- **Launch**: `open /Applications/Quake/vkQuake.app`
- **Install location**: `/Applications/Quake/` (app + `id1/` + optional `hipnotic/` + `rogue/`)
- **Requires**: `7zip` (script prompts to `brew install` if missing)
- **Full game includes**: All 4 episodes, Mission Pack 1 (Scourge of Armagon), Mission Pack 2 (Dissolution of Eternity), and CD soundtrack as OGG files

## Quake II (1997)

```bash
./install-quake2.sh
```

- **Engine**: Yamagi Quake II 8.70 (Mac Source Ports build, universal 2, signed/notarized)
- **Game data**: official 3.14 demo (~36MB, Yamagi's own mirror, SHA/MD5-verified) — 3 single-player levels + deathmatch maps; or full game (~897MB, archive.org) if you own a copy
- **Steps**: Install engine → Download demo/full game → Extract → Install to `~/.local/share/YamagiQ2`
- **Disk space**: ~150MB (demo) or ~2GB (full)
- **Launch**: `open /Applications/Quake2/yquake2.app`
- **Game data location**: `~/.local/share/YamagiQ2`
- **Note**: Saving is disabled in the demo version; multiplayer works on the demo's included deathmatch maps

## Quake III Arena (1999)

```bash
./install-quake3.sh
```

- **Engine**: ioquake3 notarized Universal 2 build (signed, Apple Silicon + Intel)
- **Game data**: CD ISO from archive.org (~530MB) + patch data from ioquake3.org (pak1-8)
- **Steps**: Install engine → Download patch data → Download CD ISO → Copy pak0.pk3 → Install patch pk3s
- **Disk space**: ~600MB
- **Launch**: `open /Applications/ioquake3/ioquake3.app`
- **Install location**: `/Applications/ioquake3/` (app + `baseq3/` + `missionpack/`)
- **Note**: The original 1999 CD does not include Team Arena. For Team Arena, purchase from GOG ($6) or Steam ($15), then copy `missionpack/pak0.pk3`

## Unreal Gold (1998)

```bash
./install-unreal-gold.sh
```

- **Engine**: OldUnreal v227k patch (universal binary)
- **Game data**: Unreal Gold CD ISO from `files.oldunreal.net` (SHA256-verified, 4 mirrors)
- **Steps**: Install patch → Download ISO → Copy Maps/Sounds/Textures/Music → Delete obsolete font texture
- **Disk space**: ~800MB
- **Launch**: `open /Applications/Unreal.app`
- **Game data location**: `~/Library/Application Support/Unreal`
- **Note**: No map decompression needed (Unreal Gold maps are uncompressed on the CD)

## Unreal Tournament (1999)

```bash
./install-ut99.sh
```

- **Engine**: OldUnreal v469e patch (universal binary)
- **Game data**: GOTY CD1 ISO from `files.oldunreal.net` (SHA256-verified, 4 mirrors)
- **Steps**: Install patch → Download ISO → Copy Maps/Textures/Sounds/Music → Decompress `.uz` maps → Install Bonus Pack 4
- **Disk space**: ~1.3GB
- **Launch**: `open /Applications/UnrealTournament.app`
- **Game data location**: `~/Library/Application Support/Unreal Tournament`
- **Requires**: `7zip` for Bonus Pack 4 (script prompts to `brew install` if missing)

## Unreal Tournament 2004

```bash
./install-ut2004.sh
```

- **Engine**: OldUnreal v3374 patch (universal binary, preview release)
- **Game data**: DVD ISO from `files.oldunreal.net` (SHA256-verified, 3 mirrors)
- **Steps**: Install patch → Download unshield tool → Download ISO → Copy CAB files → Extract with unshield → Install game data
- **Disk space**: ~6GB
- **Launch**: `open /Applications/UT2004.app`
- **Game data location**: `~/Library/Application Support/UT2004`
- **Note**: Bonus packs (CBP1, CBP2, ECE) are included in the DVD ISO
- **Warning**: The patch is currently a preview release (not yet marked stable)

## Wolfenstein: Enemy Territory (2003)

```bash
./install-et.sh
```

- **Engine**: ET: Legacy 2.86.2 (official macOS release, universal 2)
- **Game data**: the entire game is free (engine + data, released as freeware by id Software/Splash Damage); the original 2003 paks (~229MB) are pre-installed from ET: Legacy's official mirror
- **Steps**: Download official DMG (MD5-verified) → install the `ETLegacy` folder to `/Applications` → download pak0-2 (SHA256-verified) into `etmain`
- **Disk space**: ~280MB download, ~520MB installed
- **Launch**: `open '/Applications/ETLegacy/ET Legacy.app'`
- **Playing with friends**: multiplayer-only game with active public servers — connects to the live master server out of the box; host your own dedicated server with the bundled `etlded`

---

## Common features

All scripts share:

- `--yes` flag for unattended mode (skips all confirmation prompts)
- SHA256/SHA1 verification of downloaded game data (where checksums are available)
- Fallback download mirrors (where applicable)
- Safe cleanup via trap (unmounts ISOs, removes temp files — even on Ctrl+C or errors)
- Architecture auto-detection
- Quarantine attribute removal (`xattr -dr com.apple.quarantine`)

## Configuration

Variables at the top of each script can be tweaked (patch versions, install paths, etc.).

## Files

- `quickstart.sh` — menu launcher (run from the web; picks and runs any installer)
- `install-daggerfall.sh` — The Elder Scrolls II: Daggerfall (1996) installer
- `install-diablo.sh` — Diablo (1996) installer
- `install-duke3d.sh` — Duke Nukem 3D (1996) installer
- `install-homm2.sh` — Heroes of Might and Magic II (1996) installer
- `install-homm3.sh` — Heroes of Might and Magic III (1999) installer
- `install-marathon.sh` — Marathon Trilogy (1994-1996) installer
- `install-openra.sh` — OpenRA (C&C, Red Alert, Dune 2000) installer
- `install-quake.sh` — Quake (1996) installer
- `install-quake2.sh` — Quake II (1997) installer
- `install-quake3.sh` — Quake III Arena (1999) installer
- `install-unreal-gold.sh` — Unreal Gold (1998) installer
- `install-ut99.sh` — Unreal Tournament (1999) installer
- `install-ut2004.sh` — Unreal Tournament 2004 installer
- `install-et.sh` — Wolfenstein: Enemy Territory (2003) installer
- `original.sh` — original untested UT99 script (kept for reference)

## Playing with friends

Every multiplayer-capable game can be hosted from its in-game multiplayer menu, and every installer sets the game up for both hosting and joining.

How you find each other depends on the game:

- **Join straight from the menu** — built-in browsers and lobbies, nothing to enter or exchange: Marathon Trilogy (live metaserver browser, including full campaign co-op), Wolfenstein: Enemy Territory (public server list), OpenRA (lobby)
- **Direct host/join** — Unreal Tournament, Unreal Gold, UT2004, Quake, Quake II, Quake III, Diablo, Duke Nukem 3D: one player hosts from the game's multiplayer menu and the others connect from theirs; the address to enter is shown in each game's join dialog (works over LAN, and over the internet where the host's network allows it)
- **Hot-seat** — HoMM2: take turns on the same Mac
