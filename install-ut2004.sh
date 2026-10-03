#!/bin/bash
set -euo pipefail

PATCH_TAG="3374-preview-23"
PATCH_DMG_URL="https://github.com/OldUnreal/UT2004Patches/releases/download/${PATCH_TAG}/OldUnreal-UT2004Patch3374-macOS.dmg"
PATCH_DMG_FILE="OldUnreal-UT2004Patch3374-macOS.dmg"

UNSHIELD_URL="https://github.com/OldUnreal/FullGameInstallers/releases/download/macos-installers-1/OldUnreal-UT2004Installer-macOS.zip"
UNSHIELD_FILE="OldUnreal-UT2004Installer-macOS.zip"

ISO_FILE="UT2004.iso"
ISO_SHA256="43e9182ae20bcbc0f6f4588fee6c1b336c261f1465403118a1973b09b1a22541"
ISO_URLS=(
    "https://files.oldunreal.net/UT2004.ISO"
    "https://files2.oldunreal.net/UT2004.ISO"
    "https://files3.oldunreal.net/UT2004.ISO"
)

ASSETS_DIR="$HOME/Library/Application Support/UT2004"
APP_PATH="/Applications/UT2004.app"

TEMP_DIR=""
ISO_MOUNT=""
DMG_MOUNT=""
AUTO_YES=false

cleanup() {
    local exit_code=$?
    if [[ -n "${ISO_MOUNT:-}" ]]; then
        hdiutil detach "$ISO_MOUNT" -force -quiet 2>/dev/null || true
    fi
    if [[ -n "${DMG_MOUNT:-}" ]]; then
        hdiutil detach "$DMG_MOUNT" -force -quiet 2>/dev/null || true
    fi
    if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "${TEMP_DIR:-}" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    exit $exit_code
}
trap cleanup EXIT

download_with_fallback() {
    local output="$1"
    shift
    local urls=("$@")
    for url in "${urls[@]}"; do
        echo "  Trying: $url"
        if curl -f -L --progress-bar --connect-timeout 30 -o "$output" "$url"; then
            return 0
        fi
        echo "  Failed, trying next mirror..."
    done
    echo "Error: All download mirrors failed."
    return 1
}

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
    echo "=== Unreal Tournament 2004 Quickstart Installer ==="
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
    echo "Note: The UT2004 patch (v3374) is currently a preview release."
    echo "      It is fully playable but not yet marked as stable."
    echo ""

    for cmd in curl hdiutil shasum unzip; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command not found: $cmd"
            exit 1
        fi
    done

    local free_kb
    free_kb=$(df -k / | awk 'NR==2 {print $4}')
    local required_kb=6291456
    if [[ "$free_kb" -lt "$required_kb" ]]; then
        echo "Error: Insufficient disk space. Need at least 6GB free."
        echo "  Available: $((free_kb / 1024))MB"
        exit 1
    fi
}

confirm() {
    echo "This script will:"
    echo "  1. Install the OldUnreal UT2004 patch (v3374 preview) to /Applications"
    echo "  2. Download the UT2004 DVD ISO (~2.8GB) with SHA256 verification"
    echo "  3. Extract game data from the ISO's installer CAB files"
    echo "  4. Copy maps, textures, sounds, music, and more to the game data folder"
    echo ""
    echo "Note: Bonus packs (CBP1, CBP2, ECE) are included in the DVD ISO."
    echo ""
    echo "Game data location: $ASSETS_DIR"
    echo ""

    if [[ "$AUTO_YES" == false ]]; then
        read -r -p "Press Enter to continue, or Ctrl+C to cancel..." </dev/tty
    fi
}

