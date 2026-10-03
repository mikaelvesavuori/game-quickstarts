#!/bin/bash
set -euo pipefail

OPENRA_VERSION="release-20250330"
ENGINE_URL="https://github.com/OpenRA/OpenRA/releases/download/${OPENRA_VERSION}/OpenRA-${OPENRA_VERSION}.dmg"
ENGINE_FILE="OpenRA-${OPENRA_VERSION}.dmg"
ENGINE_SHA256="2a78cd58603fd06ed6006ae5916065455a7ac7c1290dba1d06c0292bad4238ab"

CNC_PACKAGES_URL="https://openra.ppmsite.com/cnc-packages.zip"
RA_QUICKINSTALL_URL="https://openra.ppmsite.com/ra-quickinstall.zip"
D2K_QUICKINSTALL_URL="https://openra.ppmsite.com/d2k-quickinstall-v3.zip"

CONTENT_DIR="$HOME/Library/Application Support/OpenRA/Content"

DMG_MOUNT=""
TEMP_DIR=""
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
    echo "=== OpenRA Quickstart Installer (C&C, Red Alert, Dune 2000) ==="
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
    local required_kb=524288
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 512MB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Install OpenRA (Universal 2, Apple Silicon + Intel) to /Applications"
    echo "  2. Download game data for all three games:"
    echo "     - Command & Conquer (Tiberian Dawn)"
    echo "     - Red Alert"
    echo "     - Dune 2000"
    echo "  3. Pre-install game data so games are ready immediately"
    echo ""
    echo "Three separate apps will be installed:"
    echo "  - OpenRA - Tiberian Dawn.app  (Command & Conquer)"
    echo "  - OpenRA - Red Alert.app"
    echo "  - OpenRA - Dune 2000.app"
    echo ""
    echo "Note: Game data includes core files (no FMV videos or music soundtrack)."
    echo "      For full content, use 'Manage Content' in-game with original CDs."
    echo "      C&C and Red Alert were released as freeware by EA."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing OpenRA ==="

    local apps_to_install=(
        "OpenRA - Tiberian Dawn.app"
        "OpenRA - Red Alert.app"
        "OpenRA - Dune 2000.app"
    )

    local existing=false
    for app in "${apps_to_install[@]}"; do
        if [[ -d "/Applications/$app" ]]; then
            existing=true
            break
        fi
    done

    if [[ "$existing" == true ]]; then
        echo "  OpenRA apps already exist in /Applications."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing installation? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing installation."
                return 0
            fi
        fi
        for app in "${apps_to_install[@]}"; do
            rm -rf "/Applications/$app"
        done
    fi

    echo "  Downloading OpenRA DMG (~152MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_URL"
    verify_sha256 "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_SHA256"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$ENGINE_FILE" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    local dmg_root="$DMG_MOUNT"
    for dir in "$DMG_MOUNT"/*/; do
        if [[ -d "${dir}OpenRA - Tiberian Dawn.app" ]] || [[ -d "${dir}OpenRA - Red Alert.app" ]]; then
            dmg_root="${dir%/}"
            break
        fi
    done

    for app in "${apps_to_install[@]}"; do
        if [[ -d "$dmg_root/$app" ]]; then
            echo "  Copying $app..."
            cp -R "$dmg_root/$app" /Applications/
            xattr -dr com.apple.quarantine "/Applications/$app" 2>/dev/null || true
        else
            echo "  Warning: $app not found in DMG."
        fi
    done

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  OpenRA installed."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Downloading game data ==="

    mkdir -p "$CONTENT_DIR"

    echo ""
    echo "  --- Command & Conquer (Tiberian Dawn) ---"
    mkdir -p "$CONTENT_DIR/cnc"
    echo "  Downloading C&C game data (~7.5MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/cnc-packages.zip" "$CNC_PACKAGES_URL"
    unzip -q -o "$TEMP_DIR/cnc-packages.zip" -d "$CONTENT_DIR/cnc/"
    echo "  C&C game data installed."

    echo ""
    echo "  --- Red Alert ---"
    mkdir -p "$CONTENT_DIR/ra/v2"
    echo "  Downloading Red Alert game data (~13MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/ra-quickinstall.zip" "$RA_QUICKINSTALL_URL"
    unzip -q -o "$TEMP_DIR/ra-quickinstall.zip" -d "$CONTENT_DIR/ra/v2/"
    echo "  Red Alert game data installed."

    echo ""
    echo "  --- Dune 2000 ---"
    mkdir -p "$CONTENT_DIR/d2k"
    echo "  Downloading Dune 2000 game data (~13MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/d2k-quickinstall.zip" "$D2K_QUICKINSTALL_URL"
    unzip -q -o "$TEMP_DIR/d2k-quickinstall.zip" -d "$CONTENT_DIR/d2k/"
    echo "  Dune 2000 game data installed."

    echo ""
    echo "  All game data installed."
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "OpenRA is ready to play! Three games installed:"
    echo ""
    echo "  Command & Conquer:"
    echo "    open '/Applications/OpenRA - Tiberian Dawn.app'"
    echo ""
    echo "  Red Alert:"
    echo "    open '/Applications/OpenRA - Red Alert.app'"
    echo ""
    echo "  Dune 2000:"
    echo "    open '/Applications/OpenRA - Dune 2000.app'"
    echo ""
    echo "Or find them in your Applications folder."
    echo ""
    echo "Game data location: $CONTENT_DIR"
    echo ""
    echo "Note: Core game data only (no FMV videos or music soundtrack)."
    echo "For full content, use 'Manage Content' > 'Detect Disc or Installation'"
    echo "in the in-game menu with the original game CDs."
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
