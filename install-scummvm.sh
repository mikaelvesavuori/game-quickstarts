#!/bin/bash
set -euo pipefail

# ScummVM 2026.4.0, the official macOS release (Universal 2:
# Apple Silicon + Intel, signed and notarized). Prior to the 2.9.0
# release, ScummVM switched to calendar-based version numbers.
SCUMMVM_VERSION="2026.4.0"
ENGINE_URL="https://downloads.scummvm.org/frs/scummvm/${SCUMMVM_VERSION}/scummvm-${SCUMMVM_VERSION}-macosx.dmg"
ENGINE_DMG="scummvm-${SCUMMVM_VERSION}-macosx.dmg"
ENGINE_SHA256="5614527fa57ffce14773c69923b96eeb7b1b135bcd96bfe74640ca341cad4598"

# Three complete adventure games, all released as freeware by their
# creators and distributed by the ScummVM project itself:
#   - Beneath a Steel Sky (1994, Revolution Software) — CD version, full speech
#   - Flight of the Amazon Queen (1995, Interactive Binary Illusions) — CD version
#   - Lure of the Temptress (1991, Revolution Software)
BASS_URL="https://downloads.scummvm.org/frs/extras/Beneath%20a%20Steel%20Sky/bass-cd-1.2.zip"
BASS_SHA256="53209b9400eab6fd7fa71518b2f357c8de75cfeaa5ba57024575ab79cc974593"
# The ZIP nests everything inside this directory:
BASS_INNER_DIR="bass-cd-1.2"

FOTAQ_URL="https://downloads.scummvm.org/frs/extras/Flight%20of%20the%20Amazon%20Queen/FOTAQ_Talkie-original.zip"
FOTAQ_SHA256="a298e68243f18a741d4816ef636a5a77a1593816fb2c9e23a09124c35a95dfec"
# FOTAQ ships the game files (queen.1 etc.) at the ZIP root — no inner dir.
FOTAQ_INNER_DIR=""

LURE_URL="https://downloads.scummvm.org/frs/extras/Lure%20of%20the%20Temptress/lure-1.1.zip"
LURE_SHA256="f3178245a1483da1168c3a11e70b65d33c389f1f5df63d4f3a356886c1890108"
LURE_INNER_DIR="lure"

INSTALL_DIR="/Applications/ScummVM"
APP_PATH="$INSTALL_DIR/ScummVM.app"
SCUMMVM_BIN="$APP_PATH/Contents/MacOS/scummvm"
GAMES_DIR="$INSTALL_DIR/games"

# ScummVM target/game IDs used to register and launch each game.
BASS_TARGET="sky"
FOTAQ_TARGET="queen"
LURE_TARGET="lure"

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
    echo "=== ScummVM Classic Adventures Quickstart Installer ==="
    echo "(Beneath a Steel Sky, Flight of the Amazon Queen, Lure of the Temptress)"
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
    local required_kb=786432
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 768MB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Install ScummVM v${SCUMMVM_VERSION} (Universal 2, Apple"
    echo "     Silicon + Intel) to /Applications/ScummVM"
    echo "  2. Download three complete adventure games (~179MB total,"
    echo "     SHA256-verified) from the ScummVM project's own server:"
    echo "       - Beneath a Steel Sky (1994) — CD version, full speech"
    echo "       - Flight of the Amazon Queen (1995) — CD version"
    echo "       - Lure of the Temptress (1991)"
    echo "  3. Register them with ScummVM and create a launcher app for"
    echo "     each, so each game is ready to play immediately"
    echo ""
    echo "All three games were released as freeware by their creators"
    echo "(Revolution Software / Interactive Binary Illusions) and are"
    echo "distributed by the ScummVM project itself."
    echo ""
    echo "ScummVM runs hundreds of other classic adventures — for the other"
    echo "freeware titles see: https://www.scummvm.org/games/"
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing ScummVM v${SCUMMVM_VERSION} ==="

    if [[ -d "$INSTALL_DIR" ]]; then
        echo "  $INSTALL_DIR already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing installation? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing installation."
                return 0
            fi
        fi
        rm -rf "$INSTALL_DIR"
    fi

    mkdir -p "$INSTALL_DIR"

    echo "  Downloading ScummVM DMG (~161MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_DMG" "$ENGINE_URL"
    verify_sha256 "$TEMP_DIR/$ENGINE_DMG" "$ENGINE_SHA256"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$ENGINE_DMG" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    if [[ ! -d "$DMG_MOUNT/ScummVM.app" ]]; then
        echo "Error: ScummVM.app not found in DMG."
        return 1
    fi

    echo "  Copying ScummVM.app to /Applications..."
    if ! cp -R "$DMG_MOUNT/ScummVM.app" "$INSTALL_DIR/"; then
        echo "Error: Failed to copy to $INSTALL_DIR."
        return 1
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  ScummVM installed."
}

