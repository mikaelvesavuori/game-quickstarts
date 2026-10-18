#!/bin/bash
set -euo pipefail

VCMI_VERSION="1.7.5"
STABLE_BASE_URL="https://github.com/vcmi/vcmi/releases/download/${VCMI_VERSION}"
STABLE_ARM_URL="${STABLE_BASE_URL}/VCMI-macOS-arm.dmg"
STABLE_ARM_SHA256="b56b55d0671ae604effb12d0394b74a552f203426cafa165f82488505fb465e3"
STABLE_INTEL_URL="${STABLE_BASE_URL}/VCMI-macOS-intel.dmg"
STABLE_INTEL_SHA256="613f7e9c2d515e10ff1eae77bab236308cf5bd08b68ff3d1b65cb7a16cde0ef6"

# The free demo requires a VCMI 1.8.0 development build: the stable 1.7.5
# crashes on demo data (fixed post-1.7.5; the crash triggers on a partially
# included creature animation that 1.8.0 handles). Update these pins when a
# 1.8.0 stable release ships.
DEMO_ARM_URL="https://builds.vcmi.download/branch/develop/macos-arm/VCMI-branch-develop-cb39556.dmg"
DEMO_ARM_SHA256="77c3ee8ed36fc59631910afc6ff4a3014692e7e281160dc9df79ffb8f4f9a206"
DEMO_INTEL_URL="https://builds.vcmi.download/branch/develop/macos-intel/VCMI-branch-develop-6ea877a.dmg"
DEMO_INTEL_SHA256="6bdd9d89aa7fb33bf139a7d93fa6db504486c5e5337bffa9fbb60516105d8b77"

# Official Mac demo (Complete Edition-based, 2000) - freely distributed demo
MACDEMO_URL="https://classicmacdemos.com/download/heroes-of-might-and-magic-iii/"
MACDEMO_SHA256="3e5f77588f00ca681717aeaed8060d1e400a1774fb6c9787232209d64c007680"

# Heroes III Demo - official VCMI ecosystem mod that adapts demo data (CC BY-SA)
DEMO_SUPPORT_URL="https://github.com/vcmi-mods/demo-support/archive/a1cb0d760cd1e1884d55e1a9d740b8883a6f13e7.zip"
DEMO_SUPPORT_SHA256="c253cd44ba2a89e272cf5a3757b508ee57f3dd2f00a3d2026ffd916ae3769492"
DEMO_SUPPORT_DIRNAME="demo-support-a1cb0d760cd1e1884d55e1a9d740b8883a6f13e7"

INSTALL_DIR="/Applications/HoMM3"
APP_PATH="$INSTALL_DIR/VCMI.app"
VCMIBUILDER="$APP_PATH/Contents/MacOS/vcmibuilder"
DATA_DIR="$HOME/Library/Application Support/vcmi"

TEMP_DIR=""
DMG_MOUNT=""
AUTO_YES=false
USE_DEMO=false

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
    echo "=== Heroes of Might and Magic III Quickstart Installer ==="
    echo ""

    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Error: This script is for macOS only."
        exit 1
    fi

    local arch
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        echo "System: macOS on Apple Silicon (arm64)"
    elif [[ "$arch" == "x86_64" ]]; then
        echo "System: macOS on Intel ($arch)"
    else
        echo "Error: Unsupported architecture: $arch"
        exit 1
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

check_demo_space() {
    local free_kb
    free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local required_kb=1048576
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space for the demo. Need at least 1GB free."
        echo "  Available: $((free_kb / 1024))MB"
        return 1
    fi
}

ensure_unar() {
    if command -v unar &>/dev/null; then
        return 0
    fi
    echo "unar is required to extract the Mac demo (StuffIt archive)."
    if command -v brew &>/dev/null; then
        read -r -p "Install unar via Homebrew? (y/N) " response </dev/tty
        if [[ "${response:-N}" == [Yy]* ]]; then
            brew install unar
        else
            echo "Error: unar is required. Install with: brew install unar"
            return 1
        fi
    else
        echo "Error: unar is required. Install from https://theunarchiver.com/ or use: brew install unar"
        return 1
    fi
}

