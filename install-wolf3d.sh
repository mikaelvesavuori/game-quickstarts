#!/bin/bash
set -euo pipefail

# ECWolf 1.4.2 — official macOS release from the ECWolf developer's own
# site. Universal quad-arch binary (Apple Silicon, Intel — plus i386 and
# PowerPC for older Macs), works from macOS 10.4 and later.
ECWOLF_VERSION="1.4.2"
ENGINE_URL="https://maniacsvault.net/ecwolf/files/ecwolf/1.x/ecwolf-${ECWOLF_VERSION}.dmg"
ENGINE_FILE="ecwolf-${ECWOLF_VERSION}.dmg"
ENGINE_SHA256="9261a1105c48669ff27bde975a82c95605e8d36503505e3e3bee39de76baca95"

# Wolfenstein 3D shareware v1.4 (Episode 1), distributed by the ECWolf
# project itself — id Software released it as freely redistributable
# shareware in 1992. The ZIP holds the eight .WL1 data files ECWolf needs.
SHAREWARE_URL="https://maniacsvault.net/ecwolf/files/shareware/wolf3d14.zip"
SHAREWARE_FILE="wolf3d14.zip"
SHAREWARE_SHA256="23efc1839b9bd91de43fbd036e55aca94271293dd46d176dafd40378b2f94108"

INSTALL_DIR="/Applications/Wolf3D"
ENGINE_APP_PATH="$INSTALL_DIR/ECWolf.app"

# ECWolf's documented game data search path on macOS.
DATA_DIR="$HOME/Library/Application Support/ECWolf"

LAUNCHER_APP_PATH="$INSTALL_DIR/Wolfenstein 3D.app"

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
    echo "=== Wolfenstein 3D (1992) Shareware Quickstart Installer ==="
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

    for cmd in curl hdiutil unzip shasum; do
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
    echo "  1. Install ECWolf v${ECWOLF_VERSION} (official build, universal:"
    echo "     Apple Silicon + Intel, from the ECWolf project's own site)"
    echo "     to $INSTALL_DIR — SHA256-verified"
    echo "  2. Download the freely redistributable Wolfenstein 3D shareware"
    echo "     v1.4 (Episode 1, ~1MB, also from the ECWolf project's site)"
    echo "  3. Create a launcher app so the game is ready to play immediately"
    echo ""
    echo "ECWolf is the maintained Wolfenstein 3D engine port (1992 id"
    echo "Software classic + Spear of Destiny support) with modern"
    echo "resolutions and controls. The shareware gives Episode 1; the"
    echo "full game (all 6 episodes + Spear of Destiny) can be added any"
    echo "time from an owned Steam/GOG copy (~\$5) — see the notes printed"
    echo "at the end of this installation."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing ECWolf v${ECWOLF_VERSION} ==="

    if [[ -d "$ENGINE_APP_PATH" ]]; then
        echo "  ECWolf.app already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing engine? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing engine."
                return 0
            fi
        fi
        rm -rf "$ENGINE_APP_PATH"
    fi

    mkdir -p "$INSTALL_DIR"

    echo "  Downloading ECWolf DMG (~24MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_URL"
    verify_sha256 "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_SHA256"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$ENGINE_FILE" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    if [[ ! -d "$DMG_MOUNT/ECWolf.app" ]]; then
        echo "Error: ECWolf.app not found in DMG."
        return 1
    fi

    echo "  Copying ECWolf.app to $INSTALL_DIR..."
    if ! cp -R "$DMG_MOUNT/ECWolf.app" "$INSTALL_DIR/"; then
        echo "Error: Failed to copy to $INSTALL_DIR."
        return 1
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$ENGINE_APP_PATH" 2>/dev/null || true

    echo "  Engine installed."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Downloading Wolfenstein 3D shareware data ==="

    if compgen -G "$DATA_DIR/*.WL1" >/dev/null; then
        echo "  Game data (*.WL1) already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
        rm -f "$DATA_DIR"/*.WL1
    fi

    mkdir -p "$DATA_DIR"

    echo "  Downloading shareware v1.4 (~1.4MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$SHAREWARE_FILE" "$SHAREWARE_URL"
    verify_sha256 "$TEMP_DIR/$SHAREWARE_FILE" "$SHAREWARE_SHA256"

    echo "  Unpacking..."
    unzip -q -o "$TEMP_DIR/$SHAREWARE_FILE" -d "$TEMP_DIR/shareware"

    echo "  Installing game data into $DATA_DIR..."
    local copied=0
    for f in "$TEMP_DIR/shareware/wolf3d14"/*.WL1; do
        [[ -f "$f" ]] || continue
        cp "$f" "$DATA_DIR/"
        copied=$((copied + 1))
    done
    if [[ "$copied" -lt 8 ]]; then
        echo "Error: Expected 8 .WL1 files, found $copied."
        return 1
    fi
    echo "  Game data installed ($copied files)."
}

create_launcher() {
    echo ""
    echo "=== Step 3: Creating launcher app ==="

    rm -rf "$LAUNCHER_APP_PATH"

    local launcher_contents="$LAUNCHER_APP_PATH/Contents"
    mkdir -p "$launcher_contents/MacOS" "$launcher_contents/Resources"

    # Game data lives in ~/Library/Application Support/ECWolf (ECWolf's own
    # documented search path), so the launcher just starts the engine.
    cat > "$launcher_contents/MacOS/Wolfenstein 3D" <<'LAUNCHER_EOF'
#!/bin/bash
exec "$(dirname "$0")/../../../ECWolf.app/Contents/MacOS/ecwolf" "$@"
LAUNCHER_EOF
    chmod +x "$launcher_contents/MacOS/Wolfenstein 3D"

    # Reuse ECWolf's own icon if available
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
    <string>Wolfenstein 3D</string>
    <key>CFBundleDisplayName</key>
    <string>Wolfenstein 3D</string>
    <key>CFBundleIdentifier</key>
    <string>com.mikaelvesavuori.game-quickstarts.wolf3d-launcher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Wolfenstein 3D</string>
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
    echo "The shareware version includes Episode 1 only. The full game has"
    echo "all 6 episodes, plus Spear of Destiny missions."
    echo ""
    echo "  1. Buy Wolfenstein 3D on GOG (~\$5) or Steam — or dust off your"
    echo "     1992 floppy/CD copy"
    echo ""
    echo "  2. Copy the registered game files into:"
    echo "       $DATA_DIR"
    echo "     Registered Wolf3D files are .WL6 (GAMEMAPS.WL6, MAPHEAD.WL6,"
    echo "     VGAGRAPH.WL6, VGAHEAD.WL6, VGADICT.WL6, VSWAP.WL6,"
    echo "     AUDIOHED.WL6, AUDIOT.WL6); Spear of Destiny uses .SOD files."
    echo "     ECWolf shows every detected game version in its title menu."
    echo ""
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Wolfenstein 3D (shareware, Episode 1) is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open '$LAUNCHER_APP_PATH'"
    echo ""
    echo "Settings and saved games live in:"
    echo "  $DATA_DIR"
    echo ""
    echo "Playing with friends:"
    echo "  ECWolf supports co-op and deathmatch (up to 11 players),"
    echo "  LAN-focused: one player hosts with 'ecwolf --host 2' from the"
    echo "  Terminal, the others run 'ecwolf --join <host-ip>'."
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
