#!/bin/bash
set -euo pipefail

# OpenTyrian2000 3.0 (Mac Source Ports build, July 2025) — Universal 2,
# signed and notarized. The complete freeware Tyrian 2000 game data
# (all 5 episodes) is bundled inside the app, so this is a one-download
# install: engine and game data in a single DMG.
OT2K_VERSION="3.0"
OT2K_URL="https://github.com/MacSourcePorts/opentyrian2000/releases/download/3.0_2025-07-12/opentyrian2000-3.0.dmg"
OT2K_DMG="opentyrian2000-3.0.dmg"
OT2K_SHA256="b28ffbf5dc4e9cacfa76e763f682cdfc68978482494cbc7b4cb51d027fa7afb0"

# OpenTyrian2000 is the community fork of OpenTyrian that supports the
# fifth episode added by Tyrian 2000 (the v3.0 patch of Tyrian, 1999).
# Tyrian was released as freeware by Eclipse Software in 2004.

INSTALL_DIR="/Applications/Tyrian2000"
APP_PATH="$INSTALL_DIR/opentyrian2000.app"

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
    echo "=== Tyrian 2000 (1999) Quickstart Installer ==="
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

    for cmd in curl hdiutil shasum; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command not found: $cmd"
            exit 1
        fi
    done

    local free_kb
    free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local required_kb=102400
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 100MB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Download the OpenTyrian2000 v${OT2K_VERSION} macOS release (~10MB)"
    echo "     (Universal 2: Apple Silicon + Intel, signed and notarized)"
    echo "  2. Verify the download with SHA256"
    echo "  3. Install it — with the complete game data — to $INSTALL_DIR"
    echo ""
    echo "Tyrian 2000 is fully free — the game was released as freeware by"
    echo "Eclipse Software in 2004. This build includes all 5 episodes, so"
    echo "the game is playable immediately after install."
    echo ""
    echo "OpenTyrian2000 is the community-maintained engine port (a fork of"
    echo "OpenTyrian); the build comes from Mac Source Ports."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing OpenTyrian2000 v${OT2K_VERSION} ==="

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

    echo "  Downloading OpenTyrian2000 DMG (~10MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$OT2K_DMG" "$OT2K_URL"
    verify_sha256 "$TEMP_DIR/$OT2K_DMG" "$OT2K_SHA256"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$OT2K_DMG" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    if [[ ! -d "$DMG_MOUNT/opentyrian2000.app" ]]; then
        echo "Error: opentyrian2000.app not found in DMG."
        return 1
    fi

    echo "  Copying app (engine + full game data) to /Applications..."
    if ! cp -R "$DMG_MOUNT/opentyrian2000.app" "$INSTALL_DIR/"; then
        echo "Error: Failed to copy to $INSTALL_DIR."
        return 1
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  Tyrian 2000 installed."
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Tyrian 2000 is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open '$APP_PATH'"
    echo ""
    echo "Or find 'opentyrian2000' in $INSTALL_DIR"
    echo ""
    echo "High scores and saved games live in:"
    echo "  ~/.config/opentyrian2000"
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
    finish
}

main "$@"
