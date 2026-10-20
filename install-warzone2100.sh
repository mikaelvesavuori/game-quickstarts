#!/bin/bash
set -euo pipefail

# Warzone 2100 4.7.0 — 100% free and open source (GPLv2+, game data included).
# The entire game — engine, campaign, multiplayer and soundtrack — was
# liberated by Eidos/Pumpkin Studios in 2004, so this is a one-download
# install with nothing else to buy or copy.
WZ_VERSION="4.7.0"
ENGINE_URL="https://github.com/Warzone2100/warzone2100/releases/download/${WZ_VERSION}/warzone2100_macOS_universal_novideos.zip"
ENGINE_FILE="warzone2100_macOS_universal_novideos.zip"
ENGINE_SHA256="925dde05b4580eae247ed77ffb611b3746686afa890f4ebf6b378a232e37e29a"

# This is the project's official "no videos" build: identical gameplay with
# a much smaller download. The full build (with the campaign FMV briefings)
# is available from wz2100.net/download — see the notes at the end.

INSTALL_DIR="/Applications/Warzone2100"
APP_PATH="$INSTALL_DIR/Warzone 2100.app"

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
    echo "=== Warzone 2100 (1999) Quickstart Installer ==="
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

    for cmd in curl unzip shasum; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command not found: $cmd"
            exit 1
        fi
    done

    local free_kb
    free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local required_kb=1258291
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 1.2GB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Download Warzone 2100 v${WZ_VERSION} for macOS (~546MB)"
    echo "     (Universal 2: Apple Silicon + Intel; official release)"
    echo "     SHA256-verified against the checksum published by the project"
    echo "  2. Install it to $INSTALL_DIR"
    echo ""
    echo "Warzone 2100 is 100% free (GPLv2+) — the game and its data were"
    echo "open-sourced by the original publisher. This download includes"
    echo "the campaign, skirmish, multiplayer and the full soundtrack."
    echo ""
    echo "This is the official build without the campaign FMV briefing"
    echo "videos (smaller download); gameplay is identical. See the notes"
    echo "at the end for adding the videos."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_game() {
    echo ""
    echo "=== Step 1: Installing Warzone 2100 v${WZ_VERSION} ==="

    if [[ -d "$APP_PATH" ]]; then
        echo "  Warzone 2100.app already exists."
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

    echo "  Downloading Warzone 2100 (~546MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_URL"
    verify_sha256 "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_SHA256"

    echo "  Unpacking..."
    unzip -q -o "$TEMP_DIR/$ENGINE_FILE" -d "$TEMP_DIR/wz"

    echo "  Removing bundled debug symbols (~450MB)..."
    rm -rf "$TEMP_DIR/wz/Warzone 2100.app/Contents/MacOS/Warzone 2100.dSYM"

    echo "  Copying Warzone 2100.app to $INSTALL_DIR..."
    cp -R "$TEMP_DIR/wz/Warzone 2100.app" "$INSTALL_DIR/"

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  Installed."
}

print_notes() {
    echo ""
    echo "=== Notes ==="
    echo ""
    echo "Campaign briefing videos:"
    echo "  This build ships without the FMV briefing videos to keep the"
    echo "  download small. The full build (with videos included) is at"
    echo "  https://wz2100.net/download - download the standard macOS zip,"
    echo "  replace the app, and the campaign plays its videos."
    echo ""
    echo "Saved games and settings:"
    echo "  ~/Library/Application Support/Warzone 2100 Project"
    echo ""
    echo "Playing with friends:"
    echo "  Built-in multiplayer lobby with a live server list - open the"
    echo "  Multiplayer menu and join straight from the list, or host a"
    echo "  game of your own. Works on LAN and the internet. Skirmish vs"
    echo "  AI bots is also built in."
    echo ""
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Warzone 2100 is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open '$APP_PATH'"
    echo ""
    echo "Or find 'Warzone 2100' in $INSTALL_DIR"
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

    install_game
    print_notes
    finish
}

main "$@"
