#!/bin/bash
set -euo pipefail

# CorsixTH 0.70.1 — official macOS release from the CorsixTH project
# (Universal 2: Apple Silicon + Intel, signed and notarized packagers).
CORSIXTH_VERSION="0.70.1"
ENGINE_URL="https://github.com/CorsixTH/CorsixTH/releases/download/v${CORSIXTH_VERSION}/CorsixTH-${CORSIXTH_VERSION}.dmg"
ENGINE_FILE="CorsixTH-${CORSIXTH_VERSION}.dmg"
ENGINE_SHA256="90910ded3830cda8204cf2958fb49f174f34c9c279eb5fbf43e17a15fd6ef9c8"

# Official Theme Hospital demo, hosted by the CorsixTH project itself.
DEMO_URL="https://th.corsix.org/Demo.zip"
DEMO_FILE="theme-hospital-demo.zip"
DEMO_SHA256="d6b79b6f76e91413ecbf552a397e283e124a223263491cb08f803ae0b660f897"

INSTALL_DIR="/Applications/ThemeHospital"
APP_PATH="$INSTALL_DIR/CorsixTH.app"
DEMO_DATA_DIR="$INSTALL_DIR/ThemeHospitalDemo"
# CorsixTH keeps its config in the XDG location on macOS (~/.config/CorsixTH),
# matching config_finder.lua: $XDG_CONFIG_HOME/CorsixTH or ~/.config/CorsixTH
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/CorsixTH"
CONFIG_FILE="$CONFIG_DIR/config.txt"

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
    echo "=== Theme Hospital (1997) Demo Quickstart Installer ==="
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
    local required_kb=614400
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 600MB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Install CorsixTH v${CORSIXTH_VERSION} (Universal 2, official release)"
    echo "     to $INSTALL_DIR — SHA256-verified"
    echo "  2. Download the official Theme Hospital demo (~13MB) from the"
    echo "     CorsixTH project's own website — SHA256-verified"
    echo "  3. Pre-configure CorsixTH so it finds the demo data and starts"
    echo "     without any first-run folder prompts"
    echo ""
    echo "CorsixTH is the maintained open-source reimplementation of the"
    echo "Bullfrog business sim, from the original CorsixTH author and"
    echo "community. The demo gives the early hospital levels; the full"
    echo "campaign comes from an owned copy (GOG/EA, ~\$6) — see the notes"
    echo "printed at the end of this installation."
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    echo ""
    echo "=== Step 1: Installing CorsixTH v${CORSIXTH_VERSION} ==="

    if [[ -d "$APP_PATH" ]]; then
        echo "  CorsixTH.app already exists."
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

    echo "  Downloading CorsixTH DMG (~98MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_URL"
    verify_sha256 "$TEMP_DIR/$ENGINE_FILE" "$ENGINE_SHA256"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$ENGINE_FILE" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    if [[ ! -d "$DMG_MOUNT/CorsixTH.app" ]]; then
        echo "Error: CorsixTH.app not found in DMG."
        return 1
    fi

    echo "  Copying CorsixTH.app to $INSTALL_DIR..."
    if ! cp -R "$DMG_MOUNT/CorsixTH.app" "$INSTALL_DIR/"; then
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
    echo "=== Step 2: Downloading the Theme Hospital demo ==="

    if [[ -d "$DEMO_DATA_DIR/HOSP" ]]; then
        echo "  Demo data already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                return 0
            fi
        fi
        rm -rf "$DEMO_DATA_DIR"
    fi

    mkdir -p "$DEMO_DATA_DIR"

    echo "  Downloading demo (~13MB) from th.corsix.org..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$DEMO_FILE" "$DEMO_URL"
    verify_sha256 "$TEMP_DIR/$DEMO_FILE" "$DEMO_SHA256"

    echo "  Unpacking..."
    unzip -q -o "$TEMP_DIR/$DEMO_FILE" -d "$DEMO_DATA_DIR"

    if [[ ! -d "$DEMO_DATA_DIR/HOSP" ]]; then
        echo "Error: HOSP data folder not found in demo archive."
        return 1
    fi
    echo "  Game data installed."
}

configure_engine() {
    echo ""
    echo "=== Step 3: Configuring CorsixTH ==="

    mkdir -p "$CONFIG_DIR"
    touch "$CONFIG_FILE"

    # Look for an existing theme_hospital_install setting. The game ships a
    # placeholder ([[X:\ThemeHospital\hospital]]) in its generated config, so
    # an existing value is only kept if it points at a usable folder.
    local current_line=""
    current_line=$(grep -m1 "^theme_hospital_install" "$CONFIG_FILE" || true)

    if [[ -n "$current_line" ]]; then
        local current_path="${current_line#* = }"
        current_path="${current_path#\[\[}"
        current_path="${current_path%\]\]}"
        current_path="${current_path//\\/}"
        if [[ -d "$current_path" ]]; then
            echo "  theme_hospital_install already points at a valid folder:"
            echo "    $current_path"
            echo "  (leaving it alone)"
            return 0
        fi
        echo "  Replacing the unusable data path in the existing config"
        grep -v "^theme_hospital_install" "$CONFIG_FILE" > "$TEMP_DIR/config_new" || true
        mv "$TEMP_DIR/config_new" "$CONFIG_FILE"
    fi

    echo "theme_hospital_install = [[$DEMO_DATA_DIR/HOSP]]" >> "$CONFIG_FILE"
    echo "  Configured CorsixTH to use the demo data ($CONFIG_FILE)"
}

print_upgrade_instructions() {
    echo ""
    echo "=== Upgrading to the Full Game ==="
    echo ""
    echo "The demo includes the first levels. The full campaign comes with"
    echo "an owned copy:"
    echo ""
    echo "  Buy Theme Hospital on GOG (~\$5-6) or from the EA app"
    echo "  (Origin). The GOG offline installer extracts with innoextract"
    echo "  (brew install innoextract), giving a HOSP folder."
    echo ""
    echo "  Point CorsixTH at it by editing:"
    echo "    $CONFIG_FILE"
    echo "  and changing theme_hospital_install to the full game's HOSP"
    echo "  folder, or delete that line and pick the folder when"
    echo "  CorsixTH asks. Saved games keep working either way."
    echo ""
    echo "Note on music: the current Mac build of CorsixTH ships with"
    echo "  MIDI playback (RtMidi) disabled, so the in-game MIDI music"
    echo "  may stay quiet. Sound effects are unaffected."
    echo ""
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Theme Hospital (demo) is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open '$APP_PATH'"
    echo ""
    echo "Saved games live in:"
    echo "  $CONFIG_DIR/Saves"
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
    configure_engine
    print_upgrade_instructions
    finish
}

main "$@"
