#!/bin/bash
set -euo pipefail

# SimCity 2000 (1993/1994) — played through OpenSC2K, an open-source
# remake built with Rust and Godot (MIT license). The engine is under
# very active development and ships official, signed and notarized
# Universal 2 macOS builds; this script installs the current release.
#
# OpenSC2K does not include the original game assets. The engine's
# Import Assets function reads them from the original game files —
# including the official DOS demo, which is what this script installs
# so the game is playable immediately for free. Own the full game
# (SimCity 2000 Special Edition for Windows 95, sold on GOG) for the
# complete asset set: the demo has no newspaper data and no SCURK
# artwork, but the city-building game itself is fully playable.
#
# Maxis/EA retains copyright on SimCity 2000 and its assets. The demo
# was released for free by Maxis; the full game remains for sale on GOG.
OPENS2K_VERSION="0.3.0"
OPENS2K_URL="https://github.com/OpenSC2K/OpenSC2K/releases/download/v${OPENS2K_VERSION}/OpenSC2K-${OPENS2K_VERSION}-macos-universal.dmg"
OPENS2K_DMG="OpenSC2K-${OPENS2K_VERSION}-macos-universal.dmg"
OPENS2K_SHA256="7947bff3d3231b003f673b3a81a75440b0082c6676cc85f8a772f87b3d98b9d3"

# Official SimCity 2000 DOS demo (MAXIS, 1993), hosted on archive.org.
DEMO_URL="https://archive.org/download/Simcity2000Demo/simc2000.zip"
DEMO_ZIP="simc2000.zip"
DEMO_SHA256="7b943026765d928caf9eaac03608047c4ab36d5a08f5aaa8b3d8c048c1393c0c"

INSTALL_DIR="/Applications/SimCity2000"
APP_PATH="$INSTALL_DIR/OpenSC2K.app"
DEMO_DIR="$INSTALL_DIR/SimCity2000Demo"

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
    echo "=== SimCity 2000 (1993) Quickstart Installer ==="
    echo ""

    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Error: This script is for macOS only."
        exit 1
    fi

    local arch
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        echo "System: macOS on Apple Silicon (arm64)"
        echo "Requires macOS 13 or later."
    else
        echo "System: macOS on Intel ($arch)"
        echo "Requires macOS 11 or later."
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
    local required_kb=512000
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 500MB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Download OpenSC2K ${OPENS2K_VERSION} (~100MB)"
    echo "     (open-source SimCity 2000 engine, official build,"
    echo "     Universal 2: Apple Silicon + Intel, signed and notarized)"
    echo "  2. Verify the download with SHA256"
    echo "  3. Install it to $INSTALL_DIR"
    echo "  4. Download the official SimCity 2000 DOS demo (~1MB,"
    echo "     archive.org, Maxis) and extract it next to the app"
    echo "  5. Print the one-time 'Import Assets' steps to load the"
    echo "     demo's graphics, text and sounds into the game"
    echo ""
    echo "The demo is fully playable: build cities, zone, budget, raise"
    echo "leases and taxes, and run disasters. Two demo limitations: no"
    echo "in-game newspaper, and no SCURK (Urban Renewal Kit) artwork."
    echo ""
    echo "To upgrade to the complete asset set, buy SimCity 2000 Special"
    echo "Edition on GOG (\$2.99) and use Import Assets on its files —"
    echo "the script prints the exact steps at the end."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing OpenSC2K ${OPENS2K_VERSION} ==="

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

    echo "  Downloading OpenSC2K DMG (~100MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$OPENS2K_DMG" "$OPENS2K_URL"
    verify_sha256 "$TEMP_DIR/$OPENS2K_DMG" "$OPENS2K_SHA256"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$OPENS2K_DMG" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    if [[ ! -d "$DMG_MOUNT/OpenSC2K.app" ]]; then
        echo "Error: OpenSC2K.app not found in DMG."
        return 1
    fi

    echo "  Copying OpenSC2K.app to /Applications..."
    if ! cp -R "$DMG_MOUNT/OpenSC2K.app" "$INSTALL_DIR/"; then
        echo "Error: Failed to copy to $INSTALL_DIR."
        return 1
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  OpenSC2K installed."
}

install_demo_data() {
    echo ""
    echo "=== Step 2: Installing the SimCity 2000 DOS demo ==="

    if [[ -d "$DEMO_DIR" ]]; then
        echo "  $DEMO_DIR already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing demo files? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing demo files."
                return 0
            fi
        fi
        rm -rf "$DEMO_DIR"
    fi

    mkdir -p "$DEMO_DIR"

    echo "  Downloading DOS demo (~1MB, archive.org)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$DEMO_ZIP" "$DEMO_URL"
    verify_sha256 "$TEMP_DIR/$DEMO_ZIP" "$DEMO_SHA256"

    echo "  Extracting demo..."
    unzip -q -o "$TEMP_DIR/$DEMO_ZIP" -d "$DEMO_DIR"

    if [[ ! -f "$DEMO_DIR/SC2000.DAT" ]] || [[ ! -f "$DEMO_DIR/SC2000.EXE" ]]; then
        echo "Error: Demo files incomplete — SC2000.EXE/SC2000.DAT not found."
        return 1
    fi

    echo "  Demo installed."
}

finish() {
    echo ""
    echo "=== Installation Complete — one first-run step ==="
    echo ""
    echo "On first launch, the game needs to import the demo's assets"
    echo "(graphics, text, sound). This is a one-time, in-game action:"
    echo ""
    echo "  1. Launch the game:"
    echo "       open '$APP_PATH'"
    echo ""
    echo "  2. On the main menu, click 'Import Assets'"
    echo "  3. Select the folder:"
    echo "       $DEMO_DIR"
    echo "     (the importer scans the files itself — SC2000.EXE,"
    echo "      SC2000.DAT and the demo city will be found there)"
    echo "  4. Start a new city and play"
    echo ""
    echo "Demo limits (compared to the full game): no in-game newspaper,"
    echo "no SCURK artwork. Everything else works — zoning, budgeting,"
    echo "ordinances, disasters, saving."
    echo ""
    echo "Upgrade path: buy SimCity 2000 Special Edition (Windows 95)"
    echo "on GOG, unpack the installer (e.g. 'brew install innoextract',"
    echo "then 'innoextract setup_simcity_2000_special_edition.exe'),"
    echo "and use Import Assets on the unpacked game folder."
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
    install_demo_data
    finish
}

main "$@"
