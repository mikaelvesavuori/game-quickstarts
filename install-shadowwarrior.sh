#!/bin/bash
set -euo pipefail

# Raze 1.11.0 (Build engine port from the GZDoom team; Universal 2,
# Apple Silicon + Intel) — the same pinned release used for Duke Nukem 3D.
RAZE_VERSION="1.11.0"
ENGINE_URL="https://github.com/ZDoom/Raze/releases/download/${RAZE_VERSION}/raze-macos-${RAZE_VERSION}.zip"
ENGINE_FILE="raze-macos-${RAZE_VERSION}.zip"
ENGINE_SHA256="b7980849a507cfcfeaf8f76298c032bfe4415b2f246f41e3c0c9a6291770c70c"

# Shadow Warrior was released as freeware in 2016 ("Shadow Warrior Classic
# Complete", GOG). This is a mirror of the official GOG Linux package from
# archive.org - it contains the complete registered game (v1.2) as plain
# files plus the official soundtrack, no install machinery needed beyond
# unzip (the GOG Linux .sh is a zip archive with a small stub prepended).
GAME_URL="https://archive.org/download/shadow-warrior-classic-complete/linux%20-%20gog%20-%20gog_shadow_warrior_classic_complete_2.0.0.4.zip"
GAME_FILE="gog_shadow_warrior_classic_complete.zip"
GAME_SHA256="36898c687694c9249213bd3690874cbd34338c778cc836e6ced88a23877463db"

# Registered v1.2 GRP checksum - double-checks the extracted game data.
GRP_SHA1="4863226c01d0850c65ac0a3e20831e072b285425"

INSTALL_DIR="/Applications/ShadowWarrior"
ENGINE_APP_PATH="$INSTALL_DIR/Raze.app"
LAUNCHER_APP_PATH="$INSTALL_DIR/Shadow Warrior.app"

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

# unzip exits 1 for harmless warnings (the GOG Linux installer is a zip
# with a 787KB stub prepended, so every extract emits one); treat 0 and 1
# as success, anything higher as failure.
run_unzip() {
    local rc=0
    unzip "$@" >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -gt 1 ]]; then
        echo "Error: unzip failed (exit code $rc)."
        return 1
    fi
    return 0
}

preflight() {
    echo "=== Shadow Warrior (1997) Quickstart Installer ==="
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
    echo "  1. Install Raze v${RAZE_VERSION} (Universal 2, Apple Silicon + Intel)"
    echo "     to $INSTALL_DIR"
    echo "  2. Download the complete registered Shadow Warrior game"
    echo "     (v1.2) + official soundtrack (~258MB, SHA256-verified)"
    echo "     - freeware since 2016; mirrored from the official GOG"
    echo "       Linux package on archive.org"
    echo "  3. Create a launcher app so the game is ready to play immediately"
    echo ""
    echo "Shadow Warrior is fully free - 3D Realms' Build-engine FPS was"
    echo "released as freeware in 2016, together with its expansions."
    echo "Raze plays the main campaign and Wanton Destruction, with"
    echo "in-engine music plus the CD soundtrack."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
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
    run_unzip -q -o "$TEMP_DIR/$ENGINE_FILE" -d "$TEMP_DIR/raze"
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

install_game_data() {
    echo ""
    echo "=== Step 2: Downloading Shadow Warrior game data ==="

    if [[ -f "$INSTALL_DIR/Sw.grp" ]]; then
        echo "  Game data already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
        rm -rf "$INSTALL_DIR/Sw.grp" "$INSTALL_DIR/Sw.rts" "$INSTALL_DIR/WT.GRP" "$INSTALL_DIR"/shadow??.ogg
    fi

    echo "  Downloading GOG Linux package (~258MB) from archive.org..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$GAME_FILE" "$GAME_URL"
    verify_sha256 "$TEMP_DIR/$GAME_FILE" "$GAME_SHA256"

    echo "  Extracting the self-extracting installer..."
    run_unzip -j -o "$TEMP_DIR/$GAME_FILE" -d "$TEMP_DIR/gog"
    local installer="$TEMP_DIR/gog/gog_shadow_warrior_classic_complete_2.0.0.4.sh"
    if [[ ! -f "$installer" ]]; then
        echo "Error: GOG installer not found inside the package."
        return 1
    fi

    echo "  Extracting game data (main GRP, RTS, expansion and soundtrack)..."
    run_unzip -j -o "$installer" \
        "data/noarch/data/Sw.grp" "data/noarch/data/Sw.rts" "data/noarch/data/WT.GRP" "data/noarch/data/MUSIC/Track*.ogg" \
        -d "$TEMP_DIR/swdata"
    if [[ ! -f "$TEMP_DIR/swdata/Sw.grp" ]]; then
        echo "Error: Sw.grp not found in the GOG package."
        return 1
    fi
    verify_sha1 "$TEMP_DIR/swdata/Sw.grp" "$GRP_SHA1"

    echo "  Installing game data into $INSTALL_DIR..."
    cp "$TEMP_DIR/swdata/Sw.grp" "$TEMP_DIR/swdata/Sw.rts" "$INSTALL_DIR/"

    # Wanton Destruction - supported natively by Raze; if present in the
    # package, install it too and Raze offers it at startup.
    if [[ -f "$TEMP_DIR/swdata/WT.GRP" ]]; then
        cp "$TEMP_DIR/swdata/WT.GRP" "$INSTALL_DIR/"
        echo "  Wanton Destruction expansion installed."
    fi

    # Raze finds CD soundtrack re-rips next to the game files, named
    # after the game (shadowXX.ogg, where XX is the CD track number).
    local track_num
    for f in "$TEMP_DIR/swdata"/Track[0-9][0-9].ogg; do
        [[ -f "$f" ]] || continue
        track_num="${f##*/Track}"
        cp "$f" "$INSTALL_DIR/shadow${track_num}"
    done

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
    cat > "$launcher_contents/MacOS/Shadow Warrior" <<'LAUNCHER_EOF'
#!/bin/bash
cd "$(dirname "$0")/../../.." || exit 1
exec "./Raze.app/Contents/MacOS/Raze" "$@"
LAUNCHER_EOF
    chmod +x "$launcher_contents/MacOS/Shadow Warrior"

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
    <string>Shadow Warrior</string>
    <key>CFBundleDisplayName</key>
    <string>Shadow Warrior</string>
    <key>CFBundleIdentifier</key>
    <string>com.mikaelvesavuori.game-quickstarts.shadowwarrior-launcher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Shadow Warrior</string>
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

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Shadow Warrior (full registered v1.2 game) is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open '$LAUNCHER_APP_PATH'"
    echo ""
    echo "Notes:"
    echo "  - The Wanton Destruction expansion is installed too - Raze"
    echo "    offers it alongside the main campaign at startup."
    echo "    (Twin Dragon also ships in the GOG package, but as loose DOS"
    echo "    files Raze cannot load; a future GRP may add it.)"
    echo "  - The CD soundtrack is installed (shadow02.ogg - shadow14.ogg)."
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
    finish
}

main "$@"