# Download one game archive and extract its files into $GAMES_DIR/<game>/.
download_game() {
    local id="$1"
    local url="$2"
    local sha256="$3"
    local inner_dir="${4:-}"

    if [[ -d "$GAMES_DIR/$id" ]]; then
        echo "  ${id}: already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
        rm -rf "$GAMES_DIR/$id"
    fi

    mkdir -p "$GAMES_DIR/$id"

    local zip_file="$TEMP_DIR/${id}.zip"
    curl -f -L --progress-bar -o "$zip_file" "$url"
    verify_sha256 "$zip_file" "$sha256"

    unzip -q -o "$zip_file" -d "$TEMP_DIR/${id}_x"

    if [[ -n "$inner_dir" ]]; then
        if [[ ! -d "$TEMP_DIR/${id}_x/$inner_dir" ]]; then
            echo "Error: directory '$inner_dir' not found inside ${id} archive."
            return 1
        fi
        cp -R "$TEMP_DIR/${id}_x/$inner_dir/." "$GAMES_DIR/$id/"
    else
        cp -R "$TEMP_DIR/${id}_x/." "$GAMES_DIR/$id/"
    fi

    echo "  ${id} installed."
}

install_game_data() {
    echo ""
    echo "=== Step 2: Downloading adventure games ==="

    mkdir -p "$GAMES_DIR"

    echo "  Beneath a Steel Sky (CD version, ~66MB)..."
    download_game "bass" "$BASS_URL" "$BASS_SHA256" "$BASS_INNER_DIR"

    echo ""
    echo "  Flight of the Amazon Queen (CD version, ~107MB)..."
    download_game "fotaq" "$FOTAQ_URL" "$FOTAQ_SHA256" "$FOTAQ_INNER_DIR"

    echo ""
    echo "  Lure of the Temptress (~5MB)..."
    download_game "lure" "$LURE_URL" "$LURE_SHA256" "$LURE_INNER_DIR"

    echo ""
    echo "  Game data installed."
}

register_games() {
    echo ""
    echo "=== Step 3: Registering games with ScummVM ==="

    echo "  Adding games from $GAMES_DIR ..."
    "$SCUMMVM_BIN" --add --path="$GAMES_DIR" --recursive

    # Verify all three targets were detected and stored in the config.
    local targets
    targets=$("$SCUMMVM_BIN" --list-targets 2>/dev/null || true)
    for target in "$BASS_TARGET" "$FOTAQ_TARGET" "$LURE_TARGET"; do
        if ! echo "$targets" | grep -q "^${target}[[:space:]]"; then
            echo "Error: game target '${target}' was not detected."
            echo "  Expected one of the installed games to register as '${target}'."
            return 1
        fi
    done

    echo "  All games registered."
}

# Create a launcher app per game (same pattern as the Duke Nukem 3D
# installer) so each adventure starts directly from Finder/Spotlight.
create_launcher() {
    local name="$1"
    local target="$2"
    local app_path="$INSTALL_DIR/${name}.app"

    rm -rf "$app_path"

    local contents="$app_path/Contents"
    mkdir -p "$contents/MacOS" "$contents/Resources"

    cat > "$contents/MacOS/$name" <<LAUNCHER_EOF
#!/bin/bash
exec "${SCUMMVM_BIN}" "${target}" "\$@"
LAUNCHER_EOF
    chmod +x "$contents/MacOS/$name"

    # Reuse ScummVM's own icon if available
    for icns in "$APP_PATH/Contents/Resources/"*.icns; do
        if [[ -f "$icns" ]]; then
            cp "$icns" "$contents/Resources/AppIcon.icns"
            break
        fi
    done

    cat > "$contents/Info.plist" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${name}</string>
    <key>CFBundleDisplayName</key>
    <string>${name}</string>
    <key>CFBundleIdentifier</key>
    <string>com.mikaelvesavuori.game-quickstarts.scummvm-${target}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>${name}</string>
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

    xattr -dr com.apple.quarantine "$app_path" 2>/dev/null || true

    echo "  Launcher created: ${name}.app"
}

create_launchers() {
    echo ""
    echo "=== Step 4: Creating launcher apps ==="

    create_launcher "Beneath a Steel Sky" "$BASS_TARGET"
    create_launcher "Flight of the Amazon Queen" "$FOTAQ_TARGET"
    create_launcher "Lure of the Temptress" "$LURE_TARGET"
}

print_more_games() {
    echo ""
    echo "=== More freeware adventures ==="
    echo ""
    echo "ScummVM runs hundreds of classic adventures. The ScummVM project"
    echo "also distributes more complete freeware games, e.g. Drascula,"
    echo "DreamWeb, Broken Sword 2.5, Soltys and Sfinx:"
    echo "  https://www.scummvm.org/games/"
    echo ""
    echo "Download one, then add it via the ScummVM launcher:"
    echo "'Add Game...' -> select the extracted folder -> done."
    echo ""
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Three classic adventures are ready to play!"
    echo ""
    echo "Launch each game directly with:"
    echo "  open '$INSTALL_DIR/Beneath a Steel Sky.app'"
    echo "  open '$INSTALL_DIR/Flight of the Amazon Queen.app'"
    echo "  open '$INSTALL_DIR/Lure of the Temptress.app'"
    echo ""
    echo "Or open the ScummVM launcher and pick any installed game:"
    echo "  open '$APP_PATH'"
    echo ""
    echo "Game data lives in: $GAMES_DIR"
    echo "Saved games live in: ~/Documents/ScummVM Savegames"
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
    register_games
    create_launchers
    print_more_games
    finish
}

main "$@"
