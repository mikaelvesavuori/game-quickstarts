#!/bin/bash
set -euo pipefail

ENGINE_URL="https://files.ioquake3.org/ioquake3_notarized.zip"
ENGINE_FILE="ioquake3_notarized.zip"

PATCH_DATA_URL="https://files.ioquake3.org/quake3-latest-pk3s.zip"
PATCH_DATA_FILE="quake3-latest-pk3s.zip"

ISO_URL="https://archive.org/download/Quake_III_Arena_Id_Software_1999/Quake_III_Arena_Id_Software_1999.iso"
ISO_FILE="quake3.iso"

INSTALL_DIR="/Applications/ioquake3"
APP_PATH="$INSTALL_DIR/ioquake3.app"

TEMP_DIR=""
ISO_MOUNT=""
AUTO_YES=false

cleanup() {
    local exit_code=$?
    if [[ -n "${ISO_MOUNT:-}" ]]; then
        hdiutil detach "$ISO_MOUNT" -force -quiet 2>/dev/null || true
    fi
    if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "${TEMP_DIR:-}" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    exit $exit_code
}
trap cleanup EXIT

preflight() {
    echo "=== Quake III Arena Quickstart Installer ==="
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

    for cmd in curl hdiutil unzip; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command not found: $cmd"
            exit 1
        fi
    done

    local free_kb
    free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local required_kb=1048576
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 1GB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Install ioquake3 (notarized Universal 2 build) to /Applications/ioquake3"
    echo "  2. Download the Quake III Arena CD ISO (~530MB) from archive.org"
    echo "  3. Copy pak0.pk3 (game data) from the CD"
    echo "  4. Download and install the latest patch data (pak1-8) from ioquake3.org"
    echo ""
    echo "Install location: $INSTALL_DIR"
    echo ""
    echo "Note: This CD is the original 1999 release without Team Arena."
    echo "      For Team Arena, purchase from GOG (\$6) or Steam (\$15)."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing ioquake3 ==="

    mkdir -p "$INSTALL_DIR"

    echo "  Downloading ioquake3 (notarized, Universal 2)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_URL"

    echo "  Extracting..."
    unzip -q "$TEMP_DIR/$ENGINE_FILE" -d "$TEMP_DIR/engine"

    local app_found=""
    for app in "$TEMP_DIR/engine"/*.app "$TEMP_DIR/engine"/*/*.app; do
        if [[ -d "$app" ]]; then
            app_found="$app"
            break
        fi
    done

    if [[ -z "$app_found" ]]; then
        echo "Error: ioquake3.app not found in downloaded archive."
        return 1
    fi

    echo "  Copying ioquake3.app to $INSTALL_DIR..."
    cp -R "$app_found" "$INSTALL_DIR/"

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  Engine installed."
}

install_patch_data() {
    echo ""
    echo "=== Step 2: Downloading patch data (pak1-8) ==="

    echo "  Downloading patch data..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$PATCH_DATA_FILE" "$PATCH_DATA_URL"

    echo "  Extracting..."
    unzip -q "$TEMP_DIR/$PATCH_DATA_FILE" -d "$TEMP_DIR/patch_data"

    for gamedir in baseq3 missionpack; do
        local src=""
        for dir in "$TEMP_DIR/patch_data"/*/"$gamedir" "$TEMP_DIR/patch_data/$gamedir"; do
            if [[ -d "$dir" ]]; then
                src="$dir"
                break
            fi
        done
        if [[ -n "$src" ]]; then
            echo "  Installing $gamedir patch files..."
            mkdir -p "$INSTALL_DIR/$gamedir"
            cp "$src/"*.pk3 "$INSTALL_DIR/$gamedir/" 2>/dev/null || true
        fi
    done

    echo "  Patch data installed."
}

install_game_data() {
    echo ""
    echo "=== Step 3: Downloading Quake III Arena CD ==="

    echo "  Downloading ISO (~530MB) from archive.org..."
    curl -f -L --progress-bar --connect-timeout 30 -o "$TEMP_DIR/$ISO_FILE" "$ISO_URL"

    ISO_MOUNT="$TEMP_DIR/iso_mount"
    mkdir -p "$ISO_MOUNT"
    echo "  Mounting ISO..."
    hdiutil attach "$TEMP_DIR/$ISO_FILE" -mountpoint "$ISO_MOUNT" -nobrowse -readonly -quiet

    local pak0=""
    for dir in "$ISO_MOUNT"/*/baseq3 "$ISO_MOUNT"/*/BASEQ3 "$ISO_MOUNT/baseq3" "$ISO_MOUNT/BASEQ3"; do
        if [[ -d "$dir" ]]; then
            for pak in "$dir"/pak0.pk3 "$dir"/PAK0.PK3; do
                if [[ -f "$pak" ]]; then
                    pak0="$pak"
                    break 2
                fi
            done
        fi
    done

    if [[ -z "$pak0" ]]; then
        echo "Error: pak0.pk3 not found in ISO."
        return 1
    fi

    echo ""
    echo "=== Step 4: Copying game data ==="

    mkdir -p "$INSTALL_DIR/baseq3"
    echo "  Copying pak0.pk3..."
    cp "$pak0" "$INSTALL_DIR/baseq3/pak0.pk3"

    local mp_pak0=""
    for dir in "$ISO_MOUNT"/*/missionpack "$ISO_MOUNT"/*/MISSIONPACK "$ISO_MOUNT/missionpack" "$ISO_MOUNT/MISSIONPACK"; do
        if [[ -d "$dir" ]]; then
            for pak in "$dir"/pak0.pk3 "$dir"/PAK0.PK3; do
                if [[ -f "$pak" ]]; then
                    mp_pak0="$pak"
                    break 2
                fi
            done
        fi
    done

    if [[ -n "$mp_pak0" ]]; then
        mkdir -p "$INSTALL_DIR/missionpack"
        echo "  Copying missionpack/pak0.pk3..."
        cp "$mp_pak0" "$INSTALL_DIR/missionpack/pak0.pk3"
    else
        echo "  Team Arena not found on this CD (original 1999 release)."
        echo "  For Team Arena, purchase Quake III + Team Arena from GOG or Steam."
    fi

    hdiutil detach "$ISO_MOUNT" -quiet
    ISO_MOUNT=""

    echo "  Game data copied."
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Quake III Arena is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open $APP_PATH"
    echo ""
    echo "Or find ioquake3.app in $INSTALL_DIR"
    echo ""

    if [[ ! -d "$INSTALL_DIR/missionpack" ]] || \
       [[ -z "$(ls "$INSTALL_DIR/missionpack/"*.pk3 2>/dev/null)" ]]; then
        echo "Team Arena: Not installed (not on the original CD)."
        echo "  To add Team Arena, buy from GOG (\$6) or Steam (\$15),"
        echo "  then copy missionpack/pak0.pk3 to:"
        echo "  $INSTALL_DIR/missionpack/"
        echo ""
    fi
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
    install_patch_data
    install_game_data
    finish
}

main "$@"
