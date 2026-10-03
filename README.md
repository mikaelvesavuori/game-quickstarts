# Retro Game Quickstart

One-script installers for classic games on macOS — Apple Silicon and Intel. Each script downloads the engine, game data, and sets everything up in a single run. Run any of them with a single `curl | bash` command — no clone required (see [Run from the web](#run-from-the-web)).

## Run from the web

No clone needed — run any installer with a single command (macOS, Apple Silicon or Intel). The scripts are self-contained and read prompts from your terminal (`/dev/tty`), so piping over `curl | bash` works exactly like running a local clone.

### Interactive menu

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/quickstart.sh | bash
```

Pick a game directly by number (1-7):

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/quickstart.sh | bash -s -- 3
```

Forward flags to the installer (e.g. unattended mode):

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/quickstart.sh | bash -s -- 3 --yes
```

### Run a specific game directly

```bash
# 1. Unreal Tournament (1999)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-ut99.sh | bash

# 2. Unreal Gold (1998)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-unreal-gold.sh | bash

# 3. Unreal Tournament 2004
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-ut2004.sh | bash

# 4. Quake III Arena
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-quake3.sh | bash

# 5. Quake (1996)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-quake.sh | bash

# 6. The Elder Scrolls II: Daggerfall
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-daggerfall.sh | bash

# 7. OpenRA (C&C, Red Alert, Dune 2000)
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-openra.sh | bash
```

Unattended (skip all confirmation prompts):

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelvesavuori/game-quickstarts/main/install-ut99.sh | bash -s -- --yes
```

| # | Game | One-liner |
|---|------|-----------|
| 1 | Unreal Tournament (1999) | `curl -fsSL …/install-ut99.sh \| bash` |
| 2 | Unreal Gold (1998) | `curl -fsSL …/install-unreal-gold.sh \| bash` |
| 3 | Unreal Tournament 2004 | `curl -fsSL …/install-ut2004.sh \| bash` |
| 4 | Quake III Arena | `curl -fsSL …/install-quake3.sh \| bash` |
| 5 | Quake (1996) | `curl -fsSL …/install-quake.sh \| bash` |
| 6 | The Elder Scrolls II: Daggerfall | `curl -fsSL …/install-daggerfall.sh \| bash` |
| 7 | OpenRA (C&C, Red Alert, Dune 2000) | `curl -fsSL …/install-openra.sh \| bash` |

> All game data is downloaded, checksum-verified, and cleaned up safely even on Ctrl+C. The menu launcher (`quickstart.sh`) just downloads the chosen installer to a temp dir and runs it, so it stays tiny and always serves the latest version from `main`.

## Installers

| Script | Game | Genre | Game data source | One-click? |
|--------|------|-------|-----------------|------------|
| `install-ut99.sh` | Unreal Tournament (1999) | FPS | GOTY CD1 ISO (~620MB, OldUnreal) | Yes |
| `install-unreal-gold.sh` | Unreal Gold (1998) | FPS | Unreal Gold CD ISO (~645MB, OldUnreal) | Yes |
| `install-ut2004.sh` | Unreal Tournament 2004 | FPS | DVD ISO (~2.8GB, OldUnreal) | Yes |
| `install-quake3.sh` | Quake III Arena | FPS | CD ISO (~530MB, archive.org) | Yes |
| `install-quake.sh` | Quake (1996) | FPS | Full game (~597MB, archive.org) or Shareware (Episode 1, free) | Yes — prompts for legitimate copy |
| `install-daggerfall.sh` | The Elder Scrolls II: Daggerfall | RPG | Full game (~107MB, archive.org, free) | Yes |
| `install-openra.sh` | C&C, Red Alert, Dune 2000 | RTS | Quick-install packages (~33MB, OpenRA mirrors) | Yes |

## Quick start (local clone)

```bash
./install-ut99.sh          # Unreal Tournament 99
./install-unreal-gold.sh   # Unreal Gold
./install-ut2004.sh        # UT2004
./install-quake3.sh        # Quake III Arena
./install-quake.sh         # Quake (shareware)
./install-daggerfall.sh    # The Elder Scrolls II: Daggerfall
./install-openra.sh        # Command & Conquer, Red Alert, Dune 2000
```

Or fully unattended (skip confirmation prompt):

```bash
./install-ut99.sh --yes
```

## Requirements

- macOS (Apple Silicon or Intel, 10.9+ for Unreal/UT99, 10.15+ for UT2004/OpenRA)
- `curl` (pre-installed on macOS)
- Disk space varies per game (see below)
- `7zip` needed for UT99 Bonus Pack 4, Quake shareware, and Daggerfall (scripts prompt to `brew install` if missing)
- Daggerfall Unity requires Rosetta 2 on Apple Silicon (script installs it automatically if needed)

All engines are universal binaries (no Rosetta 2 needed) except Daggerfall Unity (x86_64, runs via Rosetta 2).

---

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

## Quake III Arena

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

## The Elder Scrolls II: Daggerfall

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
- `install-ut99.sh` — Unreal Tournament (1999) installer
- `install-unreal-gold.sh` — Unreal Gold (1998) installer
- `install-ut2004.sh` — Unreal Tournament 2004 installer
- `install-quake3.sh` — Quake III Arena installer
- `install-quake.sh` — Quake (1996) installer
- `install-daggerfall.sh` — The Elder Scrolls II: Daggerfall installer
- `install-openra.sh` — OpenRA (C&C, Red Alert, Dune 2000) installer
- `original.sh` — original untested UT99 script (kept for reference)

## Playing with friends

For all multiplayer-capable games, host a game from the in-game multiplayer menu and share your IP address with friends. All installers set up the game for both hosting and joining.
