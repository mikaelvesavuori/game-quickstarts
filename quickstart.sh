#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Retro Game Quickstart — menu launcher
#
# Run from the web (interactive menu):
#   curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/quickstart.sh | bash
#
# Pick a game directly (number 1-7):
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
)
GAME_SCRIPTS=(
    "install-ut99.sh"
    "install-unreal-gold.sh"
    "install-ut2004.sh"
    "install-quake3.sh"
    "install-quake.sh"
    "install-daggerfall.sh"
    "install-openra.sh"
)

TEMP_DIR=""

cleanup() {
    local exit_code=$?
    if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "${TEMP_DIR:-}" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    exit $exit_code
}
trap cleanup EXIT

preflight() {
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "Error: These installers are for macOS only." >&2
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

Pick a game directly (number 1-7):
  curl -fsSL ${BASE_URL}/quickstart.sh | bash -s -- 3

Forward flags to the chosen installer (e.g. unattended mode):
  curl -fsSL ${BASE_URL}/quickstart.sh | bash -s -- 3 --yes

Games:
EOF
    local i=1
    for name in "${GAME_NAMES[@]}"; do
        printf "  %d. %s\n" "$i" "$name"
        i=$((i + 1))
    done
}

select_game() {
    local choice="${1:-}"
    if [[ -n "$choice" ]]; then
        if [[ ! "$choice" =~ ^[1-7]$ ]]; then
            echo "Error: invalid game number '$choice' (must be 1-7)." >&2
            exit 1
        fi
        SELECTED="$choice"
        return
    fi

    echo "=== Retro Game Quickstart ==="
    echo ""
    echo "Choose a game to install:"
    echo ""
    local i=1
    for name in "${GAME_NAMES[@]}"; do
        printf "  %d) %s\n" "$i" "$name"
        i=$((i + 1))
    done
    echo ""
    while true; do
        read -r -p "Enter number (1-7), or q to quit: " sel </dev/tty
        if [[ "${sel:-}" == "q" || "${sel:-}" == "Q" ]]; then
            echo "Cancelled."
            exit 0
        fi
        if [[ "${sel:-}" =~ ^[1-7]$ ]]; then
            SELECTED="$sel"
            return
        fi
        echo "  Invalid choice. Enter a number 1-7." >&2
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
        if [[ ! "$first_arg" =~ ^[1-7]$ ]]; then
            echo "Error: invalid game number '$first_arg' (must be 1-7)." >&2
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
