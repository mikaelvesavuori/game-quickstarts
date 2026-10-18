#!/bin/bash
set -euo pipefail

# SimTower: The Vertical Empire (1994) — played through OpenSkyscraper,
# an open-source reimplementation of the original game (GPL-2.0). This
# build is produced from the actively maintained community fork at
# https://github.com/uaktags/OpenSkyscraper (pinned commit 9976245),
# packaged for this repo and served from its GitHub releases.
#
# The engine implements the game logic itself; the original graphics,
# sounds and palettes are extracted at install time from the original
# game's SIMTOWER.EXE (a Windows 3.x NE executable) — the engine's
# --dump-resources mode converts them into PNG/WAV files under
# ~/Library/Application Support/OpenSkyscraper, where the game looks
# for them at runtime.
#
# SimTower has been delisted for decades and is not sold anywhere.
# The game data below is an unofficial abandonware copy of the retail
# v1.1b English release, hosted on archive.org. Copyright remains
# with OPeNBook/Maxis (Electronic Arts) — keep your copy for archival
# and personal use only.
ENGINE_VERSION="9976245"
ENGINE_URL="https://github.com/mikaelvesavuori/game-quickstarts/releases/download/openskyscraper-9976245/OpenSkyscraper-macos-arm64.zip"
ENGINE_ZIP="OpenSkyscraper-macos-arm64.zip"
ENGINE_SHA256="9068fdcf71126fa9b2100057024631ebd93b76a6ca0380be110352faec8e0c38"

SIMTOWER_EXE_URL="https://archive.org/download/SIMTOWER/Sim%20Tower/SimTower/SIMTOWER.EXE"
SIMTOWER_EXE="SIMTOWER.EXE"
SIMTOWER_SHA256="2825a3c53f77945c63b6d72e26faa7dde5ddd56c31ca668e67a12576d7feca96"

INSTALL_DIR="/Applications/SimTower"
APP_PATH="$INSTALL_DIR/OpenSkyscraper.app"
ENGINE_BIN="$APP_PATH/Contents/MacOS/OpenSkyscraper"

# The engine searches this directory for SIMTOWER.EXE and the
# extracted bitmaps/sounds at runtime, which makes the app work
# no matter how it is launched (Finder, Terminal, Spotlight).
DATA_DIR="$HOME/Library/Application Support/OpenSkyscraper"

TEMP_DIR=""
AUTO_YES=false

cleanup() {
    local exit_code=$?
    if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "${TEMP_DIR:-}" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    exit $exit_code
}
trap cleanup EXIT

verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual
    actual=$(shasum -a 256 "$file" | awk '{print $1}')
    if [[ "$actual" != "$expected" ]]; then
        echo "Error: SHA256 verification failed for $(basename "$file")"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
    echo "  Checksum verified."
}

