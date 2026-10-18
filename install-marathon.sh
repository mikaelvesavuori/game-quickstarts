#!/bin/bash
set -euo pipefail

ALEPHONE_RELEASE="release-20260930"
BASE_URL="https://github.com/Aleph-One-Marathon/alephone/releases/download/${ALEPHONE_RELEASE}"

MARATHON_APP="Classic Marathon.app"
MARATHON2_APP="Classic Marathon 2.app"
MARATHON_INFINITY_APP="Classic Marathon Infinity.app"

# Each DMG contains a ready-to-run app with the game data bundled inside it.
# All three games were released as free, redistributable data by Bungie.
DMGS=(
    "Marathon-20260930-Mac.dmg:${MARATHON_APP}:2506bf67ed463f937811114b4811d5c89cbce6ec69cad453c06f885b80279650"
    "Marathon2-20260930-Mac.dmg:${MARATHON2_APP}:b4f651eec05ec9b17b504758dffdd00df90c4253fc1015cfa79488dd8393ee3f"
    "MarathonInfinity-20260930-Mac.dmg:${MARATHON_INFINITY_APP}:5feafec20d974b25f89b515006ba5c6d73e95de1c8f6725b6d4f44b375a8015e"
)

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
    echo "=== Marathon Trilogy Quickstart Installer ==="
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

confirm() {
    echo "This script will:"
    echo "  1. Download the three official Aleph One macOS releases (~128MB),"
    echo "     each with the engine and game data bundled together"
    echo "  2. Verify each download with SHA256"
    echo "  3. Install three apps to /Applications:"
    echo "     - $MARATHON_APP        (Marathon, 1994)"
    echo "     - $MARATHON2_APP     (Marathon 2: Durandal, 1995)"
    echo "     - $MARATHON_INFINITY_APP  (Marathon Infinity, 1996)"
    echo ""
    echo "The entire trilogy was released free and redistributable by Bungie."
    echo "Aleph One is the open source continuation of Bungie's own engine."
    echo ""
    echo "Playing with friends:"
    echo "  Aleph One has a built-in server browser (in-game multiplayer menu),"
    echo "  including full campaign co-op - join straight from the menu."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_one() {
    local dmg_file="$1"
    local app_name="$2"
    local sha256="$3"

    echo "  --- $app_name ---"

    local app_path="/Applications/$app_name"
    if [[ -d "$app_path" ]]; then
        echo "  $app_name already exists in /Applications."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing installation."
                return 0
            fi
        fi
        rm -rf "$app_path"
    fi

    echo "  Downloading ${dmg_file}..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$dmg_file" "$BASE_URL/$dmg_file"
    verify_sha256 "$TEMP_DIR/$dmg_file" "$sha256"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$dmg_file" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    if [[ ! -d "$DMG_MOUNT/$app_name" ]]; then
        echo "Error: $app_name not found in DMG."
        hdiutil detach "$DMG_MOUNT" -quiet 2>/dev/null || true
        DMG_MOUNT=""
        return 1
    fi

    echo "  Copying $app_name to /Applications..."
    if ! cp -R "$DMG_MOUNT/$app_name" /Applications/; then
        echo "Error: Failed to copy $app_name."
        return 1
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$app_path" 2>/dev/null || true
    echo ""
}

install_games() {
    echo ""
    echo "=== Step 1: Installing the Marathon Trilogy ==="
    echo ""

    for entry in "${DMGS[@]}"; do
        local dmg_file="${entry%%:*}"
        local rest="${entry#*:}"
        local app_name="${rest%%:*}"
        local sha256="${rest#*:}"
        install_one "$dmg_file" "$app_name" "$sha256"
    done
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "The Marathon Trilogy is ready to play:"
    echo ""
    echo "  Marathon:"
    echo "    open '/Applications/$MARATHON_APP'"
    echo ""
    echo "  Marathon 2: Durandal:"
    echo "    open '/Applications/$MARATHON2_APP'"
    echo ""
    echo "  Marathon Infinity:"
    echo "    open '/Applications/$MARATHON_INFINITY_APP'"
    echo ""
    echo "Or find all three in your Applications folder."
    echo ""
    echo "Game data (maps, sounds, shapes) is bundled inside each app -"
    echo "no extra downloads or folder picks needed."
    echo ""
    echo "Playing with friends:"
    echo "  Use the in-game multiplayer menu - the built-in metaserver lists"
    echo "  live games, and the full campaigns support co-op."
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

    install_games
    finish
}

main "$@"
