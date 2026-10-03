#!/bin/bash
set -euo pipefail

ENGINE_URL="https://github.com/Interkarma/daggerfall-unity/releases/download/v1.1.1-cve-2025/dfu_mac_universal-v1.1.1.zip"
ENGINE_FILE="dfu_mac_universal-v1.1.1.zip"
ENGINE_SHA256="1edc4dd594b61686e187b84d99e295074670f07e3d308c29caa3378b6368bf56"
APP_NAME="DaggerfallUnity.app"
APP_PATH="/Applications/$APP_NAME"
GAME_FILES_DIR="$APP_PATH/Contents/Resources/Data/StreamingAssets/GameFiles"

GAME_DATA_URL="https://archive.org/download/elder-scrolls-2-daggerfall/Elder%20Scrolls%202%20Daggerfall.rar"
GAME_DATA_FILE="daggerfall.rar"
GAME_DATA_SHA1="b5e027016cce10f8d76bdbff692406e7acdd700b"

TEMP_DIR=""
AUTO_YES=false

cleanup() {
    local exit_code=$?
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

ensure_rosetta() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        if ! /usr/bin/pgrep -q oahd 2>/dev/null; then
            echo "  Installing Rosetta 2 (required for Daggerfall Unity on Apple Silicon)..."
            softwareupdate --install-rosetta --agree-to-license
        else
            echo "  Rosetta 2 already installed."
        fi
    fi
}

ensure_7zip() {
    if command -v 7z &>/dev/null || command -v 7zz &>/dev/null; then
        return 0
    fi
    echo "  7zip is required to extract game data."
    if command -v brew &>/dev/null; then
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Install 7zip via Homebrew? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "Error: 7zip is required. Install with: brew install 7zip"
                return 1
            fi
        fi
        brew install 7zip
    else
        echo "Error: 7zip is required. Install from https://7-zip.org/ or use: brew install 7zip"
        return 1
    fi
}

get_7z() {
    if command -v 7zz &>/dev/null; then
        echo "7zz"
    else
        echo "7z"
    fi
}

preflight() {
    echo "=== The Elder Scrolls II: Daggerfall (Daggerfall Unity) Quickstart Installer ==="
    echo ""

    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Error: This script is for macOS only."
        exit 1
    fi

    local arch
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        echo "System: macOS on Apple Silicon (arm64)"
        echo "  Note: Daggerfall Unity runs via Rosetta 2 on Apple Silicon."
    else
        echo "System: macOS on Intel ($arch)"
    fi
    echo ""

    for cmd in curl unzip shasum; do
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
    echo "  1. Install Rosetta 2 if needed (Apple Silicon only)"
    echo "  2. Install Daggerfall Unity v1.1.1 to /Applications"
    echo "  3. Download The Elder Scrolls II: Daggerfall game data (~107MB, free)"
    echo "  4. Set up game data for immediate play (no first-run setup needed)"
    echo ""
    echo "Launch location: $APP_PATH"
    echo ""
    echo "Note: Daggerfall was released as freeware by Bethesda Softworks."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing Daggerfall Unity ==="

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

    echo "  Downloading Daggerfall Unity (~50MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_URL"
    verify_sha256 "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_SHA256"

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
        echo "Error: $APP_NAME not found in downloaded archive."
        return 1
    fi

    echo "  Copying $APP_NAME to /Applications..."
    cp -R "$app_found" /Applications/

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  Engine installed."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Downloading Daggerfall game data ==="

    ensure_7zip
    local seven_bin
    seven_bin=$(get_7z)

    if [[ -d "$GAME_FILES_DIR/ARENA2" ]]; then
        echo "  Game data already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
        rm -rf "$GAME_FILES_DIR/ARENA2"
    fi

    echo "  Downloading game data (~107MB) from archive.org..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$GAME_DATA_FILE" "$GAME_DATA_URL"
    verify_sha1 "$TEMP_DIR/$GAME_DATA_FILE" "$GAME_DATA_SHA1"

    echo "  Extracting game data..."
    "$seven_bin" x "$TEMP_DIR/$GAME_DATA_FILE" -o"$TEMP_DIR/gamedata" -y >/dev/null 2>&1

    local arena2_src=""
    for dir in "$TEMP_DIR/gamedata"/*/DFCD/DAGGER/ARENA2 \
               "$TEMP_DIR/gamedata"/*/DAGGER/ARENA2 \
               "$TEMP_DIR/gamedata"/*/ARENA2 \
               "$TEMP_DIR/gamedata/ARENA2"; do
        if [[ -d "$dir" ]]; then
            arena2_src="$dir"
            break
        fi
    done

    if [[ -z "$arena2_src" ]]; then
        echo "Error: ARENA2 directory not found in game data archive."
        return 1
    fi

    echo "  Copying ARENA2 to game files directory..."
    mkdir -p "$GAME_FILES_DIR"
    cp -R "$arena2_src" "$GAME_FILES_DIR/ARENA2"
    chmod -R u+w "$GAME_FILES_DIR/ARENA2" 2>/dev/null || true

    echo "  Creating Portable.txt for self-contained install..."
    touch "${APP_PATH}/Contents/MacOS/Portable.txt"

    echo "  Game data installed."
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "The Elder Scrolls II: Daggerfall is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open $APP_PATH"
    echo ""
    echo "Or find $APP_NAME in your Applications folder."
    echo ""
    echo "Daggerfall Unity includes many improvements over the original:"
    echo "  - Modern resolution and controls"
    echo "  - Bug fixes and quality-of-life features"
    echo "  - Mod support (Mods > Mod Manager in-game)"
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

    ensure_rosetta
    install_engine
    install_game_data
    finish
}

main "$@"
