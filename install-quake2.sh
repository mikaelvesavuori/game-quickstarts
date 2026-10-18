#!/bin/bash
set -euo pipefail

YAMAGI_VERSION="8.70"
ENGINE_URL="https://github.com/MacSourcePorts/MSPBuildSystem/releases/download/yquake2_${YAMAGI_VERSION}/yquake2-${YAMAGI_VERSION}.dmg"
ENGINE_FILE="yquake2-${YAMAGI_VERSION}.dmg"
ENGINE_SHA256="526a2a5e5377b0295852d0c9f0c7e2ea7443f7f85a1a37ba88e951e19f84e166"
APP_NAME="yquake2.app"

DEMO_URL="https://deponie.yamagi.org/quake2/idstuff/q2-314-demo-x86.exe"
DEMO_FILE="q2-314-demo-x86.exe"
DEMO_MD5="4d1cd4618e80a38db59304132ea0856c"

FULL_GAME_URL="https://archive.org/download/quake-2-complete/Quake%202.zip"
FULL_GAME_FILE="Quake2.zip"
FULL_GAME_SHA1="09a4930c326effbd9a8975f7e601a6f2ba5aea32"

INSTALL_DIR="/Applications/Quake2"
APP_PATH="$INSTALL_DIR/$APP_NAME"
GAME_DATA_DIR="$HOME/.local/share/YamagiQ2"

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

verify_sha1() {
    local file="$1"
    local expected="$2"
    local actual
    actual=$(shasum -a 1 "$file" | awk '{print $1}')
    if [[ "$actual" != "$expected" ]]; then
        echo "Error: SHA1 verification failed for $(basename "$file")"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
    echo "  Checksum verified."
}

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

