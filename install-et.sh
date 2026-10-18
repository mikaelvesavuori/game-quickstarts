#!/bin/bash
set -euo pipefail

ET_VERSION="2.86.2"
ET_DMG_URL="https://www.etlegacy.com/download/file/788"
ET_DMG_FILE="etlegacy-v${ET_VERSION}.dmg"
ET_DMG_MD5="d32bc156f60b15e6541caf7d351e650e"

# The DMG ("binaries") build does not download game data by itself, so the
# original 2005 data paks are pre-installed from ET: Legacy's official mirror.
PAK0_URL="https://mirror.etlegacy.com/etmain/pak0.pk3"
PAK0_SHA256="712966b20e06523fe81419516500e499c86b2b4fec823856ddbd333fcb3d26e5"
PAK1_URL="https://mirror.etlegacy.com/etmain/pak1.pk3"
PAK1_SHA256="5610fd749024405b4425a7ce6397e58187b941d22092ef11d4844b427df53e5d"
PAK2_URL="https://mirror.etlegacy.com/etmain/pak2.pk3"
PAK2_SHA256="a48ab749a1a12ab4d9137286b1f23d642c29da59845b2bafc8f64e052cf06f3e"

INSTALL_DIR="/Applications/ETLegacy"
APP_PATH="$INSTALL_DIR/ET Legacy.app"
ETMAIN_DIR="$INSTALL_DIR/etmain"

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

verify_md5() {
    local file="$1"
    local expected="$2"
    local actual
    actual=$(md5 -q "$file")
    if [[ "$actual" != "$expected" ]]; then
        echo "Error: MD5 verification failed for $(basename "$file")"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
    echo "  Checksum verified."
}

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
    echo "=== Wolfenstein: Enemy Territory (ET: Legacy) Quickstart Installer ==="
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

    for cmd in curl hdiutil md5 shasum; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command not found: $cmd"
            exit 1
        fi
    done

    local free_kb
    free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local required_kb=786432
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 768MB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Download the official ET: Legacy v${ET_VERSION} macOS release"
    echo "     (Universal 2: Apple Silicon + Intel, ~48MB)"
    echo "  2. Verify the download with MD5"
    echo "  3. Install it to $INSTALL_DIR"
    echo "  4. Download the original 2003 game data (pak0-2, ~229MB total)"
    echo "     from ET: Legacy's official mirror and install it into etmain/"
    echo "     (SHA256-verified — the game data was released as freeware)"
    echo ""
    echo "Wolfenstein: Enemy Territory is a fully free, multiplayer-only game —"
    echo "engine and game data alike (released as freeware by id Software / Splash Damage)."
    echo "ET: Legacy is the actively maintained open source continuation."
    echo ""
    echo "The DMG build does not download game data on its own, so this script"
    echo "pre-installs it — the game is playable immediately after install."
    echo ""
    echo "Playing with friends:"
    echo "  ET: Legacy connects to the live master server out of the box —"
    echo "  just pick 'Play Online' and join any public server, or host your own."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing ET: Legacy v${ET_VERSION} ==="

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

    echo "  Downloading ET: Legacy DMG (~48MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ET_DMG_FILE" "$ET_DMG_URL"
    verify_md5 "$TEMP_DIR/$ET_DMG_FILE" "$ET_DMG_MD5"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$ET_DMG_FILE" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    if [[ ! -d "$DMG_MOUNT/ETLegacy" ]]; then
        echo "Error: ETLegacy folder not found in DMG."
        hdiutil detach "$DMG_MOUNT" -quiet 2>/dev/null || true
        DMG_MOUNT=""
        return 1
    fi

    echo "  Copying ETLegacy folder to /Applications..."
    if ! cp -R "$DMG_MOUNT/ETLegacy" "$INSTALL_DIR"; then
        echo "Error: Failed to copy to $INSTALL_DIR."
        return 1
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$INSTALL_DIR" 2>/dev/null || true

    echo "  ET: Legacy installed."
}

download_pak() {
    local file="$1"
    local url="$2"
    local sha256="$3"

    echo "  Downloading ${file}..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$file" "$url"
    verify_sha256 "$TEMP_DIR/$file" "$sha256"
    mv "$TEMP_DIR/$file" "$ETMAIN_DIR/$file"
}

install_game_data() {
    echo ""
    echo "=== Step 2: Installing original game data (pak0-2) ==="

    if [[ -f "$ETMAIN_DIR/pak0.pk3" ]]; then
        echo "  pak0.pk3 already exists in $ETMAIN_DIR."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
        rm -f "$ETMAIN_DIR/pak0.pk3" "$ETMAIN_DIR/pak1.pk3" "$ETMAIN_DIR/pak2.pk3"
    fi

    download_pak "pak0.pk3" "$PAK0_URL" "$PAK0_SHA256"
    download_pak "pak1.pk3" "$PAK1_URL" "$PAK1_SHA256"
    download_pak "pak2.pk3" "$PAK2_URL" "$PAK2_SHA256"

    echo "  Game data installed."
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Wolfenstein: Enemy Territory is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open '$APP_PATH'"
    echo ""
    echo "Or find 'ET Legacy' inside $INSTALL_DIR"
    echo ""
    echo "Game data (pak0-2) is pre-installed in $ETMAIN_DIR"
    echo "Your profile, etkey and downloaded maps live in:"
    echo "  ~/Library/Application Support/etlegacy"
    echo ""
    echo "Playing with friends:"
    echo "  Pick 'Play Online' and join a public server (live master server)"
    echo "  or host your own - the bundled 'etlded' can run a dedicated server."
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
