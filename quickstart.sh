#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Retro Game Quickstart — menu launcher
#
# Run from the web (interactive menu):
#   curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/quickstart.sh | bash
#
# Pick a game directly (number 1-24):
#   curl -fsSL .../quickstart.sh | bash -s -- 3
#
# Forward flags to the chosen installer (e.g. unattended mode):
#   curl -fsSL .../quickstart.sh | bash -s -- 3 --yes
# ---------------------------------------------------------------------------

REPO_OWNER="mikaelvesavuori"
REPO_NAME="game-quickstarts"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}"

# ANSI colors for the banner (empty when stdout isn't a terminal,
# so piped/redirected output stays plain)
if [[ -t 1 ]]; then
    CLR_CYAN=$'\033[36m'
    CLR_MAGENTA=$'\033[35m'
    CLR_RESET=$'\033[0m'
else
    CLR_CYAN=""
    CLR_MAGENTA=""
    CLR_RESET=""
fi

GAME_NAMES=(
    "The Elder Scrolls II: Daggerfall (1996)"
    "Diablo (1996)"
    "Doom via Freedoom (1993)"
    "Duke Nukem 3D (1996)"
    "Heroes of Might and Magic II (1996)"
    "Heroes of Might and Magic III (1999)"
    "Marathon Trilogy (1994-1996)"
    "OpenRA (C&C, Red Alert, Dune 2000)"
    "OpenTTD (Transport Tycoon Deluxe)"
    "Quake (1996)"
    "Quake II (1997)"
    "Quake III Arena (1999)"
    "Shadow Warrior (1997)"
    "ScummVM (Beneath a Steel Sky, FOTAQ, Lure)"
    "SimCity 2000 (1993)"
    "SimTower: The Vertical Empire (1994)"
    "Theme Hospital (1997)"
    "Tyrian 2000 (1999)"
    "Unreal Gold (1998)"
    "Unreal Tournament (1999)"
    "Unreal Tournament 2004"
    "Warzone 2100 (1999)"
    "Wolfenstein 3D (1992)"
    "Wolfenstein: Enemy Territory (2003)"
)
GAME_TAGS=(
    "free, full game"
    "free demo; full game can also be downloaded"
    "free, full game"
    "free demo; full game needs your files"
    "free demo; full game needs your files"
    "free demo; full game needs your files"
    "free, full game"
    "free, full game"
    "free, full game"
    "free demo; full game can also be downloaded"
    "free demo; full game can also be downloaded"
    "free, full game"
    "free, full game"
    "free, full game"
    "free demo; full game needs your files"
    "abandonware, full game - unofficial download"
    "free demo; full game needs your files"
    "free, full game"
    "free, full game"
    "free, full game"
    "free, full game"
    "free, full game"
    "free demo; full game needs your files"
    "free, full game"
)
GAME_SCRIPTS=(
    "install-daggerfall.sh"
    "install-diablo.sh"
    "install-doom.sh"
    "install-duke3d.sh"
    "install-homm2.sh"
    "install-homm3.sh"
    "install-marathon.sh"
    "install-openra.sh"
    "install-openttd.sh"
    "install-quake.sh"
    "install-quake2.sh"
    "install-quake3.sh"
    "install-scummvm.sh"
    "install-shadowwarrior.sh"
    "install-simcity2000.sh"
    "install-simtower.sh"
    "install-themehospital.sh"
    "install-tyrian.sh"
    "install-unreal-gold.sh"
    "install-ut99.sh"
    "install-ut2004.sh"
    "install-warzone2100.sh"
    "install-wolf3d.sh"
    "install-et.sh"
)

