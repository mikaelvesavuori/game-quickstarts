#!/bin/bash
set -euo pipefail

PATCH_VERSION="469e"
PATCH_DMG_URL="https://github.com/OldUnreal/UnrealTournamentPatches/releases/download/v${PATCH_VERSION}/OldUnreal-UTPatch${PATCH_VERSION}-macOS.dmg"
PATCH_DMG_FILE="OldUnreal-UTPatch${PATCH_VERSION}-macOS.dmg"

ISO_FILE="UT_GOTY_CD1.iso"
ISO_SHA256="e184984ca88f001c5ddd52035d76cd64e266e26c74975161b5ed72366c74704f"
ISO_URLS=(
    "https://files.oldunreal.net/UT_GOTY_CD1.ISO"
    "https://files2.oldunreal.net/UT_GOTY_CD1.ISO"
    "https://files3.oldunreal.net/UT_GOTY_CD1.ISO"
    "https://archive.org/download/ut-goty/UT_GOTY_CD1.iso"
)

BONUS_PACK_FILE="utbonuspack4-zip.7z"
BONUS_PACK_SHA256="5b7a1080724a122a596c226c50d4dc7c2d7636ceaf067e9c12112014a170ffba"
BONUS_PACK_URLS=(
    "https://files.oldunreal.net/utbonuspack4-zip.7z"
    "https://files2.oldunreal.net/utbonuspack4-zip.7z"
    "https://files3.oldunreal.net/utbonuspack4-zip.7z"
)

ASSETS_DIR="$HOME/Library/Application Support/Unreal Tournament"
APP_PATH="/Applications/UnrealTournament.app"
UCC_BIN="$APP_PATH/Contents/MacOS/UCC"

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
    echo "=== UT99 Quickstart Installer ==="
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
    echo "  1. Install the OldUnreal UT patch (v${PATCH_VERSION}) to /Applications"
    echo "  2. Download the UT GOTY CD1 game data (~620MB)"
    echo "  3. Copy maps, textures, sounds, and music to the game data folder"
    echo "  4. Decompress maps for in-game use"
    echo "  5. Install Bonus Pack 4 (extra maps, ~11MB)"
    echo ""
    echo "Game data location: $ASSETS_DIR"
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_patch() {
    echo ""
    echo "=== Step 1: Installing OldUnreal UT Patch v${PATCH_VERSION} ==="

    if [[ -d "$APP_PATH" ]]; then
        echo "  UnrealTournament.app already exists."
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

    if [[ ! -d "$DMG_MOUNT/UnrealTournament.app" ]]; then
        echo "Error: UnrealTournament.app not found in DMG."
        hdiutil detach "$DMG_MOUNT" -quiet 2>/dev/null || true
        DMG_MOUNT=""
        return 1
    fi

    echo "  Copying UnrealTournament.app to /Applications..."
    if ! cp -R "$DMG_MOUNT/UnrealTournament.app" /Applications/; then
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
    echo "=== Step 2: Downloading UT GOTY CD1 ==="

    echo "  Downloading ISO (~620MB)..."
    download_with_fallback "$TEMP_DIR/$ISO_FILE" "${ISO_URLS[@]}"
    verify_sha256 "$TEMP_DIR/$ISO_FILE" "$ISO_SHA256"

    ISO_MOUNT="$TEMP_DIR/iso_mount"
    mkdir -p "$ISO_MOUNT"
    echo "  Mounting ISO..."
    hdiutil attach "$TEMP_DIR/$ISO_FILE" -mountpoint "$ISO_MOUNT" -nobrowse -readonly -quiet

    if [[ ! -d "$ISO_MOUNT/Maps" ]]; then
        echo "Error: Maps directory not found in ISO."
        return 1
    fi

    echo ""
    echo "=== Step 3: Copying game data ==="

    mkdir -p "$ASSETS_DIR"

    for dir in Maps Textures Sounds Music; do
        if [[ -d "$ISO_MOUNT/$dir" ]]; then
            echo "  Copying $dir..."
            cp -R "$ISO_MOUNT/$dir" "$ASSETS_DIR"
            chmod -R u+w "$ASSETS_DIR/$dir" 2>/dev/null || true
        fi
    done

    echo "  Removing font textures (patch ships replacements)..."
    rm -f "$ASSETS_DIR/Textures/LadderFonts.utx" 2>/dev/null || true
    rm -f "$ASSETS_DIR/Textures/UWindowFonts.utx" 2>/dev/null || true

    echo "  Game data copied."
}

