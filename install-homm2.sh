#!/bin/bash
set -euo pipefail

FHEROES2_VERSION="1.1.17"
ENGINE_URL="https://github.com/MacSourcePorts/MSPBuildSystem/releases/download/fheroes2_${FHEROES2_VERSION}/fheroes2-${FHEROES2_VERSION}.dmg"
ENGINE_FILE="fheroes2-${FHEROES2_VERSION}.dmg"
ENGINE_SHA256="401fdc5d7fae0d252fca0f2449f574c958f9a9a384c8a17f9a1716f5331191ad"
APP_NAME="fheroes2.app"

# Official HoMM2 demo data, as used by fheroes2's own bundled download script.
H2DEMO_URL="https://archive.org/download/HeroesofMightandMagicIITheSuccessionWars_1020/h2demo.zip"
H2DEMO_SHA256="12048c8b03875c81e69534a3813aaf6340975e77b762dc1b79a4ff5514240e3c"

INSTALL_DIR="/Applications/HoMM2"
APP_PATH="$INSTALL_DIR/$APP_NAME"
DATA_DIR="$HOME/Library/Application Support/fheroes2"

TEMP_DIR=""
DMG_MOUNT=""
AUTO_YES=false

cleanup() {
    local exit_code=$?
    if [[ -n "${DMG_MOUNT:-}" ]]; then
        hdiutil detach "$DMG_MOUNT" -force -quiet 2>/dev/null || true
    fi
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
    echo "=== Heroes of Might and Magic II (1996) Demo Quickstart Installer ==="
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
    fi
    echo ""

    for cmd in curl hdiutil unzip shasum; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command not found: $cmd"
            exit 1
        fi
    done

    local free_kb
    free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local required_kb=314573
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 307MB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Install fheroes2 v${FHEROES2_VERSION} (Universal 2, signed & notarized)"
    echo "     to /Applications/HoMM2"
    echo "  2. Download the official HoMM2 demo data (~40MB, freely distributable)"
    echo "     using the exact source and checksum from fheroes2's own installer script"
    echo "  3. Pre-install the demo data so the game is ready immediately"
    echo ""
    echo "fheroes2 is the maintained open source recreation of the HoMM2 engine."
    echo ""
    echo "You can upgrade to the full game (The Succession Wars + Price of Loyalty)"
    echo "at any time - see the instructions printed at the end of this installation."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing fheroes2 v${FHEROES2_VERSION} ==="

    if [[ -d "$APP_PATH" ]]; then
        echo "  $APP_NAME already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing installation? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing installation."
                return 0
            fi
        fi
        rm -rf "$APP_PATH"
    fi

    mkdir -p "$INSTALL_DIR"

    echo "  Downloading fheroes2 DMG..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_URL"
    verify_sha256 "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_SHA256"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$ENGINE_FILE" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    local app_src=""
    for dir in "$DMG_MOUNT"/*.app "$DMG_MOUNT"/*.app/; do
        if [[ -d "$dir" ]]; then
            app_src="${dir%/}"
            break
        fi
    done

    if [[ -z "$app_src" || ! -d "$app_src" ]]; then
        echo "Error: $APP_NAME not found in DMG."
        hdiutil detach "$DMG_MOUNT" -quiet 2>/dev/null || true
        DMG_MOUNT=""
        return 1
    fi

    echo "  Copying $(basename "$app_src") to $INSTALL_DIR..."
    if ! cp -R "$app_src" "$INSTALL_DIR/"; then
        echo "Error: Failed to copy to $INSTALL_DIR."
        return 1
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  Engine installed."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Downloading HoMM2 demo data ==="

    if [[ -d "$DATA_DIR/demo" ]]; then
        echo "  Demo data already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
        rm -rf "$DATA_DIR/demo" "$DATA_DIR/data" "$DATA_DIR/maps"
    fi

    mkdir -p "$DATA_DIR/demo"

    echo "  Downloading the official HoMM2 demo (~40MB)..."
    curl -f -L --progress-bar -o "$DATA_DIR/demo/h2demo.zip" "$H2DEMO_URL"
    verify_sha256 "$DATA_DIR/demo/h2demo.zip" "$H2DEMO_SHA256"

    echo "  Extracting..."
    unzip -q -o "$DATA_DIR/demo/h2demo.zip" -d "$DATA_DIR/demo"

    mkdir -p "$DATA_DIR/data" "$DATA_DIR/maps"
    if [[ -d "$DATA_DIR/demo/DATA" ]]; then
        cp -r "$DATA_DIR/demo/DATA/." "$DATA_DIR/data/"
    else
        echo "Error: DATA folder not found in demo archive."
        return 1
    fi
    if [[ -d "$DATA_DIR/demo/MAPS" ]]; then
        cp -r "$DATA_DIR/demo/MAPS/." "$DATA_DIR/maps/"
    else
        echo "Error: MAPS folder not found in demo archive."
        return 1
    fi

    echo "  Cleaning up demo extraction (keeping h2demo.zip for reference)..."
    rm -rf "$DATA_DIR/demo/DATA" "$DATA_DIR/demo/MAPS" "$DATA_DIR/demo/GAMES" "$DATA_DIR/demo/HELP"

    mkdir -p "$DATA_DIR/music"
    echo "  Demo data installed."
}

print_upgrade_instructions() {
    echo ""
    echo "=== Upgrading to the Full Game ==="
    echo ""
    echo "The demo includes a sample of the full campaign."
    echo ""
    echo "To get the full game:"
    echo ""
    echo "  1. Buy Heroes of Might and Magic 2 from GOG (~\$5)"
    echo ""
    echo "  2. Extract the game files from the GOG installer using innoextract"
    echo "     (brew install innoextract):"
    echo "        innoextract setup_hoMM2_*.exe -I app"
    echo ""
    echo "  3. Copy the extracted game files into:"
    echo "     $DATA_DIR"
    echo "     The app will pick up the full DATA and MAPS automatically."
    echo ""
    echo "  Music (the demo shipped without any):"
    echo "  The original opera soundtrack is included in the GOG copy's MUSIC"
    echo "  folder. Copy its contents into:"
    echo "     $DATA_DIR/music"
    echo "  fheroes2 picks up .ogg/.mp3/.flac files there automatically."
    echo ""
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Heroes of Might and Magic II is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open $APP_PATH"
    echo ""
    echo "Or find $APP_NAME in $INSTALL_DIR"
    echo ""
    echo "Game data location: $DATA_DIR"
    echo ""
    echo "Note: The 1996 demo shipped without music tracks - this is expected."
    echo "      The full soundtrack can be added later (see the instructions above)."
    echo ""
    echo "Playing with friends:"
    echo "  HoMM2 supports hot-seat multiplayer - take turns on the same Mac."
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
    print_upgrade_instructions
    finish
}

main "$@"