prompt_game_version() {
    echo ""
    echo "Do you own a legitimate copy of Heroes of Might and Magic III"
    echo "(Complete Edition / Shadow of Death, e.g. from GOG)?"
    read -r -p "  (y/N) " own_response </dev/tty
    if [[ "${own_response:-N}" == [Yy]* ]]; then
        USE_DEMO=false
        echo ""
        echo "  The stable VCMI engine will be installed for your owned copy."
        echo "  VCMI's launcher imports the GOG offline installer directly."
    else
        USE_DEMO=true
        echo ""
        echo "  The 1999-2000 demo will be installed (freely distributable):"
        echo "  - Playable towns: Castle, Dungeon, Necropolis"
        echo "  - The original demo map 'Dead and Buried' + random maps"
        echo "  - Uses a current VCMI development build (demomode is fixed in"
        echo "    VCMI 1.8.0; latest stable 1.7.5 cannot run demo data)."
        echo "  You can upgrade to the full game at any time (instructions"
        echo "  are printed at the end)."
    fi
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_engine() {
    local engine_url=""
    local engine_file=""
    local engine_sha256=""
    local label=""

    if [[ "$USE_DEMO" == true ]]; then
        label="VCMI 1.8.0 development build (demo required)"
        if [[ "$(uname -m)" == "arm64" ]]; then
            engine_url="$DEMO_ARM_URL"
            engine_file="VCMI-demo-arm.dmg"
            engine_sha256="$DEMO_ARM_SHA256"
        else
            engine_url="$DEMO_INTEL_URL"
            engine_file="VCMI-demo-intel.dmg"
            engine_sha256="$DEMO_INTEL_SHA256"
        fi
    else
        label="VCMI v${VCMI_VERSION} (stable)"
        if [[ "$(uname -m)" == "arm64" ]]; then
            engine_url="$STABLE_ARM_URL"
            engine_file="VCMI-macOS-arm.dmg"
            engine_sha256="$STABLE_ARM_SHA256"
        else
            engine_url="$STABLE_INTEL_URL"
            engine_file="VCMI-macOS-intel.dmg"
            engine_sha256="$STABLE_INTEL_SHA256"
        fi
    fi

    echo ""
    echo "=== Step 1: Installing $label ==="

    if [[ -d "$APP_PATH" ]]; then
        echo "  VCMI.app already exists."
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

    echo "  Downloading $engine_file (~36MB)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$engine_file" "$engine_url"
    verify_sha256 "$TEMP_DIR/$engine_file" "$engine_sha256"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$engine_file" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    if [[ ! -d "$DMG_MOUNT/VCMI.app" ]]; then
        echo "Error: VCMI.app not found in DMG."
        hdiutil detach "$DMG_MOUNT" -quiet 2>/dev/null || true
        DMG_MOUNT=""
        return 1
    fi

    echo "  Copying VCMI.app to $INSTALL_DIR..."
    if ! cp -R "$DMG_MOUNT/VCMI.app" "$INSTALL_DIR/"; then
        echo "Error: Failed to copy to $INSTALL_DIR."
        return 1
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  Engine installed."
}

install_demo_data() {
    echo ""
    echo "=== Step 2: Downloading the Mac demo game data ==="

    check_demo_space
    ensure_unar

    if [[ -d "$DATA_DIR/Data" ]]; then
        echo "  Game data already exists in $DATA_DIR."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing game data? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing game data."
                install_demo_mod
                return 0
            fi
        fi
        rm -rf "$DATA_DIR/Data" "$DATA_DIR/Maps"
    fi

    echo "  Downloading the demo (~105MB, StuffIt archive)..."
    curl -f -L --progress-bar -o "$TEMP_DIR/macdemo.sit" "$MACDEMO_URL"
    verify_sha256 "$TEMP_DIR/macdemo.sit" "$MACDEMO_SHA256"

    echo "  Extracting with unar..."
    unar -o "$TEMP_DIR/demo" -q "$TEMP_DIR/macdemo.sit"
    if [[ ! -d "$TEMP_DIR/demo/Heroes III Demo/data" ]]; then
        echo "Error: demo data folder not found in archive."
        return 1
    fi

    mkdir -p "$DATA_DIR"
    echo "  Installing demo Data and Maps into $DATA_DIR..."
    cp -R "$TEMP_DIR/demo/Heroes III Demo/data" "$DATA_DIR/Data"
    cp -R "$TEMP_DIR/demo/Heroes III Demo/maps" "$DATA_DIR/Maps"

    echo "  Demo game data installed."
}

install_demo_mod() {
    echo ""
    echo "=== Step 3: Installing the Heroes III Demo mod ==="

    mkdir -p "$DATA_DIR/Mods"

    echo "  Downloading demo-support mod..."
    curl -f -L --progress-bar -o "$TEMP_DIR/demo-support.zip" "$DEMO_SUPPORT_URL"
    verify_sha256 "$TEMP_DIR/demo-support.zip" "$DEMO_SUPPORT_SHA256"

    rm -rf "$DATA_DIR/Mods/demo-support"
    unzip -q -o "$TEMP_DIR/demo-support.zip" -d "$TEMP_DIR/mod"
    mv "$TEMP_DIR/mod/$DEMO_SUPPORT_DIRNAME" "$DATA_DIR/Mods/demo-support"
    rm -rf "$DATA_DIR/Mods/demo-support/screenshots"

    if [[ -f "$DATA_DIR/config/modSettings.json" ]]; then
        echo ""
        echo "  Existing VCMI settings detected. Enable the mod once in the"
        echo "  launcher: Settings > Mods > enable 'Heroes III Demo'."
    else
        mkdir -p "$DATA_DIR/config"
        cat > "$DATA_DIR/config/modSettings.json" <<'MODSETTINGS_EOF'
{
	"activeMods" : null,
	"activePreset" : "default",
	"presets" : {
		"default" : {
			"mods" : [ "vcmi", "core", "demo-support" ],
			"settings" : { }
		}
	}
}
MODSETTINGS_EOF
        echo "  Mod installed and enabled."
    fi
}

print_data_instructions() {
    echo ""
    echo "=== Step 2: Import your game data ==="
    echo ""
    echo "VCMI is installed, but it needs the game data from an owned copy of"
    echo "Heroes of Might and Magic III: Complete Edition."
    echo ""
    echo "  Option A - GOG offline installer (recommended):"
    echo "    1. Buy HoMM3 Complete Edition on GOG (~\$5 on sale) and download"
    echo "       the offline installer (.exe and any .bin files) from your library"
    echo "    2. Open VCMI (see launch instructions below)"
    echo "    3. In the launcher, choose to install data from the GOG installer"
    echo "       and select the downloaded .exe - VCMI does the rest"
    echo ""
    echo "  Option B - copy from an existing install:"
    echo "    Place the Data, Maps and Mp3 folders from your HoMM3 installation into:"
    echo "      $DATA_DIR"
    echo ""
    echo "  Option C - command line:"
    echo "    \"$VCMIBUILDER\" --gog /path/to/setup_heroes_of_might_and_magic_3.exe \\\\"
    echo "        --dest \"$DATA_DIR\""
    echo "    (requires innoextract: brew install innoextract)"
    echo ""
}

print_demo_upgrade_instructions() {
    echo ""
    echo "=== Upgrading to the Full Game ==="
    echo ""
    echo "The demo includes three towns (Castle, Dungeon, Necropolis), the"
    echo "original demo map 'Dead and Buried', and random map generation."
    echo ""
    echo "To upgrade to the full game:"
    echo ""
    echo "  1. Buy Heroes of Might and Magic III: Complete Edition on GOG (~\$5)"
    echo "  2. Open VCMI and import the GOG offline installer from the launcher"
    echo "  3. IMPORTANT: disable the 'Heroes III Demo' mod first"
    echo "     (Settings > Mods in the launcher) - it must not be active with"
    echo "     full game data"
    echo "  4. Optionally re-run this installer and answer 'y' to the copy"
    echo "     question to switch to the stable engine"
    echo ""
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    if [[ "$USE_DEMO" == true ]]; then
        echo "Heroes of Might and Magic III (Demo) is ready to play!"
        echo ""
        echo "Playable towns: Castle, Dungeon, Necropolis."
        echo "Includes the demo map 'Dead and Buried' and random maps."
        echo ""
        echo "Launch the game with:"
        echo "  open $APP_PATH"
        echo ""
        echo "Note: music support in the demo is partial - some themes are absent."
    else
        echo "VCMI is installed. Import your game data (instructions above), then:"
        echo ""
        echo "Launch the game with:"
        echo "  open $APP_PATH"
    fi
    echo ""
    echo "Opening VCMI.app starts the VCMI launcher, which manages game"
    echo "data, mods and settings."
    echo ""
    echo "Game data location: $DATA_DIR"
    echo ""
    echo "Playing with friends:"
    echo "  VCMI has built-in network multiplayer plus hot-seat."
    echo "  Host or join from the in-game multiplayer menu."
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

    if [[ "$USE_DEMO" == true ]]; then
        install_demo_data
        install_demo_mod
        print_demo_upgrade_instructions
    else
        print_data_instructions
    fi

    finish
}

main "$@"
