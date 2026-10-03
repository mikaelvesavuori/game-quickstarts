#!/bin/bash
set -euo pipefail

VKQUAKE_VERSION="1.36.0"
ENGINE_URL="https://github.com/MacSourcePorts/MSPBuildSystem/releases/download/vkQuake-${VKQUAKE_VERSION}/vkQuake-${VKQUAKE_VERSION}.dmg"
ENGINE_FILE="vkQuake-${VKQUAKE_VERSION}.dmg"
APP_NAME="vkQuake.app"

SHAREWARE_URL="https://archive.org/download/Quake.7z/Quake.7z"
SHAREWARE_FILE="Quake.7z"

FULL_GAME_URL="https://archive.org/download/ultimate_ID_software_collection/QUAKE.zip"
FULL_GAME_FILE="QUAKE.zip"

INSTALL_DIR="/Applications/Quake"
APP_PATH="$INSTALL_DIR/$APP_NAME"

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

preflight() {
    echo "=== Quake (1996) Quickstart Installer ==="
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

    for cmd in curl hdiutil; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command not found: $cmd"
            exit 1
        fi
    done

    local seven_bin=""
    if command -v 7z &>/dev/null; then
        seven_bin="7z"
    elif command -v 7zz &>/dev/null; then
        seven_bin="7zz"
    fi

    if [[ -z "$seven_bin" ]]; then
        echo "7zip is required to extract the Quake game data."
        if command -v brew &>/dev/null; then
            read -r -p "Install 7zip via Homebrew? (y/N) " response </dev/tty
            if [[ "${response:-N}" == [Yy]* ]]; then
                brew install 7zip
            else
                echo "Error: 7zip is required. Install with: brew install 7zip"
                exit 1
            fi
        else
            echo "Error: 7zip is required. Install from https://7-zip.org/ or use: brew install 7zip"
            exit 1
        fi
    fi

    local free_kb
    free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local required_kb=1048576
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 1GB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

prompt_game_version() {
    echo ""
    echo "Do you own a legitimate copy of Quake (e.g. from GOG, Steam, or the original CD)?"
    read -r -p "  (y/N) " own_response </dev/tty
    if [[ "${own_response:-N}" == [Yy]* ]]; then
        USE_FULL_GAME=true
        echo ""
        echo "  Full game will be downloaded from archive.org (~597MB)."
        echo "  This includes all 4 episodes, both mission packs, and soundtrack."
    else
        echo ""
        echo "  Shareware version will be installed (Episode 1 only, freely distributable)."
        echo "  You can upgrade later by purchasing from GOG or Steam."
    fi
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing vkQuake v${VKQUAKE_VERSION} ==="

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

    echo "  Downloading vkQuake DMG..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_URL"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$ENGINE_FILE" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    if [[ ! -d "$DMG_MOUNT/$APP_NAME" ]]; then
        echo "Error: $APP_NAME not found in DMG."
        hdiutil detach "$DMG_MOUNT" -quiet 2>/dev/null || true
        DMG_MOUNT=""
        return 1
    fi

    echo "  Copying $APP_NAME to $INSTALL_DIR..."
    if ! cp -R "$DMG_MOUNT/$APP_NAME" "$INSTALL_DIR/"; then
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
    echo "=== Step 2: Downloading Quake game data ==="

    if [[ -d "$INSTALL_DIR/id1" ]]; then
        echo "  id1 folder already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
        rm -rf "$INSTALL_DIR/id1" "$INSTALL_DIR/hipnotic" "$INSTALL_DIR/rogue"
    fi

    local seven_bin=""
    if command -v 7z &>/dev/null; then
        seven_bin="7z"
    elif command -v 7zz &>/dev/null; then
        seven_bin="7zz"
    fi

    if [[ "$USE_FULL_GAME" == true ]]; then
        echo "  Downloading full Quake game (~597MB) from archive.org..."
        curl -f -L --progress-bar -o "$TEMP_DIR/$FULL_GAME_FILE" "$FULL_GAME_URL"

        echo "  Extracting..."
        "$seven_bin" x "$TEMP_DIR/$FULL_GAME_FILE" -o"$TEMP_DIR/fullgame" -y >/dev/null 2>&1

        local quake_root=""
        for dir in "$TEMP_DIR/fullgame"/QUAKE "$TEMP_DIR/fullgame"/Quake "$TEMP_DIR/fullgame"/quake; do
            if [[ -d "$dir" ]]; then
                quake_root="$dir"
                break
            fi
        done

        if [[ -z "$quake_root" ]]; then
            echo "Error: Quake directory not found in downloaded archive."
            return 1
        fi

        if [[ -d "$quake_root/id1" ]]; then
            echo "  Copying id1 folder (full game data)..."
            cp -R "$quake_root/id1" "$INSTALL_DIR/id1"
            chmod -R u+w "$INSTALL_DIR/id1" 2>/dev/null || true
        else
            echo "Error: id1 directory not found in full game archive."
            return 1
        fi

        if [[ -d "$quake_root/hipnotic" ]]; then
            echo "  Copying hipnotic folder (Mission Pack 1: Scourge of Armagon)..."
            cp -R "$quake_root/hipnotic" "$INSTALL_DIR/hipnotic"
            chmod -R u+w "$INSTALL_DIR/hipnotic" 2>/dev/null || true
        fi

        if [[ -d "$quake_root/rogue" ]]; then
            echo "  Copying rogue folder (Mission Pack 2: Dissolution of Eternity)..."
            cp -R "$quake_root/rogue" "$INSTALL_DIR/rogue"
            chmod -R u+w "$INSTALL_DIR/rogue" 2>/dev/null || true
        fi

        for music_src in "$quake_root/rerelease/id1/music" "$quake_root/id1/music"; do
            if [[ -d "$music_src" ]]; then
                mkdir -p "$INSTALL_DIR/id1/music"
                cp "$music_src/"*.ogg "$INSTALL_DIR/id1/music/" 2>/dev/null || true
                echo "  Soundtrack installed."
                break
            fi
        done

        for mp_music_src in "$quake_root/rerelease/hipnotic/music" "$quake_root/hipnotic/music"; do
            if [[ -d "$mp_music_src" ]]; then
                mkdir -p "$INSTALL_DIR/hipnotic/music"
                cp "$mp_music_src/"*.ogg "$INSTALL_DIR/hipnotic/music/" 2>/dev/null || true
                break
            fi
        done

        for mp_music_src in "$quake_root/rerelease/rogue/music" "$quake_root/rogue/music"; do
            if [[ -d "$mp_music_src" ]]; then
                mkdir -p "$INSTALL_DIR/rogue/music"
                cp "$mp_music_src/"*.ogg "$INSTALL_DIR/rogue/music/" 2>/dev/null || true
                break
            fi
        done

        echo "  Full game data installed."
    else
        echo "  Downloading Quake Shareware (~9MB)..."
        curl -f -L --progress-bar -o "$TEMP_DIR/$SHAREWARE_FILE" "$SHAREWARE_URL"

        echo "  Extracting..."
        "$seven_bin" x "$TEMP_DIR/$SHAREWARE_FILE" -o"$TEMP_DIR/shareware" -y >/dev/null 2>&1

        local id1_src=""
        for dir in "$TEMP_DIR/shareware"/*/id1 "$TEMP_DIR/shareware"/*/ID1 "$TEMP_DIR/shareware/id1" "$TEMP_DIR/shareware/ID1"; do
            if [[ -d "$dir" ]]; then
                id1_src="$dir"
                break
            fi
        done

        if [[ -z "$id1_src" ]]; then
            echo "Error: id1 directory not found in shareware archive."
            return 1
        fi

        echo "  Copying id1 folder..."
        cp -R "$id1_src" "$INSTALL_DIR/id1"
        chmod -R u+w "$INSTALL_DIR/id1" 2>/dev/null || true

        echo "  Shareware data installed."
    fi
}

print_upgrade_instructions() {
    if [[ "$USE_FULL_GAME" == true ]]; then
        return 0
    fi

    echo ""
    echo "=== Upgrading to the Full Game ==="
    echo ""
    echo "The shareware version includes Episode 1 only."
    echo ""
    echo "To get the full game:"
    echo ""
    echo "  1. Buy 'Quake: The Offering' from GOG (~\$10) or Steam (~\$10)"
    echo "     - Includes all 4 episodes + both mission packs + soundtrack"
    echo ""
    echo "  2. Replace the id1 folder:"
    echo "     rm -rf $INSTALL_DIR/id1"
    echo "     cp -R /path/to/full/Quake/id1 $INSTALL_DIR/"
    echo ""
    echo "  3. (Optional) Add mission packs:"
    echo "     cp -R /path/to/full/Quake/hipnotic $INSTALL_DIR/  # Scourge of Armagon"
    echo "     cp -R /path/to/full/Quake/rogue    $INSTALL_DIR/  # Dissolution of Eternity"
    echo ""
    echo "  4. (Optional) Add CD soundtrack as OGG files:"
    echo "     Place track02.ogg ... track11.ogg in $INSTALL_DIR/id1/music/"
    echo ""
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    if [[ "$USE_FULL_GAME" == true ]]; then
        echo "Quake (Full Game) is ready to play!"
        echo ""
        echo "Includes:"
        echo "  - All 4 episodes (id1)"
        if [[ -d "$INSTALL_DIR/hipnotic" ]]; then
            echo "  - Mission Pack 1: Scourge of Armagon (hipnotic)"
        fi
        if [[ -d "$INSTALL_DIR/rogue" ]]; then
            echo "  - Mission Pack 2: Dissolution of Eternity (rogue)"
        fi
        if [[ -d "$INSTALL_DIR/id1/music" ]]; then
            echo "  - CD Soundtrack (id1/music)"
        fi
    else
        echo "Quake (Shareware) is ready to play!"
        echo ""
        echo "Includes Episode 1 only. Run the game and use the in-game menu"
        echo "to upgrade, or see the upgrade instructions above."
    fi
    echo ""
    echo "Launch the game with:"
    echo "  open $APP_PATH"
    echo ""
    echo "Or find $APP_NAME in $INSTALL_DIR"
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
