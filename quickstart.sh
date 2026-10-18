#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Retro Game Quickstart — menu launcher
#
# Run from the web (interactive menu):
#   curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/quickstart.sh | bash
#
# Pick a game directly (number 1-14):
#   curl -fsSL .../quickstart.sh | bash -s -- 3
#
# Forward flags to the chosen installer (e.g. unattended mode):
#   curl -fsSL .../quickstart.sh | bash -s -- 3 --yes
# ---------------------------------------------------------------------------

REPO_OWNER="mikaelvesavuori"
REPO_NAME="game-quickstarts"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

GAME_NAMES=(
    "Unreal Tournament (1999)"
    "Unreal Gold (1998)"
    "Unreal Tournament 2004"
    "Quake III Arena"
    "Quake (1996)"
    "The Elder Scrolls II: Daggerfall"
    "OpenRA (C&C, Red Alert, Dune 2000)"
    "Quake II (1997)"
    "Diablo (1996, shareware)"
    "Marathon Trilogy"
    "Wolfenstein: Enemy Territory"
    "Duke Nukem 3D (1996, shareware)"
    "Heroes of Might and Magic II (demo)"
    "Heroes of Might and Magic III"
)
GAME_TAGS=(
    "own copy required - installer fetches the data"
    "own copy required - installer fetches the data"
    "own copy required - installer fetches the data"
    "own copy required - installer fetches the data"
    "free demo - installer fetches full game if owned"
    "free and complete"
    "free and complete"
    "free demo - installer fetches full game if owned"
    "free demo - installer fetches full game if owned"
    "free and complete"
    "free and complete"
    "free demo - full game comes from your own copy"
    "free demo - full game comes from your own copy"
    "free demo - full game comes from your own copy"
)
GAME_SCRIPTS=(
    "install-ut99.sh"
    "install-unreal-gold.sh"
    "install-ut2004.sh"
    "install-quake3.sh"
    "install-quake.sh"
    "install-daggerfall.sh"
    "install-openra.sh"
    "install-quake2.sh"
    "install-diablo.sh"
    "install-marathon.sh"
    "install-et.sh"
    "install-duke3d.sh"
    "install-homm2.sh"
    "install-homm3.sh"
)

GAME_COUNT=${#GAME_NAMES[@]}

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

usage() {
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
        printf "  %d. %s  [%s]\n" $((i + 1)) "${GAME_NAMES[$i]}" "${GAME_TAGS[$i]}"
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

    echo "=== Retro Game Quickstart ==="
    echo ""
    echo "Choose a game to install:"
    echo ""
    local i=0
    while [[ $i -lt ${#GAME_NAMES[@]} ]]; do
        printf "  %d) %s  [%s]\n" $((i + 1)) "${GAME_NAMES[$i]}" "${GAME_TAGS[$i]}"
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
