#!/bin/bash
set -euo pipefail

# GZDoom g4.14.2 — official macOS release (Universal 2: Apple Silicon + Intel),
# from the GZDoom team. Signed with a self-signed certificate, so the script
# removes the quarantine attribute after install.
GZDOOM_VERSION="4.14.2"
ENGINE_URL="https://github.com/ZDoom/gzdoom/releases/download/g${GZDOOM_VERSION}/gzdoom-4-14-2-macos.zip"
ENGINE_FILE="gzdoom-4-14-2-macos.zip"
ENGINE_SHA256="0f2e638574ce2a2b5adec3613cf3fc1c66f63468019d412bb8dc8787ee78fb05"

# Freedoom 0.13.0 — complete, freely licensed id Tech 1 games distributed by
# the Freedoom project itself. Phase 1 replaces DOOM.WAD (Ultimate Doom-style),
# Phase 2 replaces DOOM2.WAD (Doom II-style, 32 levels). Both WADs are fully
# standalone — no original Doom files needed.
FREEDOOM_VERSION="0.13.0"
FREEDOOM_URL="https://github.com/freedoom/freedoom/releases/download/v${FREEDOOM_VERSION}/freedoom-${FREEDOOM_VERSION}.zip"
FREEDOOM_FILE="freedoom-${FREEDOOM_VERSION}.zip"
FREEDOOM_SHA256="3f9b264f3e3ce503b4fb7f6bdcb1f419d93c7b546f4df3e874dd878db9688f59"

INSTALL_DIR="/Applications/Doom"
ENGINE_APP_PATH="$INSTALL_DIR/GZDoom.app"
LAUNCHER1_APP_PATH="$INSTALL_DIR/Doom (Freedoom).app"
LAUNCHER2_APP_PATH="$INSTALL_DIR/Doom II (Freedoom).app"

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

preflight() {
    echo "=== Doom via Freedoom (1993) Quickstart Installer ==="
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
    local required_kb=512000
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 500MB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Install GZDoom v${GZDOOM_VERSION} (Universal 2, Apple Silicon + Intel)"
    echo "     to $INSTALL_DIR"
    echo "  2. Download Freedoom v${FREEDOOM_VERSION} (~24MB) — two complete"
    echo "     free games: Phase 1 (Ultimate Doom-style) and Phase 2 (Doom II-style)"
    echo "     (SHA256-verified, from the Freedoom project's own releases)"
    echo "  3. Create launcher apps for both games"
    echo ""
    echo "Freedoom is a complete, freely licensed game that runs on the Doom"
    echo "engine — no purchase or original files are needed. If you own Doom"
    echo "or Doom II, their WAD files can be used instead (see the notes"
    echo "printed at the end of this installation)."
    echo ""
    echo "GZDoom is the maintained Doom-family engine from the ZDoom team."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing GZDoom v${GZDOOM_VERSION} ==="

    if [[ -d "$ENGINE_APP_PATH" ]]; then
        echo "  GZDoom.app already exists."
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

    echo "  Downloading GZDoom (~36MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_URL"
    verify_sha256 "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_SHA256"

    echo "  Unpacking..."
    unzip -q -o "$TEMP_DIR/$ENGINE_FILE" -d "$TEMP_DIR/gzdoom"
    if [[ ! -d "$TEMP_DIR/gzdoom/GZDoom.app" ]]; then
        echo "Error: GZDoom.app not found in archive."
        return 1
    fi

    echo "  Copying GZDoom.app to $INSTALL_DIR..."
    cp -R "$TEMP_DIR/gzdoom/GZDoom.app" "$INSTALL_DIR/"

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$ENGINE_APP_PATH" 2>/dev/null || true

    echo "  Engine installed."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Downloading Freedoom v${FREEDOOM_VERSION} ==="

    if [[ -f "$INSTALL_DIR/freedoom2.wad" ]]; then
        echo "  Freedoom WADs already exist."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
        rm -f "$INSTALL_DIR/freedoom1.wad" "$INSTALL_DIR/freedoom2.wad"
    fi

    echo "  Downloading Freedoom (~24MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$FREEDOOM_FILE" "$FREEDOOM_URL"
    verify_sha256 "$TEMP_DIR/$FREEDOOM_FILE" "$FREEDOOM_SHA256"

    echo "  Unpacking..."
    unzip -q -o "$TEMP_DIR/$FREEDOOM_FILE" -d "$TEMP_DIR/freedoom"

    echo "  Installing game data into $INSTALL_DIR..."
    cp "$TEMP_DIR/freedoom/freedoom-${FREEDOOM_VERSION}/freedoom1.wad" "$INSTALL_DIR/"
    cp "$TEMP_DIR/freedoom/freedoom-${FREEDOOM_VERSION}/freedoom2.wad" "$INSTALL_DIR/"

    if [[ ! -f "$INSTALL_DIR/freedoom1.wad" || ! -f "$INSTALL_DIR/freedoom2.wad" ]]; then
        echo "Error: Freedoom WADs not found after extraction."
        return 1
    fi
    echo "  Game data installed."
}