GAME_COUNT=${#GAME_NAMES[@]}

# Longest title, so the [tag] column lines up no matter what the titles are
NAME_COL_WIDTH=0
for _name in "${GAME_NAMES[@]}"; do
    if (( ${#_name} > NAME_COL_WIDTH )); then
        NAME_COL_WIDTH=${#_name}
    fi
done

TEMP_DIR=""

cleanup() {
    local exit_code=$?
    if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "${TEMP_DIR:-}" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    exit $exit_code
}
trap cleanup EXIT

is_valid_game_number() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( 1 <= $1 && $1 <= GAME_COUNT ))
}

preflight() {
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Error: These installers are for macOS only." >&2
        exit 1
    fi
    if [[ ${#GAME_NAMES[@]} -ne ${#GAME_SCRIPTS[@]} ]] || [[ ${#GAME_NAMES[@]} -ne ${#GAME_TAGS[@]} ]]; then
        echo "Error: GAME_NAMES, GAME_TAGS and GAME_SCRIPTS are out of sync." >&2
        exit 1
    fi
    for cmd in curl bash; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command not found: $cmd" >&2
            exit 1
        fi
    done
}

print_banner() {
    local release_date short_url
    release_date=$(date +%Y-%m)
    short_url="github.com/${REPO_OWNER}/${REPO_NAME}"

    printf '\n'

    # Warez-style RETRO QUICKSTART lockup (ANSI Shadow block letters, 79 columns)
    printf '%s' "$CLR_CYAN"
    cat <<'EOF'
                  ██████╗ ███████╗████████╗██████╗  ██████╗ 
                  ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗
                  ██████╔╝█████╗     ██║   ██████╔╝██║   ██║
                  ██╔══██╗██╔══╝     ██║   ██╔══██╗██║   ██║
                  ██║  ██║███████╗   ██║   ██║  ██║╚██████╔╝
                  ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ 
 ██████╗ ██╗   ██╗██╗ ██████╗██╗  ██╗███████╗████████╗ █████╗ ██████╗ ████████╗
██╔═══██╗██║   ██║██║██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝
██║   ██║██║   ██║██║██║     █████╔╝ ██████╗    ██║   ███████║██████╔╝   ██║   
██║▄▄ ██║██║   ██║██║██║     ██╔═██╗ ╚════██║   ██║   ██╔══██║██╔══██║   ██║   
╚██████╔╝╚██████╔╝██║╚██████╗██║  ██╗██████╔╝   ██║   ██║  ██║██║  ██║   ██║   
 ╚══▀▀═╝  ╚═════╝ ╚═╝ ╚═════╝╚═╝  ╚═╝╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   
EOF
    printf '%s\n\n' "$CLR_RESET"

    # Release NFO box (80 columns)
    printf '%s' "$CLR_MAGENTA"
    printf '%s\n' '╔═══[ RELEASE NFO ]════════════════════════════════════════════════════════════╗'
    printf '║ %-38s%-38s ║\n' "RELEASE : ${release_date}" "PLATFORM : macOS (AS & Intel)"
    printf '║ %-38s%-38s ║\n' "COUNT   : ${GAME_COUNT} classic games" "SUPPLIER : ${REPO_OWNER}"
    printf '║ %-76s ║\n' "SOURCE  : ${short_url}"
    printf '%s\n\n' '╚══════════════════════════════════════════════════════════════════════════════╝'
    printf '%s' "$CLR_RESET"

    printf '  %s%s%s\n\n' "$CLR_CYAN" "$REPO_URL" "$CLR_RESET"
}

usage() {
    print_banner
    cat <<EOF
Retro Game Quickstart — menu launcher for macOS (Apple Silicon & Intel)

Run interactively and pick a game:
  curl -fsSL ${BASE_URL}/quickstart.sh | bash

Pick a game directly (number 1-${GAME_COUNT}):
  curl -fsSL ${BASE_URL}/quickstart.sh | bash -s -- 3

Forward flags to the chosen installer (e.g. unattended mode):
  curl -fsSL ${BASE_URL}/quickstart.sh | bash -s -- 3 --yes

Games:
EOF
    local i=0
    while [[ $i -lt ${#GAME_NAMES[@]} ]]; do
        printf "  %2d. %-*s  [%s]\n" $((i + 1)) "$NAME_COL_WIDTH" "${GAME_NAMES[$i]}" "${GAME_TAGS[$i]}"
        i=$((i + 1))
    done
}

select_game() {
    local choice="${1:-}"
    if [[ -n "$choice" ]]; then
        if ! is_valid_game_number "$choice"; then
            echo "Error: invalid game number '$choice' (must be 1-${GAME_COUNT})." >&2
            exit 1
        fi
        SELECTED="$choice"
        return
    fi

    print_banner
    echo "Choose a game to install:"
    echo ""
    local i=0
    while [[ $i -lt ${#GAME_NAMES[@]} ]]; do
        printf "  %2d) %-*s  [%s]\n" $((i + 1)) "$NAME_COL_WIDTH" "${GAME_NAMES[$i]}" "${GAME_TAGS[$i]}"
        i=$((i + 1))
    done
    echo ""
    while true; do
        read -r -p "Enter number (1-${GAME_COUNT}), or q to quit: " sel </dev/tty
        if [[ "${sel:-}" == "q" || "${sel:-}" == "Q" ]]; then
            echo "Cancelled."
            exit 0
        fi
        if is_valid_game_number "${sel:-}"; then
            SELECTED="$sel"
            return
        fi
        echo "  Invalid choice. Enter a number 1-${GAME_COUNT}." >&2
    done
}

main() {
    local first_arg="${1:-}"

    if [[ "$first_arg" == "-h" || "$first_arg" == "--help" ]]; then
        usage
        exit 0
    fi

    preflight

    local SELECTED=""
    if [[ -n "$first_arg" && "$first_arg" =~ ^[0-9]+$ ]]; then
        if ! is_valid_game_number "$first_arg"; then
            echo "Error: invalid game number '$first_arg' (must be 1-${GAME_COUNT})." >&2
            exit 1
        fi
        select_game "$first_arg"
        shift
    else
        select_game
    fi

    local script="${GAME_SCRIPTS[$((SELECTED - 1))]}"
    local name="${GAME_NAMES[$((SELECTED - 1))]}"
    local url="${BASE_URL}/${script}"

    echo ""
    echo "Selected: $name"
    echo "  Downloading installer: $script"
    echo ""

    TEMP_DIR=$(mktemp -d)
    local script_path="$TEMP_DIR/$script"

    curl -fsSL -o "$script_path" "$url"

    echo "  Running: bash $script $*"
    echo ""
    bash "$script_path" "$@"
}

main "$@"