preflight() {
    echo "=== SimTower: The Vertical Empire (1994) Quickstart Installer ==="
    echo ""

    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Error: This script is for macOS only."
        exit 1
    fi

    local arch
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        echo "System: macOS on Apple Silicon (arm64)"
    else
        echo "System: macOS on Intel ($arch)"
        echo ""
        echo "Error: The OpenSkyscraper engine build currently only supports"
        echo "Apple Silicon (arm64). An Intel build may be added later."
        exit 1
    fi
    echo ""

    for cmd in curl unzip shasum; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command not found: $cmd"
            exit 1
        fi
    done

    local free_kb
    free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local required_kb=307200
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 300MB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Download OpenSkyscraper commit ${ENGINE_VERSION} (~5MB)"
    echo "     (open-source SimTower engine, built for this repo from the"
    echo "     community fork, GPL-2.0)"
    echo "  2. Verify the download with SHA256"
    echo "  3. Install it to $INSTALL_DIR"
    echo "  4. Download the original SimTower game (~7MB) from archive.org"
    echo "  5. Verify it with SHA256 and extract all graphics, sounds"
    echo "     and fonts the engine needs into $DATA_DIR"
    echo ""
    echo "SimTower (OPeNBook/Maxis, 1994) is delisted and has not been"
    echo "sold anywhere for decades. The downloaded SIMTOWER.EXE is an"
    echo "unofficial abandonware copy of the retail v1.1b English game;"
    echo "copyright remains with OPeNBook/Maxis (Electronic Arts)."
    echo ""
    echo "OpenSkyscraper is an in-progress open-source reimplementation:"
    echo "the core game — building, elevators, hotels/offices, the economy"
    echo "simulation — works, but not every feature of the original game"
    echo "is implemented yet."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing OpenSkyscraper ${ENGINE_VERSION} ==="

    if [[ -d "$INSTALL_DIR" ]]; then
        echo "  $INSTALL_DIR already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing installation? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing installation."
                return 0
            fi
        fi
        rm -rf "$INSTALL_DIR"
    fi

    mkdir -p "$INSTALL_DIR"

    echo "  Downloading OpenSkyscraper (~5MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_ZIP" "$ENGINE_URL"
    verify_sha256 "$TEMP_DIR/$ENGINE_ZIP" "$ENGINE_SHA256"

    echo "  Extracting app to $INSTALL_DIR..."
    unzip -q -o "$TEMP_DIR/$ENGINE_ZIP" -d "$INSTALL_DIR"

    if [[ ! -x "$ENGINE_BIN" ]]; then
        echo "Error: OpenSkyscraper.app not found after extraction."
        return 1
    fi

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  OpenSkyscraper installed."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Installing SimTower game data ==="

    if [[ -f "$DATA_DIR/$SIMTOWER_EXE" ]]; then
        echo "  $DATA_DIR/$SIMTOWER_EXE already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
    fi

    mkdir -p "$DATA_DIR"

    echo "  Downloading SimTower v1.1b (~7MB, archive.org)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$SIMTOWER_EXE" "$SIMTOWER_EXE_URL"
    verify_sha256 "$TEMP_DIR/$SIMTOWER_EXE" "$SIMTOWER_SHA256"
    cp "$TEMP_DIR/$SIMTOWER_EXE" "$DATA_DIR/$SIMTOWER_EXE"

    echo "  Copying UI fonts next to the game data..."
    rm -rf "$DATA_DIR/fonts"
    cp -R "$APP_PATH/Contents/Resources/fonts" "$DATA_DIR/fonts"

    echo "  Extracting graphics and sounds from SIMTOWER.EXE"
    echo "  (runs the engine once in resource-dump mode)..."
    if (cd "$DATA_DIR" && "$ENGINE_BIN" --dump-resources "$DATA_DIR" > "$TEMP_DIR/dump.log" 2>&1); then
        :
    else
        echo "Error: Resource extraction failed. Engine output:"
        tail -20 "$TEMP_DIR/dump.log" 2>/dev/null || true
        return 1
    fi

    local png_count sound_count
    png_count=$(find "$DATA_DIR/bitmaps" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
    sound_count=$(find "$DATA_DIR/sounds" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$png_count" -lt 40 ]] || [[ "$sound_count" -lt 20 ]]; then
        echo "Error: Extracted resources look incomplete"
        echo "  (found $png_count bitmap sheets, $sound_count sound files)."
        return 1
    fi

    echo "  Extracted $png_count bitmap sheets and $sound_count sounds."
    echo "  Game data installed."
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "SimTower is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open '$APP_PATH'"
    echo ""
    echo "Or find 'OpenSkyscraper' in $INSTALL_DIR"
    echo ""
    echo "The game data lives in:"
    echo "  $DATA_DIR"
    echo ""
    echo "Reminder: OpenSkyscraper is an open-source reimplementation in"
    echo "progress — core play works, some original features are missing."
    echo "SimTower remains copyright OPeNBook/Maxis (Electronic Arts);"
    echo "keep your unofficial copy for personal and archival use."
    echo ""
}

main() {
    if [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]]; then
        AUTO_YES=true
    fi

    preflight
    confirm

    TEMP_DIR=$(mktemp -d)
    echo "  Temp directory: $TEMP_DIR"

    install_engine
    install_game_data
    finish
}

main "$@"
