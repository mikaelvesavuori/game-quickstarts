#!/bin/bash
set -euo pipefail

PATCH_VERSION="227k_15"
PATCH_DMG_URL="https://github.com/OldUnreal/Unreal-testing/releases/download/v${PATCH_VERSION}/OldUnreal-UnrealPatch227k-macOS.dmg"
PATCH_DMG_FILE="OldUnreal-UnrealPatch227k-macOS.dmg"
APP_NAME="Unreal.app"

ISO_FILE="UNREAL_GOLD.iso"
ISO_SHA256="7e360d0cc9e5533f38859819fd3cbfea7c475ecd428f9f433b5f8e1d5742cbca"
ISO_URLS=(
    "https://files.oldunreal.net/UNREAL_GOLD.ISO"
    "https://files2.oldunreal.net/UNREAL_GOLD.ISO"
    "https://files3.oldunreal.net/UNREAL_GOLD.ISO"
    "https://archive.org/download/totallyunreal/UNREAL_GOLD.ISO"
)

ASSETS_DIR="$HOME/Library/Application Support/Unreal"
APP_PATH="/Applications/$APP_NAME"

TEMP_DIR=""
ISO_MOUNT=""
DMG_MOUNT=""
AUTO_YES=false

cleanup() {
    local exit_code=$?
    if [[ -n "${ISO_MOUNT:-}" ]]; then
        hdiutil detach "$ISO_MOUNT" -force -quiet 2>/dev/null || true
    fi
    if [[ -n "${DMG_MOUNT:-}" ]]; then
        hdiutil detach "$DMG_MOUNT" -force -quiet 2>/dev/null || true
    fi
    if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "${TEMP_DIR:-}" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    exit $exit_code
}
trap cleanup EXIT

download_with_fallback() {
    local output="$1"
    shift
    local urls=("$@")
    for url in "${urls[@]}"; do
        echo "  Trying: $url"
        if curl -f -L --progress-bar --connect-timeout 30 -o "$output" "$url"; then
            return 0
        fi
        echo "  Failed, trying next mirror..."
    done
    echo "Error: All download mirrors failed."
    return 1
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
    echo "=== Unreal Gold (1998) Quickstart Installer ==="
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
    local required_kb=2097152
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 2GB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Install the OldUnreal Unreal patch (v227k) to /Applications"
    echo "  2. Download the Unreal Gold CD game data (~645MB)"
    echo "  3. Copy maps, sounds, textures, and music to the game data folder"
    echo ""
    echo "Game data location: $ASSETS_DIR"
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_patch() {
    echo ""
    echo "=== Step 1: Installing OldUnreal Unreal Patch v227k ==="

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

    echo "  Downloading patch..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$PATCH_DMG_FILE" "$PATCH_DMG_URL"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$PATCH_DMG_FILE" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    if [[ ! -d "$DMG_MOUNT/$APP_NAME" ]]; then
        echo "Error: $APP_NAME not found in DMG."
        hdiutil detach "$DMG_MOUNT" -quiet 2>/dev/null || true
        DMG_MOUNT=""
        return 1
    fi

    echo "  Copying $APP_NAME to /Applications..."
    if ! cp -R "$DMG_MOUNT/$APP_NAME" /Applications/; then
        echo "Error: Failed to copy to /Applications."
        return 1
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  Patch installed."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Downloading Unreal Gold CD ==="

    echo "  Downloading ISO (~645MB)..."
    download_with_fallback "$TEMP_DIR/$ISO_FILE" "${ISO_URLS[@]}"
    verify_sha256 "$TEMP_DIR/$ISO_FILE" "$ISO_SHA256"

    ISO_MOUNT="$TEMP_DIR/iso_mount"
    mkdir -p "$ISO_MOUNT"
    echo "  Mounting ISO..."
    hdiutil attach "$TEMP_DIR/$ISO_FILE" -mountpoint "$ISO_MOUNT" -nobrowse -readonly -quiet

    local maps_found=false
    for dir in "$ISO_MOUNT"/*/; do
        if [[ -d "${dir}Maps" ]] || [[ -d "${dir}MAPS" ]]; then
            maps_found=true
            break
        fi
    done
    if ! $maps_found && [[ ! -d "$ISO_MOUNT/Maps" ]] && [[ ! -d "$ISO_MOUNT/MAPS" ]]; then
        echo "Error: Maps directory not found in ISO."
        return 1
    fi

    echo ""
    echo "=== Step 3: Copying game data ==="

    mkdir -p "$ASSETS_DIR"

    local iso_root="$ISO_MOUNT"
    for dir in "$ISO_MOUNT"/*/; do
        if [[ -d "${dir}Maps" ]] || [[ -d "${dir}MAPS" ]]; then
            iso_root="${dir%/}"
            break
        fi
    done

    for dir in Maps Sounds Textures Music; do
        local src=""
        for variant in "$dir" "$(echo "$dir" | tr '[:lower:]' '[:upper:]')"; do
            if [[ -d "$iso_root/$variant" ]]; then
                src="$iso_root/$variant"
                break
            fi
        done
        if [[ -n "$src" ]]; then
            echo "  Copying $dir..."
            cp -R "$src" "$ASSETS_DIR/$dir"
            chmod -R u+w "$ASSETS_DIR/$dir" 2>/dev/null || true
        fi
    done

    echo "  Removing obsolete font texture (patch ships replacement)..."
    rm -f "$ASSETS_DIR/Textures/UWindowFonts.utx" 2>/dev/null || true

    echo "  Game data copied."
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Unreal Gold is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open $APP_PATH"
    echo ""
    echo "Or find $APP_NAME in your Applications folder / Launchpad."
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

    install_patch
    install_game_data
    finish
}

main "$@"
