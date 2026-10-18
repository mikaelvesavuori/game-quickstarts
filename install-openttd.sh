#!/bin/bash
set -euo pipefail

# OpenTTD 15.3, the open source continuation of Transport Tycoon Deluxe
# (1995). Official macOS build: Universal 2 (Apple Silicon + Intel).
OPENTTD_VERSION="15.3"
OPENTTD_URL="https://cdn.openttd.org/openttd-releases/15.3/openttd-15.3-macos-universal.dmg"
OPENTTD_DMG="openttd-15.3-macos-universal.dmg"
OPENTTD_SHA256="7ca8c0dddd7dc4f26d66a5170af4bf094ed36440cf5641db564356c807308614"

# Freely licensed replacements for the original Transport Tycoon Deluxe
# graphics, sound effects and music. With these installed, the game is
# fully playable without any owned TTD files — and the in-game
# "download graphics on first run" prompt is skipped entirely.
OPENGFX_URL="https://cdn.openttd.org/opengfx-releases/8.0/opengfx-8.0-all.zip"
OPENGFX_FILE="opengfx-8.0-all.zip"
OPENGFX_SHA256="43a0c1dabf39cb865394f3a6cc36d4da5c10ecfaaf55652043104806810903be"
OPENSFX_URL="https://cdn.openttd.org/opensfx-releases/1.0.3/opensfx-1.0.3-all.zip"
OPENSFX_FILE="opensfx-1.0.3-all.zip"
OPENSFX_SHA256="e0a218b7dd9438e701503b0f84c25a97c1c11b7c2f025323fb19d6db16ef3759"
OPENMSX_URL="https://cdn.openttd.org/openmsx-releases/0.4.2/openmsx-0.4.2-all.zip"
OPENMSX_FILE="openmsx-0.4.2-all.zip"
OPENMSX_SHA256="5a4277a2e62d87f2952ea5020dc20fb2f6ffafdccf9913fbf35ad45ee30ec762"

INSTALL_DIR="/Applications/OpenTTD"
APP_PATH="$INSTALL_DIR/OpenTTD.app"

# OpenTTD's personal directory on macOS: base sets, saved games, config.
# Note: OpenTTD 15 renamed the base set scan directory to "baseset".
PERSONAL_DIR="$HOME/Documents/OpenTTD"
BASESETS_DIR="$PERSONAL_DIR/baseset"

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
    echo "=== OpenTTD (Transport Tycoon Deluxe, 1995) Quickstart Installer ==="
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

    for cmd in curl hdiutil unzip tar shasum; do
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
    echo "  1. Download the official OpenTTD ${OPENTTD_VERSION} macOS release"
    echo "     (Universal 2: Apple Silicon + Intel, ~14MB)"
    echo "  2. Verify the download with SHA256"
    echo "  3. Install it to $INSTALL_DIR"
    echo "  4. Download the free base sets (~15MB total, SHA256-verified)"
    echo "     and pre-install them, so the game is playable immediately:"
    echo "       - OpenGFX   (graphics)"
    echo "       - OpenSFX   (sound effects)"
    echo "       - OpenMSX   (music)"
    echo ""
    echo "OpenTTD is fully free — it ships with freely licensed graphics,"
    echo "sound and music (OpenGFX/OpenSFX/OpenMSX), so no copy of the"
    echo "original Transport Tycoon Deluxe is needed to play."
    echo ""
    echo "If you do own TTD, its data can be used instead — see:"
    echo "  https://wiki.openttd.org/en/Manual/Installation"
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing OpenTTD ${OPENTTD_VERSION} ==="

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

    echo "  Downloading OpenTTD DMG (~14MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$OPENTTD_DMG" "$OPENTTD_URL"
    verify_sha256 "$TEMP_DIR/$OPENTTD_DMG" "$OPENTTD_SHA256"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$OPENTTD_DMG" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    if [[ ! -d "$DMG_MOUNT/OpenTTD.app" ]]; then
        echo "Error: OpenTTD.app not found in DMG."
        return 1
    fi

    echo "  Copying OpenTTD.app to /Applications..."
    if ! cp -R "$DMG_MOUNT/OpenTTD.app" "$INSTALL_DIR/"; then
        echo "Error: Failed to copy to $INSTALL_DIR."
        return 1
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  OpenTTD installed."
}

# Each ZIP contains a single uncompressed TAR, which in turn contains a
# versioned directory with the base set files. Extract the TAR straight
# into the base set directory.
install_base_set() {
    local name="$1"
    local url="$2"
    local file="$3"
    local sha256="$4"
    local descriptor="$5"

    echo "  Downloading ${name}..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$file" "$url"
    verify_sha256 "$TEMP_DIR/$file" "$sha256"

    echo "  Extracting ${name}..."
    unzip -q -o "$TEMP_DIR/$file" -d "$TEMP_DIR/${name}_zip"
    local tar_file
    tar_file=$(find "$TEMP_DIR/${name}_zip" -maxdepth 1 -name "*.tar" -print -quit)
    if [[ -z "$tar_file" ]]; then
        echo "Error: TAR archive not found inside ${name} ZIP."
        return 1
    fi
    tar -xf "$tar_file" -C "$BASESETS_DIR"

    if ! find "$BASESETS_DIR" -name "$descriptor" -print -quit | grep -q .; then
        echo "Error: ${descriptor} not found after extracting ${name}."
        return 1
    fi

    echo "  ${name} installed."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Installing free base sets (OpenGFX, OpenSFX, OpenMSX) ==="

    if [[ -d "$BASESETS_DIR" ]] && find "$BASESETS_DIR" -name "*.obg" -print -quit | grep -q .; then
        echo "  Existing base sets found in $BASESETS_DIR."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing base sets? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing base sets."
                return 0
            fi
        fi
    fi

    mkdir -p "$BASESETS_DIR"

    install_base_set "OpenGFX" "$OPENGFX_URL" "$OPENGFX_FILE" "$OPENGFX_SHA256" "opengfx.obg"
    install_base_set "OpenSFX" "$OPENSFX_URL" "$OPENSFX_FILE" "$OPENSFX_SHA256" "opensfx.obs"
    install_base_set "OpenMSX" "$OPENMSX_URL" "$OPENMSX_FILE" "$OPENMSX_SHA256" "openmsx.obm"

    echo "  Base sets installed."
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "OpenTTD is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open '$APP_PATH'"
    echo ""
    echo "Or find 'OpenTTD' in $INSTALL_DIR"
    echo ""
    echo "Graphics, sound and music are pre-installed in:"
    echo "  ~/Documents/OpenTTD/baseset"
    echo "Saved games and settings live in:"
    echo "  ~/Documents/OpenTTD"
    echo ""
    echo "Playing with friends:"
    echo "  OpenTTD has built-in multiplayer — open the Multiplayer menu"
    echo "  to join any game straight from the server list (works over LAN"
    echo "  and the internet), or host your own via 'Start Server'."
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
