#!/bin/bash
set -euo pipefail

RAZE_VERSION="1.11.0"
ENGINE_URL="https://github.com/ZDoom/Raze/releases/download/${RAZE_VERSION}/raze-macos-${RAZE_VERSION}.zip"
ENGINE_FILE="raze-macos-${RAZE_VERSION}.zip"
ENGINE_SHA256="b7980849a507cfcfeaf8f76298c032bfe4415b2f246f41e3c0c9a6291770c70c"

# Duke Nukem 3D shareware v1.3d (Episode 1: L.A. Meltdown), freely redistributable.
# The ZIP contains 3D Realms' DN3DSW13.SHR installer package; 7-Zip extracts the GRP.
SHAREWARE_URL="https://archive.org/download/duke-nukem-3d-shareware/Duke%20Nukem%203D.zip"
SHAREWARE_FILE="duke-shareware.zip"
SHAREWARE_SHA1="d7191ea177436656784312d339593c90a86c9667"

INSTALL_DIR="/Applications/Duke3D"
ENGINE_APP_PATH="$INSTALL_DIR/Raze.app"
LAUNCHER_APP_PATH="$INSTALL_DIR/Duke Nukem 3D.app"

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

preflight() {
    echo "=== Duke Nukem 3D (1996) Shareware Quickstart Installer ==="
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

    for cmd in curl unzip shasum; do
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
        echo "7zip is required to extract the shareware game data."
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
    local required_kb=209715
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 205MB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Install Raze v${RAZE_VERSION} (Universal 2, Apple Silicon + Intel)"
    echo "     to /Applications/Duke3D"
    echo "  2. Download the freely distributable shareware data (~6MB)"
    echo "     - Episode 1: L.A. Meltdown"
    echo "  3. Create a launcher app so the game is ready to play immediately"
    echo ""
    echo "Raze is the maintained Build-engine port from the GZDoom team."
    echo "You can upgrade to the full game at any time (GOG/Steam, ~\$5) - see"
    echo "the instructions printed at the end of this installation."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

seven_zip_bin() {
    if command -v 7z &>/dev/null; then
        echo "7z"
    else
        echo "7zz"
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing Raze v${RAZE_VERSION} ==="

    if [[ -d "$ENGINE_APP_PATH" ]]; then
        echo "  Raze.app already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing installation? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing installation."
                return 0
            fi
        fi
        rm -rf "$ENGINE_APP_PATH"
    fi

    mkdir -p "$INSTALL_DIR"

    echo "  Downloading Raze (~32MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_URL"
    verify_sha256 "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_SHA256"

    echo "  Unpacking..."
    unzip -q -o "$TEMP_DIR/$ENGINE_FILE" -d "$TEMP_DIR/raze"
    if [[ ! -d "$TEMP_DIR/raze/Raze.app" ]]; then
        echo "Error: Raze.app not found in archive."
        return 1
    fi

    echo "  Copying Raze.app to $INSTALL_DIR..."
    cp -R "$TEMP_DIR/raze/Raze.app" "$INSTALL_DIR/"

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$ENGINE_APP_PATH" 2>/dev/null || true

    echo "  Engine installed."
}

extract_shareware_grp() {
    local seven_bin
    seven_bin=$(seven_zip_bin)

    unzip -q -o "$TEMP_DIR/$SHAREWARE_FILE" -d "$TEMP_DIR/shareware"

    local shr_file=""
    for file in "$TEMP_DIR/shareware"/*.SHR "$TEMP_DIR/shareware"/*.shr; do
        if [[ -f "$file" ]]; then
            shr_file="$file"
            break
        fi
    done
    if [[ -z "$shr_file" ]]; then
        echo "Error: Shareware installer package (.SHR) not found in archive."
        return 1
    fi

    "$seven_bin" x "$shr_file" -o"$TEMP_DIR/grp" -y >/dev/null 2>&1

    if [[ ! -f "$TEMP_DIR/grp/DUKE3D.GRP" ]]; then
        echo "Error: DUKE3D.GRP not found in extracted package."
        return 1
    fi
    echo "  Game data extracted."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Downloading Duke Nukem 3D shareware data ==="

    if [[ -f "$INSTALL_DIR/DUKE3D.GRP" ]]; then
        echo "  DUKE3D.GRP already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
        rm -f "$INSTALL_DIR/DUKE3D.GRP" "$INSTALL_DIR/DUKE.RTS"
    fi

    echo "  Downloading shareware package (~6MB) from archive.org..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$SHAREWARE_FILE" "$SHAREWARE_URL"
    verify_sha1 "$TEMP_DIR/$SHAREWARE_FILE" "$SHAREWARE_SHA1"

    extract_shareware_grp

    echo "  Installing game data into $INSTALL_DIR..."
    cp "$TEMP_DIR/grp/DUKE3D.GRP" "$INSTALL_DIR/"
    if [[ -f "$TEMP_DIR/grp/DUKE.RTS" ]]; then
        cp "$TEMP_DIR/grp/DUKE.RTS" "$INSTALL_DIR/"
    fi

    echo "  Game data installed."
}

create_launcher() {
    echo ""
    echo "=== Step 3: Creating launcher app ==="

    rm -rf "$LAUNCHER_APP_PATH"

    local launcher_contents="$LAUNCHER_APP_PATH/Contents"
    mkdir -p "$launcher_contents/MacOS" "$launcher_contents/Resources"

    # Raze finds game data in the current working directory. The launcher
    # app cd's to the installation folder before starting Raze, so the game
    # works when launched from Finder, Spotlight or `open`.
    cat > "$launcher_contents/MacOS/Duke Nukem 3D" <<'LAUNCHER_EOF'
#!/bin/bash
cd "$(dirname "$0")/../../.." || exit 1
exec "./Raze.app/Contents/MacOS/Raze" "$@"
LAUNCHER_EOF
    chmod +x "$launcher_contents/MacOS/Duke Nukem 3D"

    # Reuse Raze's own icon if available
    for icns in "$ENGINE_APP_PATH/Contents/Resources/"*.icns; do
        if [[ -f "$icns" ]]; then
            cp "$icns" "$launcher_contents/Resources/AppIcon.icns"
            break
        fi
    done

    cat > "$launcher_contents/Info.plist" <<'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Duke Nukem 3D</string>
    <key>CFBundleDisplayName</key>
    <string>Duke Nukem 3D</string>
    <key>CFBundleIdentifier</key>
    <string>com.mikaelvesavuori.game-quickstarts.duke3d-launcher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Duke Nukem 3D</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

    xattr -dr com.apple.quarantine "$LAUNCHER_APP_PATH" 2>/dev/null || true

    echo "  Launcher created: $LAUNCHER_APP_PATH"
}

print_upgrade_instructions() {
    echo ""
    echo "=== Upgrading to the Full Game ==="
    echo ""
    echo "The shareware version includes Episode 1: L.A. Meltdown only."
    echo ""
    echo "To get the full game:"
    echo ""
    echo "  1. Buy Duke Nukem 3D: Atomic Edition from GOG (~\$5) or Steam (~\$5)"
    echo "     - Includes all 3 episodes + the Atomic expansion"
    echo ""
    echo "  2. Replace the game data:"
    echo "     Copy DUKE3D.GRP (registered v1.3d or Atomic v1.5) from your"
    echo "     installation over this file:"
    echo "       $INSTALL_DIR/DUKE3D.GRP"
    echo "     (GOG/Steam users: extract the game files from the installer with"
    echo "      innoextract, or run the Windows installer under CrossOver/Wine)"
    echo ""
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Duke Nukem 3D (Shareware) is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open '$LAUNCHER_APP_PATH'"
    echo ""
    echo "Or find 'Duke Nukem 3D' in $INSTALL_DIR"
    echo ""
    echo "Playing with friends:"
    echo "  Raze supports LAN and direct-connection multiplayer from the"
    echo "  in-game menu (basic P2P netcode) - one player hosts, the"
    echo "  others join by connecting to them."
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
    create_launcher
    print_upgrade_instructions
    finish
}

main "$@"
