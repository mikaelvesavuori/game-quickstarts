# Retro Game Quickstart

One-script installers for classic games on macOS — Apple Silicon and Intel. Each script downloads the engine, game data, and sets everything up in a single run. Run any of them with a single `curl | bash` command — no clone required (see [Run from the web](#run-from-the-web)).

## Run from the web

No clone needed — run any installer with a single command (macOS, Apple Silicon or Intel). The scripts are self-contained and read prompts from your terminal (`/dev/tty`), so piping over `curl | bash` works exactly like running a local clone.

**Anxious about piping `curl` into `bash`?** Good instinct. Read [`quickstart.sh`](https://github.com/mikaelvesavuori/game-quickstarts/blob/main/quickstart.sh) first, or browse [all the installers](https://github.com/mikaelvesavuori/game-quickstarts) — everything is plain, readable shell, no minified blobs, nothing hidden. The interactive menu points here for the same reason.

### Interactive menu

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/quickstart.sh | bash
```

Pick a game directly by number (1-24):

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

#  3. Doom via Freedoom (1993)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-doom.sh | bash

#  4. Duke Nukem 3D (1996)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-duke3d.sh | bash

#  5. Heroes of Might and Magic II (1996)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-homm2.sh | bash

#  6. Heroes of Might and Magic III (1999)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-homm3.sh | bash

#  7. Marathon Trilogy (1994-1996)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-marathon.sh | bash

#  8. OpenRA (C&C, Red Alert, Dune 2000)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-openra.sh | bash

#  9. OpenTTD — Transport Tycoon Deluxe (1995)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-openttd.sh | bash

# 10. Quake (1996)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-quake.sh | bash

# 11. Quake II (1997)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-quake2.sh | bash

# 12. Quake III Arena (1999)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-quake3.sh | bash

# 13. Shadow Warrior (1997)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-shadowwarrior.sh | bash

# 14. ScummVM: Beneath a Steel Sky, Flight of the Amazon Queen, Lure of the Temptress
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-scummvm.sh | bash

# 15. SimCity 2000 (1993)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-simcity2000.sh | bash

# 16. SimTower: The Vertical Empire (1994)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-simtower.sh | bash

# 17. Theme Hospital (1997) — demo
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-themehospital.sh | bash

# 18. Tyrian 2000 (1999)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-tyrian.sh | bash

# 19. Unreal Gold (1998)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-unreal-gold.sh | bash

# 20. Unreal Tournament (1999)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-ut99.sh | bash

# 21. Unreal Tournament 2004
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-ut2004.sh | bash

# 22. Warzone 2100 (1999)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-warzone2100.sh | bash

# 23. Wolfenstein 3D (1992) — shareware
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-wolf3d.sh | bash

# 24. Wolfenstein: Enemy Territory (2003)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-et.sh | bash
```

Unattended (skip all confirmation prompts):

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-ut99.sh | bash -s -- --yes
```

| #  | Game                                       | Data                                         | One-liner                                     |
|----|--------------------------------------------|----------------------------------------------|-----------------------------------------------|
| 1  | The Elder Scrolls II: Daggerfall (1996)    | free, full game                              | `curl -fsSL …/install-daggerfall.sh  \| bash` |
| 2  | Diablo (1996)                              | free demo; full game can also be downloaded  | `curl -fsSL …/install-diablo.sh      \| bash` |
| 3  | Doom via Freedoom (1993)                   | free, full game                              | `curl -fsSL …/install-doom.sh        \| bash` |
| 4  | Duke Nukem 3D (1996)                       | free demo; full game needs your files        | `curl -fsSL …/install-duke3d.sh      \| bash` |
| 5  | Heroes of Might and Magic II (1996)        | free demo; full game needs your files        | `curl -fsSL …/install-homm2.sh       \| bash` |
| 6  | Heroes of Might and Magic III (1999)       | free demo; full game needs your files        | `curl -fsSL …/install-homm3.sh       \| bash` |
| 7  | Marathon Trilogy (1994-1996)               | free, full game                              | `curl -fsSL …/install-marathon.sh    \| bash` |
| 8  | OpenRA (C&C, Red Alert, Dune 2000)         | free, full game                              | `curl -fsSL …/install-openra.sh      \| bash` |
| 9  | OpenTTD (Transport Tycoon Deluxe)          | free, full game                              | `curl -fsSL …/install-openttd.sh     \| bash` |
| 10 | Quake (1996)                               | free demo; full game can also be downloaded  | `curl -fsSL …/install-quake.sh       \| bash` |
| 11 | Quake II (1997)                            | free demo; full game can also be downloaded  | `curl -fsSL …/install-quake2.sh      \| bash` |
| 12 | Quake III Arena (1999)                     | free, full game                              | `curl -fsSL …/install-quake3.sh      \| bash` |
| 13 | Shadow Warrior (1997)                     | free, full game                              | `curl -fsSL …/install-shadowwarrior.sh \| bash` |
| 14 | ScummVM (Beneath a Steel Sky, FOTAQ, Lure) | free, full game                              | `curl -fsSL …/install-scummvm.sh     \| bash` |
| 15 | SimCity 2000 (1993)                        | free demo; full game needs your files        | `curl -fsSL …/install-simcity2000.sh \| bash` |
| 16 | SimTower: The Vertical Empire (1994)       | abandonware, full game - unofficial download | `curl -fsSL …/install-simtower.sh    \| bash` |
| 17 | Theme Hospital (1997)                      | free demo; full game needs your files        | `curl -fsSL …/install-themehospital.sh \| bash` |
| 18 | Tyrian 2000 (1999)                         | free, full game                              | `curl -fsSL …/install-tyrian.sh      \| bash` |
| 19 | Unreal Gold (1998)                         | free, full game                              | `curl -fsSL …/install-unreal-gold.sh \| bash` |
| 20 | Unreal Tournament (1999)                   | free, full game                              | `curl -fsSL …/install-ut99.sh        \| bash` |
| 21 | Unreal Tournament 2004                     | free, full game                              | `curl -fsSL …/install-ut2004.sh      \| bash` |
| 22 | Warzone 2100 (1999)                        | free, full game                              | `curl -fsSL …/install-warzone2100.sh \| bash` |
| 23 | Wolfenstein 3D (1992)                      | free demo; full game needs your files        | `curl -fsSL …/install-wolf3d.sh      \| bash` |
| 24 | Wolfenstein: Enemy Territory (2003)        | free, full game                              | `curl -fsSL …/install-et.sh          \| bash` |

> All game data is downloaded, checksum-verified, and cleaned up safely even on Ctrl+C. The menu launcher (`quickstart.sh`) just downloads the chosen installer to a temp dir and runs it, so it stays tiny and always serves the latest version from `main`.

## Installers

| Script                   | Game                                      | Genre         | Game data source                                                                                                                            | One-click?                        |
|--------------------------|-------------------------------------------|---------------|---------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------|
| `install-daggerfall.sh`  | The Elder Scrolls II: Daggerfall (1996)   | RPG           | Full game (~107MB, archive.org, free)                                                                                                       | Yes                               |
| `install-diablo.sh`      | Diablo (1996)                             | ARPG          | Shareware data (~31MB, DevilutionX releases, free) or full game (~494MB, cdn.pvpgn.pro, for owners)                                         | Yes                               |
| `install-doom.sh`        | Doom via Freedoom (1993)                  | FPS           | Freedoom 0.13.0 (~24MB, both Phase WADs, freedoom.github.io) — complete free id Tech 1 games; engine: GZDoom 4.14.2 official macOS build                              | Yes                               |
| `install-duke3d.sh`      | Duke Nukem 3D (1996)                      | FPS           | Shareware package (~6MB, archive.org, free)                                                                                                 | Yes                               |
| `install-homm2.sh`       | Heroes of Might and Magic II (1996)       | TBS           | Official demo (~40MB, archive.org, free)                                                                                                    | Yes                               |
| `install-homm3.sh`       | Heroes of Might and Magic III (1999)      | TBS           | Official Mac demo (~105MB, classicmacdemos.com, free) + demo-support mod; or own copy (GOG installer imported by the launcher)              | Yes                               |
| `install-marathon.sh`    | Marathon Trilogy (1994-1996)              | FPS           | Bundled with app (free, released by Bungie)                                                                                                 | Yes                               |
| `install-openra.sh`      | OpenRA (C&C, Red Alert, Dune 2000)        | RTS           | Quick-install packages (~33MB, OpenRA mirrors)                                                                                              | Yes                               |
| `install-openttd.sh`     | OpenTTD — Transport Tycoon Deluxe (1995)  | Transport sim | Official OpenTTD 15.3 (~14MB, cdn.openttd.org) + free base sets OpenGFX/OpenSFX/OpenMSX (~15MB, cdn.openttd.org)                            | Yes                               |
| `install-quake.sh`       | Quake (1996)                              | FPS           | Full game (~597MB, archive.org) or Shareware (Episode 1, free)                                                                              | Yes — prompts for legitimate copy |
| `install-quake2.sh`      | Quake II (1997)                           | FPS           | 3.14 demo (~36MB, Yamagi mirror, free) or full game (~897MB, archive.org)                                                                   | Yes                               |
| `install-quake3.sh`      | Quake III Arena (1999)                    | FPS           | CD ISO (~530MB, archive.org)                                                                                                                | Yes                               |
| `install-scummvm.sh`     | ScummVM: Beneath a Steel Sky, FOTAQ, Lure | Adventure     | ScummVM 2026.4.0 (~161MB, scummvm.org) + 3 complete freeware games (~179MB, SHA256-verified, scummvm.org)                                   | Yes                               |
| `install-shadowwarrior.sh` | Shadow Warrior (1997)                 | FPS           | Complete registered game v1.2 + official soundtrack (~258MB, SHA256-verified; freeware since 2016 — mirror of the official GOG Linux package on archive.org)      | Yes                               |
| `install-simcity2000.sh` | SimCity 2000 (1993)                       | City builder  | OpenSC2K 0.3.0 (~100MB, official release) + official DOS demo (~1MB, archive.org, free); full game importable from a GOG copy               | Yes                               |
| `install-simtower.sh`    | SimTower: The Vertical Empire (1994)      | Building sim  | OpenSkyscraper engine build (~5MB, this repo's releases) + retail v1.1b `SIMTOWER.EXE` (~7MB, archive.org, unofficial abandonware download) | Yes                               |
| `install-themehospital.sh` | Theme Hospital (1997)                  | Business sim  | CorsixTH 0.70.1 official macOS build (~98MB, SHA256-verified) + official demo (~13MB, th.corsix.org, SHA256-verified)                         | Yes                               |
| `install-tyrian.sh`      | Tyrian 2000 (1999)                        | SHMUP         | Complete freeware game (all 5 episodes) bundled inside OpenTyrian2000 3.0 (~10MB, Mac Source Ports)                                         | Yes                               |
| `install-unreal-gold.sh` | Unreal Gold (1998)                        | FPS           | Unreal Gold CD ISO (~645MB, OldUnreal)                                                                                                      | Yes                               |
| `install-ut99.sh`        | Unreal Tournament (1999)                  | FPS           | GOTY CD1 ISO (~620MB, OldUnreal)                                                                                                            | Yes                               |
| `install-ut2004.sh`      | Unreal Tournament 2004                    | FPS           | DVD ISO (~2.8GB, OldUnreal)                                                                                                                 | Yes                               |
| `install-warzone2100.sh` | Warzone 2100 (1999)                       | RTS           | Entire game (engine + data, GPLv2+) — official 4.7.0 macOS universal build, no-videos variant (~546MB, SHA256-verified)                       | Yes                               |
| `install-wolf3d.sh`      | Wolfenstein 3D (1992)                     | FPS           | ECWolf 1.4.2 official macOS build (~24MB, SHA256-verified) + shareware v1.4 data files (~1.4MB, all hosted by the ECWolf project, SHA256-verified) | Yes                               |
| `install-et.sh`          | Wolfenstein: Enemy Territory (2003)       | FPS (MP)      | Fully free; original paks pre-installed (~229MB, ET: Legacy official mirror)                                                                | Yes                               |

### Data tiers at a glance

| Tier                              | Meaning                                                                                               | Games                                                                                                                                                                                                     |
|-----------------------------------|-------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Fully free                        | Nothing to buy, nothing to copy — the script installs the complete game                               | Daggerfall, Doom via Freedoom, Marathon Trilogy, OpenRA, OpenTTD ‡, Quake III Arena, ScummVM (BASS, FOTAQ, Lure), Shadow Warrior, Tyrian 2000, Unreal Gold, Unreal Tournament (1999), Unreal Tournament 2004, Warzone 2100, Wolfenstein: Enemy Territory † |
| Free demo; download the full game | A demo or shareware is installed now; if you own the full game, the script downloads its data for you | Diablo, Quake (1996), Quake II                                                                                                                                                                            |
| Free demo; add your own files     | A demo is installed now; to upgrade, copy files from your own copy — the installer prints the steps   | Duke Nukem 3D, HoMM2, HoMM3, SimCity 2000, Theme Hospital, Wolfenstein 3D                                                                                                                                  |
| Abandonware                       | The game is delisted and cannot be bought; the installer fetches an unofficial copy (labeled as such) | SimTower                                                                                                                                                                                                  |

† OpenRA installs the core game files; FMV videos and CD soundtracks can still be added from the original CDs via the in-game "Manage Content" menu.
‡ OpenTTD is fully playable with the freely licensed OpenGFX/OpenSFX/OpenMSX base sets that the script installs; owning the original Transport Tycoon Deluxe is not required (its data can still be used if you have it).

## Quick start (local clone)

```bash
./install-daggerfall.sh    # The Elder Scrolls II: Daggerfall (1996)
./install-diablo.sh        # Diablo (1996)
./install-doom.sh          # Doom via Freedoom (1993)
./install-duke3d.sh        # Duke Nukem 3D (1996)
./install-homm2.sh         # Heroes of Might and Magic II (1996)
./install-homm3.sh         # Heroes of Might and Magic III (1999)
./install-marathon.sh      # Marathon Trilogy (1994-1996)
./install-openra.sh        # OpenRA (C&C, Red Alert, Dune 2000)
./install-openttd.sh       # OpenTTD — Transport Tycoon Deluxe (1995)
./install-quake.sh         # Quake (1996)
./install-quake2.sh        # Quake II (1997)
./install-quake3.sh        # Quake III Arena (1999)
./install-shadowwarrior.sh # Shadow Warrior (1997)
./install-scummvm.sh       # ScummVM: Beneath a Steel Sky, FOTAQ, Lure
./install-simcity2000.sh   # SimCity 2000 (1993)
./install-simtower.sh      # SimTower: The Vertical Empire (1994)
./install-themehospital.sh # Theme Hospital (1997)
./install-tyrian.sh        # Tyrian 2000 (1999)
./install-unreal-gold.sh   # Unreal Gold (1998)
./install-ut99.sh          # Unreal Tournament (1999)
./install-ut2004.sh        # Unreal Tournament 2004
./install-warzone2100.sh   # Warzone 2100 (1999)
./install-wolf3d.sh        # Wolfenstein 3D (1992)
./install-et.sh            # Wolfenstein: Enemy Territory (2003)
```

Or fully unattended (skip confirmation prompt):

```bash
./install-ut99.sh --yes
```

## Requirements

- macOS (Apple Silicon or Intel — 10.9+ for Unreal/UT99, 10.13+ for ScummVM, 10.14+ for OpenTTD/Warzone 2100, 10.15+ for UT2004/OpenRA/GZDoom (Doom via Freedoom), 11+ for OpenSC2K on Intel / 13+ on Apple Silicon)
- `curl` (pre-installed on macOS)
- Disk space varies per game (see below)
- `7zip` needed for UT99 Bonus Pack 4, Quake shareware, Daggerfall, and Duke Nukem 3D shareware (scripts prompt to `brew install` if missing)
- Daggerfall Unity requires Rosetta 2 on Apple Silicon (script installs it automatically if needed)

All engines are native on both Apple Silicon and Intel - universal binaries everywhere except Daggerfall Unity (x86_64, runs via Rosetta 2), VCMI (separate native builds per architecture, no Rosetta needed) and OpenSkyscraper (arm64 only for now — Intel Macs are rejected with a friendly message until an Intel build is published).

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

## Doom via Freedoom (1993)

```bash
./install-doom.sh
```

- **Engine**: GZDoom 4.14.2 (official macOS release from the ZDoom team; universal 2, SHA256-verified)
- **Game data**: Freedoom 0.13.0 — two complete, freely licensed id Tech 1 games (SHA256-verified, from the Freedoom project's own releases):
  - **Freedoom: Phase 1** — standalone Ultimate Doom-style game ("Doom (Freedoom)" launcher)
  - **Freedoom: Phase 2** — standalone Doom II-style, 32-level game ("Doom II (Freedoom)" launcher)
- **Steps**: Install engine → download + install both Freedoom WADs → create two launcher apps
- **Disk space**: ~400MB
- **Launch**: `open '/Applications/Doom/Doom (Freedoom).app'` (or `Doom II (Freedoom).app`)
- **Install location**: `/Applications/Doom/` (GZDoom.app + WADs + launchers)
- **Note**: own Doom or Doom II? Copy the original WADs into `/Applications/Doom` and launch `GZDoom.app` directly — its IWAD picker lists every installed game, Freedoom included. Settings and saves live in `~/Library/Application Support/GZDoom`. FreeDM (free deathmatch WAD) works the same way
- **Improvements over DOS**: modern resolutions and controls, mouse look, widescreen, Full HD/4K mods

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

## OpenTTD — Transport Tycoon Deluxe (1995)

```bash
./install-openttd.sh
```

- **Engine**: OpenTTD 15.3 (official macOS build, Universal 2, Apple Silicon + Intel)
- **Game data**: freely licensed base sets from the OpenTTD team — OpenGFX 8.0 (graphics), OpenSFX 1.0.3 (sound) and OpenMSX 0.4.2 (music); all downloaded from `cdn.openttd.org` with the project's own published SHA256 checksums (~15MB total)
- **Steps**: Install engine → download + extract the base sets into `~/Documents/OpenTTD/baseset` → play (this also skips the in-game first-run graphics download)
- **Disk space**: ~100MB
- **Launch**: `open /Applications/OpenTTD/OpenTTD.app`
- **Game data location**: `~/Documents/OpenTTD` (base sets, saved games, NewGRFs, settings)
- **Note**: No copy of the original Transport Tycoon Deluxe is needed — the free base sets make the game fully playable. If you do own TTD, its data can be used instead
- **Playing with friends**: built-in multiplayer with a live server browser — open the Multiplayer menu to join any game straight from the list, or host your own via "Start Server" (works over LAN and the internet)

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
- **Note**: The original 1999 CD does not include Team Arena. Team Arena, purchase from GOG ($6) or Steam ($15), then copy `missionpack/pak0.pk3`

## Shadow Warrior (1997)

```bash
./install-shadowwarrior.sh
```

- **Engine**: Raze 1.11.0 (universal 2, official Raze release from the GZDoom team; SHA256-verified) — the same engine used for Duke Nukem 3D
- **Game data**: the complete registered game (v1.2) — released as **freeware** in 2016 — mirrored from the official GOG "Classic Complete" Linux package on archive.org (~258MB, SHA256-verified; the registered `Sw.grp` is additionally SHA1-verified); the official CD soundtrack (`shadow02-14.ogg`) is installed alongside
- **Steps**: Install engine → download package → extract the GRP, RTS and soundtrack → create launcher app
- **Disk space**: ~350MB
- **Launch**: `open '/Applications/ShadowWarrior/Shadow Warrior.app'`
- **Install location**: `/Applications/ShadowWarrior/` (Raze.app + game data + soundtrack + launcher)
- **Note**: the Wanton Destruction expansion is installed too (Raze supports it natively and offers it at startup); the GOG package also carries Twin Dragon as loose DOS files that Raze cannot currently load
- **Playing with friends**: Raze supports LAN and direct-connection multiplayer from the in-game menu (basic P2P netcode)

## ScummVM — Beneath a Steel Sky, Flight of the Amazon Queen, Lure of the Temptress

```bash
./install-scummvm.sh
```

- **Engine**: ScummVM 2026.4.0 (official macOS release, Universal 2, signed/notarized)
- **Game data**: three complete adventure games, all released as freeware by their creators and distributed by the ScummVM project itself (SHA256-verified, ~179MB total):
  - **Beneath a Steel Sky** (1994, Revolution Software) — CD version with full speech
  - **Flight of the Amazon Queen** (1995, Interactive Binary Illusions) — CD version
  - **Lure of the Temptress** (1991, Revolution Software)
- **Steps**: Install engine → download + extract the three games into `/Applications/ScummVM/games` → register them with `scummvm --add` → create one launcher app per game
- **Disk space**: ~700MB
- **Launch**: `open '/Applications/ScummVM/Beneath a Steel Sky.app'` (or the FOTAQ / Lure launchers), or `open /Applications/ScummVM/ScummVM.app` for the full ScummVM menu
- **Game data location**: `/Applications/ScummVM/games`; saved games live in `~/Documents/ScummVM Savegames`
- **Note**: ScummVM runs hundreds of classic adventures. The project also distributes more complete freeware titles (Dráscula, DreamWeb, Broken Sword 2.5, Sfinx, Sołtys…) — download one from [scummvm.org/games](https://www.scummvm.org/games/) and add it via "Add Game…" in the launcher

## SimCity 2000 (1993)

```bash
./install-simcity2000.sh
```

- **Engine**: OpenSC2K 0.3.0 ([opensc2k.net](http://opensc2k.net)) — open-source SimCity 2000 remake written in Rust and Godot (MIT license), official macOS build: Universal 2, signed and notarized, macOS 11+ (Intel) / 13+ (Apple Silicon)
- **Game data (free)**: the official **SimCity 2000 DOS demo** (~1MB, SHA256-verified, archive.org) — released for free by Maxis in 1993; gives the complete city-building game
- **Game data (full, your files)**: SimCity 2000 Special Edition (Windows 95) — sold on GOG (~$2.99); point the game's Import Assets at its files (unpack the GOG installer with `innoextract`)
- **Steps**: Download engine DMG (~100MB) → install to `/Applications/SimCity2000` → download + extract the demo → one-time in-game import: main menu **Import Assets** → select `/Applications/SimCity2000/SimCity2000Demo` (the script prints these steps at the end)
- **Disk space**: ~600MB
- **Launch**: `open '/Applications/SimCity2000/OpenSC2K.app'`
- **Demo limits vs the full game**: no in-game newspaper, no SCURK (Urban Renewal Kit) artwork; zoning, budgeting, ordinances, disasters and saving all work
- **Bonus over the original**: city sizes from 16 up to 4096 tiles per side, full-resolution data maps, more zoom levels, FluidSynth MIDI music, autosave, mods via a built-in JavaScript runtime

## SimTower: The Vertical Empire (1994)

```bash
./install-simtower.sh
```

- **Engine**: OpenSkyscraper (open-source reimplementation, GPL-2.0) — built for this repo from the actively maintained community fork ([uaktags/OpenSkyscraper](https://github.com/uaktags/OpenSkyscraper), pinned commit `9976245`), served from this repo's GitHub releases; arm64 (Apple Silicon) only for now
- **Game data**: original retail `SIMTOWER.EXE` v1.1b (~7MB, SHA256-verified, archive.org) — SimTower has been delisted for decades and cannot be bought, so this is an **unofficial abandonware download**; copyright remains with OPeNBook/Maxis (Electronic Arts). Keep it for personal and archival use
- **Steps**: Install engine (~5MB) → download `SIMTOWER.EXE` → run the engine once in resource-dump mode to extract the original graphics/sounds (~385 files: 60+ bitmap sheets, ~58 sounds) → copy UI fonts → done
- **Disk space**: ~50MB
- **Launch**: `open /Applications/SimTower/OpenSkyscraper.app`
- **Game data location**: `~/Library/Application Support/OpenSkyscraper` (the engine's search path, so the app works however it's launched)
- **Status — in-progress reimplementation**: the core game — building floors, offices/hotels/condos, elevators and elevator dispatch, the economy and population simulation — works with the original graphics and sounds. Not every original feature (e.g. saving) is implemented yet; upstream development is ongoing

## Theme Hospital (1997)

```bash
./install-themehospital.sh
```

- **Engine**: CorsixTH 0.70.1 (official macOS release, universal 2, SHA256-verified)
- **Game data (demo, free)**: the official Theme Hospital demo (~13MB, `th.corsix.org` — hosted by the CorsixTH project itself, SHA256-verified)
- **Game data (full, own copy)**: Theme Hospital on GOG (~$5-6) or the EA app
- **Steps**: Install engine → download + extract the demo → pre-configure the data path in `config.txt` (no first-run folder prompt)
- **Disk space**: ~450MB
- **Launch**: `open /Applications/ThemeHospital/CorsixTH.app`
- **Game data location**: `/Applications/ThemeHospital/ThemeHospitalDemo/HOSP`; config in `~/.config/CorsixTH/config.txt`
- **Note**: the current macOS build ships with MIDI playback (RtMidi) disabled, so the in-game MIDI music may stay quiet; sound effects are unaffected. Upgrade by pointing `theme_hospital_install` in config.txt at the full game's HOSP folder (saved games keep working)
- **CorsixTH improvements**: high resolutions, zoom, UI scaling, autosave, map editor

## Tyrian 2000 (1999)

```bash
./install-tyrian.sh
```

- **Engine**: OpenTyrian2000 3.0 (Mac Source Ports build, Universal 2, signed/notarized) — the community fork of OpenTyrian that supports Tyrian 2000's fifth episode
- **Game data**: the complete game (all 5 episodes) is bundled inside the app — Tyrian was released as freeware by Eclipse Software in 2004
- **Steps**: Download DMG (~10MB, SHA256-verified) → copy the app to `/Applications/Tyrian2000` → done — a single download contains engine and game
- **Disk space**: ~50MB
- **Launch**: `open /Applications/Tyrian2000/opentyrian2000.app`
- **Saves**: high scores and saved games live in `~/.config/opentyrian2000`

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

## Warzone 2100 (1999)

```bash
./install-warzone2100.sh
```

- **Engine + game**: Warzone 2100 4.7.0 official macOS release (universal 2) — engine *and* all game data are free (GPLv2+), liberated by the original publisher in 2004
- **Package**: official no-videos build (~546MB, project-published SHA256, 10.14+) — campaign, skirmish, multiplayer and the full soundtrack included; the script strips the bundled debug symbols (~450MB) during install
- **Steps**: Download → verify SHA256 → unpack → strip debug bundle → install to /Applications
- **Disk space**: ~1.2GB free during install (~800MB installed)
- **Launch**: `open '/Applications/Warzone2100/Warzone 2100.app'`
- **Note**: the campaign FMV briefing videos are excluded from this build to halve the download (gameplay is identical); the full official build can replace it at any time from [wz2100.net/download](https://wz2100.net/download/)
- **Saved games/settings**: `~/Library/Application Support/Warzone 2100 Project`
- **Playing with friends**: built-in multiplayer lobby with a live server list (LAN + internet) plus skirmish vs AI — join straight from the menu

## Wolfenstein 3D (1992)

```bash
./install-wolf3d.sh
```

- **Engine**: ECWolf 1.4.2 — official macOS release from the ECWolf project's own site (quad-arch universal: Apple Silicon, Intel, i386, PowerPC; works from macOS 10.4; SHA256-verified)
- **Game data**: the freely redistributable shareware v1.4 — Episode 1 with all 10 levels (~1.4MB, the eight `.WL1` files, also hosted by the ECWolf project; SHA256-verified)
- **Steps**: Install engine → download + extract the shareware → place the data in ECWolf's search path → create launcher app
- **Disk space**: ~120MB
- **Launch**: `open '/Applications/Wolf3D/Wolfenstein 3D.app'`
- **Install location**: `/Applications/Wolf3D/` (ECWolf.app + launcher); game data lives in `~/Library/Application Support/ECWolf` — ECWolf's documented search path
- **ECWolf improvements**: modern resolutions and widescreen, WASD + mouse controls, unlimited saves, mod support (DECORATE-style scripting, Wolf3D mods work without touching originals)
- **Upgrade**: full game (6 episodes + Spear of Destiny) from an owned Steam/GOG copy (~$5) — copy the `.WL6`/`.SOD` files into `~/Library/Application Support/ECWolf`; ECWolf auto-detects Steam/GOG installs too
- **Playing with friends**: co-op and deathmatch for up to 11 players via direct connection (`ecwolf --host` / `--join <ip>`, LAN-focused)

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
- `install-doom.sh` — Doom via Freedoom (1993) installer
- `install-duke3d.sh` — Duke Nukem 3D (1996) installer
- `install-homm2.sh` — Heroes of Might and Magic II (1996) installer
- `install-homm3.sh` — Heroes of Might and Magic III (1999) installer
- `install-marathon.sh` — Marathon Trilogy (1994-1996) installer
- `install-openra.sh` — OpenRA (C&C, Red Alert, Dune 2000) installer
- `install-openttd.sh` — OpenTTD (Transport Tycoon Deluxe) installer
- `install-quake.sh` — Quake (1996) installer
- `install-quake2.sh` — Quake II (1997) installer
- `install-quake3.sh` — Quake III Arena (1999) installer
- `install-scummvm.sh` — ScummVM (Beneath a Steel Sky, FOTAQ, Lure) installer
- `install-shadowwarrior.sh` — Shadow Warrior (1997) installer
- `install-simcity2000.sh` — SimCity 2000 (1993) installer
- `install-simtower.sh` — SimTower: The Vertical Empire (1994) installer
- `install-themehospital.sh` — Theme Hospital (1997) installer
- `install-tyrian.sh` — Tyrian 2000 (1999) installer
- `install-unreal-gold.sh` — Unreal Gold (1998) installer
- `install-ut99.sh` — Unreal Tournament (1999) installer
- `install-ut2004.sh` — Unreal Tournament 2004 installer
- `install-warzone2100.sh` — Warzone 2100 (1999) installer
- `install-wolf3d.sh` — Wolfenstein 3D (1992) installer
- `install-et.sh` — Wolfenstein: Enemy Territory (2003) installer
- `original.sh` — original untested UT99 script (kept for reference)

## Playing with friends

Every multiplayer-capable game can be hosted from its in-game multiplayer menu, and every installer sets the game up for both hosting and joining.

How you find each other depends on the game:

- **Join straight from the menu** — built-in browsers and lobbies, nothing to enter or exchange: Marathon Trilogy (live metaserver browser, including full campaign co-op), Wolfenstein: Enemy Territory (public server list), OpenRA (lobby), OpenTTD (built-in server list, LAN and internet), Warzone 2100 (built-in multiplayer lobby)
- **Direct host/join** — Unreal Tournament, Unreal Gold, UT2004, Quake, Quake II, Quake III, Diablo, Duke Nukem 3D, Shadow Warrior, Doom via Freedoom, Wolfenstein 3D: one player hosts from the game's multiplayer menu and the others connect from theirs; the address to enter is shown in each game's join dialog (works over LAN, and over the internet where the host's network allows it)
- **Hot-seat** — HoMM2: take turns on the same Mac