create_launcher() {
    # $1: launcher app path, $2: display name, $3: IWAD file, $4: bundle suffix
    local app_path="$1"
    local display_name="$2"
    local iwad="$3"
    local suffix="$4"

    rm -rf "$app_path"

    local launcher_contents="$app_path/Contents"
    mkdir -p "$launcher_contents/MacOS" "$launcher_contents/Resources"

    # GZDoom finds game data in the current working directory. The launcher
    # app cd's to the installation folder before starting GZDoom, so the
    # game works when launched from Finder, Spotlight or `open`.
    cat > "$launcher_contents/MacOS/$display_name" <<LAUNCHER_EOF
#!/bin/bash
cd "\$(dirname "\$0")/../../.." || exit 1
exec "./GZDoom.app/Contents/MacOS/gzdoom" -iwad "$iwad" "\$@"
LAUNCHER_EOF
    chmod +x "$launcher_contents/MacOS/$display_name"

    # Reuse GZDoom's own icon if available
    for icns in "$ENGINE_APP_PATH/Contents/Resources/"*.icns; do
        if [[ -f "$icns" ]]; then
            cp "$icns" "$launcher_contents/Resources/AppIcon.icns"
            break
        fi
    done

    cat > "$launcher_contents/Info.plist" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$display_name</string>
    <key>CFBundleDisplayName</key>
    <string>$display_name</string>
    <key>CFBundleIdentifier</key>
    <string>com.mikaelvesavuori.game-quickstarts.$suffix</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$display_name</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

    xattr -dr com.apple.quarantine "$app_path" 2>/dev/null || true

    echo "  Launcher created: $app_path"
}

create_launchers() {
    echo ""
    echo "=== Step 3: Creating launcher apps ==="
    create_launcher "$LAUNCHER1_APP_PATH" "Doom (Freedoom)" "freedoom1.wad" "freedoom1-launcher"
    create_launcher "$LAUNCHER2_APP_PATH" "Doom II (Freedoom)" "freedoom2.wad" "freedoom2-launcher"
}

print_upgrade_instructions() {
    echo ""
    echo "=== Using Your Own Doom Copies (Optional) ==="
    echo ""
    echo "Freedoom is fully playable on its own — nothing else is needed."
    echo "If you own the originals, you can use your WAD files instead:"
    echo ""
    echo "  1. Copy DOOM.WAD / DOOM2.WAD (or the whole IWAD set) into:"
    echo "       $INSTALL_DIR"
    echo ""
    echo "  2. Launch GZDoom.app directly — it shows an IWAD picker with every"
    echo "     game it finds, including the Freedoom and original WADs:"
    echo "       open '$ENGINE_APP_PATH'"
    echo ""
    echo "  (The launchers always start Freedoom; GZDoom.app itself lets you"
    echo "   pick any installed IWAD each time you play.)"
    echo ""
    echo "  FreeDM — a free deathmatch-only WAD (also from the Freedoom"
    echo "  project) — can be downloaded from freedoom.github.io and played"
    echo "  the same way."
    echo ""
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Doom via Freedoom is ready to play!"
    echo ""
    echo "Launch the games with:"
    echo "  open '$LAUNCHER1_APP_PATH'   # Phase 1 (Ultimate Doom-style)"
    echo "  open '$LAUNCHER2_APP_PATH'   # Phase 2 (Doom II-style)"
    echo ""
    echo "Settings and saved games live in:"
    echo "  ~/Library/Application Support/GZDoom"
    echo ""
    echo "Playing with friends:"
    echo "  GZDoom supports direct-connection multiplayer from the in-game"
    echo "  menu - one player hosts, the others join their address."
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
    create_launchers
    print_upgrade_instructions
    finish
}

main "$@"