install_patch() {
    echo ""
    echo "=== Step 1: Installing OldUnreal UT2004 Patch v3374 ==="

    if [[ -d "$APP_PATH" ]]; then
        echo "  UT2004.app already exists."
        if [[ "$AUTO_YES" == false ]]; then
            read -r -p "  Overwrite existing installation? (y/N) " response </dev/tty
            if [[ "${response:-N}" != [Yy]* ]]; then
                echo "  Keeping existing installation."
                return 0
            fi
        fi
        rm -rf "$APP_PATH"
    fi

    echo "  Downloading patch..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$PATCH_DMG_FILE" "$PATCH_DMG_URL"

    DMG_MOUNT="$TEMP_DIR/dmg_mount"
    mkdir -p "$DMG_MOUNT"
    echo "  Mounting DMG..."
    hdiutil attach "$TEMP_DIR/$PATCH_DMG_FILE" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

    local app_found=""
    for app in "$DMG_MOUNT"/*.app; do
        if [[ -d "$app" ]]; then
            app_found=$(basename "$app")
            break
        fi
    done

    if [[ -z "$app_found" ]]; then
        echo "Error: No .app bundle found in DMG."
        hdiutil detach "$DMG_MOUNT" -quiet 2>/dev/null || true
        DMG_MOUNT=""
        return 1
    fi

    echo "  Copying $app_found to /Applications..."
    if ! cp -R "$DMG_MOUNT/$app_found" /Applications/; then
        echo "Error: Failed to copy to /Applications."
        return 1
    fi

    hdiutil detach "$DMG_MOUNT" -quiet
    DMG_MOUNT=""

    echo "  Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

    echo "  Patch installed."
}

download_unshield() {
    echo ""
    echo "=== Step 2: Downloading extraction tool (unshield) ==="

    echo "  Downloading UT2004 installer package..."
    curl -f -L --progress-bar -o "$TEMP_DIR/$UNSHIELD_FILE" "$UNSHIELD_URL"

    echo "  Extracting unshield binary..."
    unzip -q "$TEMP_DIR/$UNSHIELD_FILE" -d "$TEMP_DIR/unshield_pkg"

    local unshield_path="$TEMP_DIR/unshield_pkg/UT2004Installer.app/Contents/MacOS/unshield"
    if [[ ! -f "$unshield_path" ]]; then
        echo "Error: unshield binary not found in downloaded package."
        return 1
    fi

    chmod +x "$unshield_path"
    echo "  unshield ready."
}

extract_game_data() {
    echo ""
    echo "=== Step 3: Downloading UT2004 DVD ISO ==="

    echo "  Downloading ISO (~2.8GB)..."
    download_with_fallback "$TEMP_DIR/$ISO_FILE" "${ISO_URLS[@]}"
    verify_sha256 "$TEMP_DIR/$ISO_FILE" "$ISO_SHA256"

    ISO_MOUNT="$TEMP_DIR/iso_mount"
    mkdir -p "$ISO_MOUNT"
    echo "  Mounting ISO..."
    hdiutil attach "$TEMP_DIR/$ISO_FILE" -mountpoint "$ISO_MOUNT" -nobrowse -readonly -quiet

    local cab_dir="$TEMP_DIR/cabs"
    mkdir -p "$cab_dir"

    echo ""
    echo "=== Step 4: Copying CAB files from ISO ==="
    local disk_count=0
    for disk_dir in "$ISO_MOUNT"/Disk*; do
        [[ -d "$disk_dir" ]] || continue
        disk_count=$((disk_count + 1))
        local disk_name
        disk_name=$(basename "$disk_dir")
        echo "  Copying from $disk_name..."
        cp "$disk_dir"/*.cab "$disk_dir"/*.hdr "$cab_dir/" 2>/dev/null || true
    done

    if [[ $disk_count -eq 0 ]]; then
        echo "Error: No Disk directories found in ISO."
        return 1
    fi

    echo "  Unmounting ISO (freeing disk space)..."
    hdiutil detach "$ISO_MOUNT" -quiet
    ISO_MOUNT=""

    echo ""
    echo "=== Step 5: Extracting game data from CAB files ==="
    local unshield_path="$TEMP_DIR/unshield_pkg/UT2004Installer.app/Contents/MacOS/unshield"

    cd "$cab_dir"
    echo "  Running unshield (this may take a few minutes)..."
    if ! "$unshield_path" x data1.hdr >/dev/null 2>&1; then
        echo "Error: CAB extraction failed."
        return 1
    fi
    cd - >/dev/null

    echo "  Extraction complete."
}

install_game_data() {
    echo ""
    echo "=== Step 6: Installing game data ==="

    mkdir -p "$ASSETS_DIR"

    local cab_dir="$TEMP_DIR/cabs"

    local -A group_map=(
        ["All_Animations"]="Animations"
        ["All_Benchmark"]="Benchmark"
        ["All_ForceFeedback"]="ForceFeedback"
        ["All_Help"]="Help"
        ["All_KarmaData"]="KarmaData"
        ["All_Maps"]="Maps"
        ["All_Music"]="Music"
        ["All_StaticMeshes"]="StaticMeshes"
        ["All_Textures"]="Textures"
        ["All_Web"]="Web"
    )

    for group in "${!group_map[@]}"; do
        local target="${group_map[$group]}"
        if [[ -d "$cab_dir/$group" ]]; then
            echo "  Copying $target..."
            mkdir -p "$ASSETS_DIR/$target"
            cp -R "$cab_dir/$group/"* "$ASSETS_DIR/$target/" 2>/dev/null || true
            chmod -R u+w "$ASSETS_DIR/$target" 2>/dev/null || true
        fi
    done

    if [[ -d "$cab_dir/English_Sounds_Speech_System_Help" ]]; then
        local ess_dir="$cab_dir/English_Sounds_Speech_System_Help"
        for subdir in Sounds Speech; do
            if [[ -d "$ess_dir/$subdir" ]]; then
                echo "  Copying $subdir..."
                mkdir -p "$ASSETS_DIR/$subdir"
                cp -R "$ess_dir/$subdir/"* "$ASSETS_DIR/$subdir/" 2>/dev/null || true
                chmod -R u+w "$ASSETS_DIR/$subdir" 2>/dev/null || true
            fi
        done
    fi

    echo "  Finding stray .uax files..."
    find "$cab_dir" -iname "*.uax" -not -path "*/Sounds/*" 2>/dev/null | while read -r uax_file; do
        mkdir -p "$ASSETS_DIR/Sounds"
        cp "$uax_file" "$ASSETS_DIR/Sounds/" 2>/dev/null || true
    done

    echo "  Game data installed."
}

finish() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Unreal Tournament 2004 is ready to play!"
    echo ""
    echo "Launch the game with:"
    echo "  open $APP_PATH"
    echo ""
    echo "Or find UT2004.app in your Applications folder / Launchpad."
    echo ""
    echo "Note: Bonus packs (CBP1, CBP2, ECE) are included."
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

    install_patch
    download_unshield
    extract_game_data
    install_game_data
    finish
}

main "$@"
