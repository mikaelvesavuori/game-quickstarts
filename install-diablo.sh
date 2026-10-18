#!/bin/bash
set -euo pipefail

DEVILUTIONX_VERSION="1.5.5"
ENGINE_URL="https://github.com/diasurgical/DevilutionX/releases/download/${DEVILUTIONX_VERSION}/devilutionx-macOS-universal.dmg"
ENGINE_FILE="devilutionx-macOS-universal.dmg"
ENGINE_SHA256="10ecd55caf4239d087bc91bce7538943705399b0b2abcff71c347ddbf01d30c6"
APP_NAME="devilutionX.app"

SPAWN_URL="https://github.com/diasurgical/devilutionx-assets/releases/download/v5/spawn.mpq"
SPAWN_FILE="spawn.mpq"
SPAWN_SHA256="64427cd7c1ba904eaa2e0031c16a6b136d0ecef9abc888c5ff8344b459356e38"

DEVILUTIONX_MPQ_URL="https://github.com/diasurgical/devilutionx-assets/releases/download/v5/devilutionx.mpq"
DEVILUTIONX_MPQ_FILE="devilutionx.mpq"
DEVILUTIONX_MPQ_SHA256="190701ca282fef8fa8b3f165322760813d6b199462bb4e2587a20068c08accd3"

# Full game data for owners (confirm ownership in the prompt)
FULL_GAME_URL="http://cdn.pvpgn.pro/diablo1/DIABDAT.MPQ"
FULL_GAME_FILE="DIABDAT.MPQ"
FULL_GAME_SHA256="6bc120a603fdb383ff91f374e7db599765d6230d81e5a4c1b33f8254911774e7"

INSTALL_DIR="/Applications/Diablo"
APP_PATH="$INSTALL_DIR/$APP_NAME"
DATA_DIR="$HOME/Library/Application Support/diasurgical/devilution"

TEMP_DIR=""
DMG_MOUNT=""
AUTO_YES=false
USE_FULL_GAME=false

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
    echo "=== Diablo (1996) Quickstart Installer ==="
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
    local required_kb=524288
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 512MB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

check_full_game_space() {
    local free_kb
    free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local required_kb=1048576
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space for the full game. Need at least 1GB free."
        echo "  Available: $((free_kb / 1024))MB"
        return 1
    fi
}