decompress_maps() {
    echo ""
    echo "=== Step 4: Decompressing maps ==="

    local uz_count=0
    for uz_file in "$ASSETS_DIR/Maps/"*.uz; do
        [[ -f "$uz_file" ]] || continue
        uz_count=$((uz_count + 1))
    done

    if [[ $uz_count -eq 0 ]]; then
        echo "  No compressed maps found. Skipping."
        return 0
    fi

    echo "  Found $uz_count compressed maps."

    mkdir -p "$ASSETS_DIR/System"

    local current=0
    local failed=0

    for uz_file in "$ASSETS_DIR/Maps/"*.uz; do
        [[ -f "$uz_file" ]] || continue
        current=$((current + 1))
        local filename
        filename=$(basename "$uz_file")
        echo "  [$current/$uz_count] $filename"
        if ! "$UCC_BIN" decompress "$uz_file" >/dev/null 2>&1; then
            echo "    Warning: Failed to decompress $filename"
            failed=$((failed + 1))
        fi
    done

    echo "  Moving decompressed maps to Maps directory..."
    mv "$ASSETS_DIR/System/"*.unr "$ASSETS_DIR/Maps/" 2>/dev/null || true

    echo "  Removing compressed map files..."
    rm -f "$ASSETS_DIR/Maps/"*.uz 2>/dev/null || true

    if [[ -z "$(ls -A "$ASSETS_DIR/System" 2>/dev/null)" ]]; then
        rmdir "$ASSETS_DIR/System" 2>/dev/null || true
    fi

    if [[ $failed -gt 0 ]]; then
        echo "  Warning: $failed map(s) failed to decompress."
    fi
    echo "  Decompression complete."
}

install_bonus_pack() {
    echo ""
    echo "=== Step 5: Installing Bonus Pack 4 ==="

    local seven_bin=""
    if command -v 7z &>/dev/null; then
        seven_bin="7z"
    elif command -v 7zz &>/dev/null; then
        seven_bin="7zz"
    fi

    if [[ -z "$seven_bin" ]]; then
        echo "  7zip is required for Bonus Pack 4."
        if command -v brew &>/dev/null; then
            if [[ "$AUTO_YES" == false ]]; then
                read -r -p "  Install 7zip via Homebrew? (y/N) " response </dev/tty
                if [[ "${response:-N}" == [Yy]* ]]; then
                    brew install 7zip
                    if command -v 7zz &>/dev/null; then
                        seven_bin="7zz"
                    elif command -v 7z &>/dev/null; then
                        seven_bin="7z"
                    fi
                fi
            fi
        fi
        if [[ -z "$seven_bin" ]]; then
            echo "Error: 7zip is required for Bonus Pack 4. Install with: brew install 7zip"
            return 1
        fi
    fi

    echo "  Downloading Bonus Pack 4 (~11MB)..."
    download_with_fallback "$TEMP_DIR/$BONUS_PACK_FILE" "${BONUS_PACK_URLS[@]}"
    verify_sha256 "$TEMP_DIR/$BONUS_PACK_FILE" "$BONUS_PACK_SHA256"

    echo "  Extracting..."
    "$seven_bin" x "$TEMP_DIR/$BONUS_PACK_FILE" -o"$TEMP_DIR/bonuspack" -y >/dev/null 2>&1

    echo "  Copying files..."
    if [[ -d "$TEMP_DIR/bonuspack" ]]; then
        cp -R "$TEMP_DIR/bonuspack/"* "$ASSETS_DIR/" 2>/dev/null || true
        chmod -R u+w "$ASSETS_DIR/" 2>/dev/null || true
    fi

    echo "  Decompressing bonus pack maps..."
    local has_uz=false
    for uz_file in "$ASSETS_DIR/Maps/"*.uz; do
        [[ -f "$uz_file" ]] || continue
        has_uz=true
        "$UCC_BIN" decompress "$uz_file" >/dev/null 2>&1 || true
    done

    if [[ "$has_uz" == true ]]; then
        mkdir -p "$ASSETS_DIR/System"
        mv "$ASSETS_DIR/System/"*.unr "$ASSETS_DIR/Maps/" 2>/dev/null || true
        rm -f "$ASSETS_DIR/Maps/"*.uz 2>/dev/null || true
        if [[ -z "$(ls -A "$ASSETS_DIR/System" 2>/dev/null)" ]]; then
            rmdir "$ASSETS_DIR/System" 2>/dev/null || true
        fi
    fi

    echo "  Bonus Pack 4 installed."
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Unreal Tournament is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open /Applications/UnrealTournament.app"
    echo ""
    echo "Or find it in your Applications folder / Launchpad."
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
    decompress_maps
    install_bonus_pack
    finish
}

main "$@"