preflight() {
    echo "=== Quake II (1997) Quickstart Installer ==="
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

    for cmd in curl hdiutil unzip shasum md5; do
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

check_full_game_space() {
    local free_kb
    free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local required_kb=2621440
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space for full game. Need at least 2.5GB free."
        echo "  Available: $((free_kb / 1024))MB"
        return 1
    fi
}

prompt_game_version() {
    echo ""
    echo "Do you own a legitimate copy of Quake II (e.g. from GOG, Steam, or the original CD)?"
    read -r -p "  (y/N) " own_response </dev/tty
    if [[ "${own_response:-N}" == [Yy]* ]]; then
        USE_FULL_GAME=true
        echo ""
        echo "  Full game will be downloaded from archive.org (~897MB)."
        echo "  Includes the base game plus both mission packs and CTF, if present."
    else
        echo ""
        echo "  Demo version will be installed (freely distributable):"
        echo "  3 single-player levels and the included deathmatch maps."
        echo "  You can upgrade later by purchasing from GOG or Steam."
    fi
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing Yamagi Quake II v${YAMAGI_VERSION} ==="

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

    echo "  Downloading Yamagi Quake II DMG (~9MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_URL"
    verify_sha256 "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_SHA256"

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

copy_fullgame_dir() {
    local src="$1"
    local name="$2"
    cp -R "$src" "$GAME_DATA_DIR/$name"
    chmod -R u+w "$GAME_DATA_DIR/$name" 2>/dev/null || true
    echo "  Copied $name."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Downloading Quake II game data ==="

    if [[ -d "$GAME_DATA_DIR/baseq2" ]]; then
        echo "  baseq2 folder already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
        rm -rf "$GAME_DATA_DIR"
    fi

    mkdir -p "$GAME_DATA_DIR"

    if [[ "$USE_FULL_GAME" == true ]]; then
        check_full_game_space

        echo "  Downloading full Quake II (~897MB) from archive.org..."
        curl -f -L --progress-bar -o "$TEMP_DIR/$FULL_GAME_FILE" "$FULL_GAME_URL"
        verify_sha1 "$TEMP_DIR/$FULL_GAME_FILE" "$FULL_GAME_SHA1"

        echo "  Extracting..."
        unzip -q -o "$TEMP_DIR/$FULL_GAME_FILE" -d "$TEMP_DIR/fullgame"

        local baseq2_src=""
        baseq2_src=$(find "$TEMP_DIR/fullgame" -type d -name baseq2 | head -1 || true)
        if [[ -z "$baseq2_src" ]]; then
            echo "Error: baseq2 directory not found in downloaded archive."
            return 1
        fi

        mkdir -p "$GAME_DATA_DIR/baseq2"
        echo "  Copying baseq2 folder (full game data)..."
        cp -R "$baseq2_src/." "$GAME_DATA_DIR/baseq2/"
        chmod -R u+w "$GAME_DATA_DIR/baseq2" 2>/dev/null || true

        for addon in ctf xatrix rogue; do
            local addon_src
            addon_src=$(find "$TEMP_DIR/fullgame" -type d -name "$addon" | head -1 || true)
            if [[ -n "$addon_src" ]]; then
                copy_fullgame_dir "$addon_src" "$addon"
            fi
        done

        echo "  Full game data installed."
    else
        echo "  Downloading Quake II demo (~36MB) from Yamagi's official mirror..."
        curl -f -L --progress-bar -o "$TEMP_DIR/$DEMO_FILE" "$DEMO_URL"
        verify_md5 "$TEMP_DIR/$DEMO_FILE" "$DEMO_MD5"

        echo "  Extracting (self-extracting ZIP)..."
        unzip -q -o "$TEMP_DIR/$DEMO_FILE" -d "$TEMP_DIR/demo"

        if [[ ! -f "$TEMP_DIR/demo/Install/Data/baseq2/pak0.pak" ]]; then
            echo "Error: pak0.pak not found in demo archive."
            return 1
        fi

        echo "  Installing baseq2 folder (demo levels + deathmatch maps)..."
        mkdir -p "$GAME_DATA_DIR/baseq2"
        cp "$TEMP_DIR/demo/Install/Data/baseq2/pak0.pak" "$GAME_DATA_DIR/baseq2/"
        cp -R "$TEMP_DIR/demo/Install/Data/baseq2/players" "$GAME_DATA_DIR/baseq2/" 2>/dev/null || true

        echo "  Demo data installed."
    fi
}

print_upgrade_instructions() {
    if [[ "$USE_FULL_GAME" == true ]]; then
        return 0
    fi

    echo ""
    echo "=== Upgrading to the Full Game ==="
    echo ""
    echo "The demo version includes 3 single-player levels and the included"
    echo "deathmatch maps only."
    echo ""
    echo "To upgrade to the full game:"
    echo ""
    echo "  1. Buy Quake II from GOG (~\$5) or Steam (~\$5)"
    echo "     - The 2023 remaster also includes both mission packs and the soundtrack"
    echo ""
    echo "  2. Replace the baseq2 folder:"
    echo "     rm -rf '$GAME_DATA_DIR/baseq2'"
    echo "     cp -R /path/to/full/Quake2/baseq2 '$GAME_DATA_DIR/'"
    echo ""
    echo "  3. (Optional) Add the mission packs/CTF:"
    echo "     cp -R /path/to/full/Quake2/xatrix '$GAME_DATA_DIR/'   # The Reckoning"
    echo "     cp -R /path/to/full/Quake2/rogue  '$GAME_DATA_DIR/'   # Ground Zero"
    echo "     cp -R /path/to/full/Quake2/ctf    '$GAME_DATA_DIR/'   # Capture the Flag"
    echo ""
    echo "  Or simply re-run this installer and answer 'y' to the copy question."
    echo ""
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    if [[ "$USE_FULL_GAME" == true ]]; then
        echo "Quake II (Full Game) is ready to play!"
    else
        echo "Quake II (Demo) is ready to play!"
    fi
    echo ""
    echo "Launch the game with:"
    echo "  open $APP_PATH"
    echo ""
    echo "Or find $APP_NAME in $INSTALL_DIR"
    echo ""
    echo "Game data location: $GAME_DATA_DIR"
    echo ""
    echo "Playing with friends:"
    echo "  Host or join from the in-game multiplayer menu (direct"
    echo "  connection support is built in)."
    echo "  Note: saving is disabled in the demo version."
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