prompt_game_version() {
    echo ""
    echo "Do you own a legitimate copy of Diablo (e.g. from GOG or the original CD)?"
    read -r -p "  (y/N) " own_response </dev/tty
    if [[ "${own_response:-N}" == [Yy]* ]]; then
        USE_FULL_GAME=true
        echo ""
        echo "  The full game data (DIABDAT.MPQ, ~494MB) will be downloaded"
        echo "  from cdn.pvpgn.pro and SHA256-verified."
    else
        echo ""
        echo "  The shareware version (spawn.mpq, ~25MB) will be installed -"
        echo "  freely distributable data from the DevilutionX project itself."
        echo "  Includes the Cathedral levels; multiplayer works between"
        echo "  shareware players. Upgrade later by re-running this installer."
    fi
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing DevilutionX v${DEVILUTIONX_VERSION} ==="

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

    echo "  Downloading DevilutionX DMG (~27MB)..."
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

    local copied_name
    copied_name=$(basename "$app_src")
    if [[ "$copied_name" != "$APP_NAME" && -d "$INSTALL_DIR/$copied_name" ]]; then
        echo "  Normalizing app name to $APP_NAME..."
        rm -rf "$APP_PATH"
        mv "$INSTALL_DIR/$copied_name" "$APP_PATH"
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  Engine installed."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Downloading Diablo game data ==="

    echo "  Downloading devilutionx.mpq (engine assets, ~5.5MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$DEVILUTIONX_MPQ_FILE" "$DEVILUTIONX_MPQ_URL"
    verify_sha256 "$TEMP_DIR/$DEVILUTIONX_MPQ_FILE" "$DEVILUTIONX_MPQ_SHA256"

    mkdir -p "$DATA_DIR"
    cp "$TEMP_DIR/$DEVILUTIONX_MPQ_FILE" "$DATA_DIR/"

    if [[ "$USE_FULL_GAME" == true ]]; then
        check_full_game_space

        if [[ -f "$DATA_DIR/$FULL_GAME_FILE" ]]; then
            echo "  $FULL_GAME_FILE already exists in $DATA_DIR."
            if [[ "$AUTO_YES" == false ]]; then
                read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
                if [[ "${response:-N}" != [Yy]* ]]; then
                    echo "  Keeping existing game data."
                    echo "  Full game data present - installation complete."
                    return 0
                fi
            fi
            rm -f "$DATA_DIR/$FULL_GAME_FILE"
        fi

        echo "  Downloading $FULL_GAME_FILE (full game, ~494MB) from cdn.pvpgn.pro..."
        curl -f -L --progress-bar -o "$TEMP_DIR/$FULL_GAME_FILE" "$FULL_GAME_URL"
        verify_sha256 "$TEMP_DIR/$FULL_GAME_FILE" "$FULL_GAME_SHA256"

        echo "  Installing game data to $DATA_DIR..."
        mv "$TEMP_DIR/$FULL_GAME_FILE" "$DATA_DIR/$FULL_GAME_FILE"

        echo "  Full game data installed."
    else
        if [[ -f "$DATA_DIR/$SPAWN_FILE" ]]; then
            echo "  $SPAWN_FILE already exists in $DATA_DIR."
            if [[ "$AUTO_YES" == false ]]; then
                read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
                if [[ "${response:-N}" != [Yy]* ]]; then
                    echo "  Keeping existing game data."
                    echo "  Shareware data present - installation complete."
                    return 0
                fi
            fi
            rm -f "$DATA_DIR/$SPAWN_FILE"
        fi

        echo "  Downloading spawn.mpq (shareware game data, ~25MB)..."
        curl -f -L --progress-bar -o "$TEMP_DIR/$SPAWN_FILE" "$SPAWN_URL"
        verify_sha256 "$TEMP_DIR/$SPAWN_FILE" "$SPAWN_SHA256"

        cp "$TEMP_DIR/$SPAWN_FILE" "$DATA_DIR/"

        echo "  Shareware data installed."
    fi
}

print_upgrade_instructions() {
    if [[ "$USE_FULL_GAME" == true ]]; then
        echo ""
        echo "=== Hellfire (Optional Expansion) ==="
        echo ""
        echo "  If you also own the Hellfire expansion, copy HELLFIRE.MPQ,"
        echo "  HFMUSIC.MPQ and HFVOICE.MPQ from your copy into:"
        echo "    $DATA_DIR"
        echo ""
        return 0
    fi

    echo ""
    echo "=== Upgrading to the Full Game ==="
    echo ""
    echo "The shareware version includes the Cathedral (first 2 dungeon levels)."
    echo ""
    echo "To get the full game:"
    echo ""
    echo "  1. Buy Diablo from GOG (~\$10)"
    echo ""
    echo "  2. Re-run this installer and answer 'y' to the ownership question -"
    echo "     the full game data is downloaded and verified automatically."
    echo ""
    echo "  Or manually: copy DIABDAT.MPQ from your CD or GOG install into:"
    echo "    $DATA_DIR"
    echo ""
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    if [[ "$USE_FULL_GAME" == true ]]; then
        echo "Diablo (Full Game) is ready to play!"
    else
        echo "Diablo (Shareware) is ready to play!"
    fi
    echo ""
    echo "Launch the game with:"
    echo "  open $APP_PATH"
    echo ""
    echo "Or find $APP_NAME in $INSTALL_DIR"
    echo ""
    echo "Game data location: $DATA_DIR"
    echo ""
    echo "Playing with friends:"
    echo "  Use the in-game multiplayer menu: Multiplayer > Direct TCP/IP connection."
    echo "  One player hosts from the menu; the others join by connecting to them."
    echo "  Works between shareware players out of the box."
    echo ""
}

main() {
    if [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]]; then
        AUTO_YES=true
    fi

    preflight
    prompt_game_version

    TEMP_DIR=$(mktemp -d)
    echo "  Temp directory: $TEMP_DIR"

    install_engine
    install_game_data
    print_upgrade_instructions
    finish
}

main "$@"
