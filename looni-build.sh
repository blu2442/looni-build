#!/usr/bin/env bash
# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║                    looni-build  •  main launcher  v1.2.0                   ║
# ║           Wine builders  •  Proton builder  •  Hybrid  •  Toolz            ║
# ╚═════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

# ── Path resolution ───────────────────────────────────────────────────────────
# Finds sibling scripts whether running from the source tree or after make install
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

_find_tool() {
    local name="$1"
    local _bin
    # Installed layout: all tools are siblings in the same bin/ directory
    _bin="${SCRIPT_DIR}/${name}"
    [ -x "$_bin" ] && { echo "$_bin"; return; }
    # Source tree layout: each tool lives in its own subdirectory
    case "$name" in
        wine-builder)       _bin="${SCRIPT_DIR}/looni-wine_builder/wine-builder.sh" ;;
        neutron-builder)    _bin="${SCRIPT_DIR}/looni-neutron_builder/neutron-builder.sh" ;;
        wine-proton_hybrid) _bin="${SCRIPT_DIR}/looni-wine-proton_hybrid_builder/wine-proton_hybrid-v1_0_0.sh" ;;
        wine_toolz)         _bin="${SCRIPT_DIR}/looni-winetoolz/wine_toolz.sh" ;;
        wine_install_mgr)   _bin="${SCRIPT_DIR}/looni-winetoolz/modules/shared_lib/wine_install_manager.sh" ;;
    esac
    [ -x "$_bin" ] && { echo "$_bin"; return; }
    echo ""
}

# ── Colours ───────────────────────────────────────────────────────────────────
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    C_R="\033[0m" C_B="\033[1m"
    C_MAG="\033[1;35m" C_CYN="\033[1;36m" C_DIM="\033[2m"
else
    C_R="" C_B="" C_MAG="" C_CYN="" C_DIM=""
fi

# ── Banner ────────────────────────────────────────────────────────────────────
clear
printf "\n${C_MAG}${C_B}"
cat << 'WOLF'
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠁⠸⢳⡄⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠃⠀⠀⢸⠸⠀⡠⣄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠃⠀⠀⢠⣞⣀⡿⠀⠀⣧⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⡖⠁⠀⠀⠀⢸⠈⢈⡇⠀⢀⡏⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⠩⢠⡴⠀⠀⠀⠀⠀⠈⡶⠉⠀⠀⡸⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⠎⢠⣇⠏⠀⠀⠀⠀⠀⠀⠀⠁⠀⢀⠄⡇⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⠏⠀⢸⣿⣴⠀⠀⠀⠀⠀⠀⣆⣀⢾⢟⠴⡇⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢀⣿⠀⠠⣄⠸⢹⣦⠀⠀⡄⠀⠀⢋⡟⠀⠀⠁⣇⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⡾⠁⢠⠀⣿⠃⠘⢹⣦⢠⣼⠀⠀⠉⠀⠀⠀⠀⢸⡀⠀⠀⠀⠀
⠀⠀⢀⣴⠫⠤⣶⣿⢀⡏⠀⠀⠘⢸⡟⠋⠀⠀⠀⠀⠀⠀⠀⠀⢳⠀⠀⠀⠀
⠐⠿⢿⣿⣤⣴⣿⣣⢾⡄⠀⠀⠀⠀⠳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢣⠀⠀⠀
⠀⠀⠀⣨⣟⡍⠉⠚⠹⣇⡄⠀⠀⠀⠀⠀⠀⠀⠀⠈⢦⠀⠀⢀⡀⣾⡇⠀⠀
⠀⠀⢠⠟⣹⣧⠃⠀⠀⢿⢻⡀⢄⠀⠀⠀⠀⠐⣦⡀⣸⣆⠀⣾⣧⣯⢻⠀⠀
⠀⠀⠘⣰⣿⣿⡄⡆⠀⠀⠀⠳⣼⢦⡘⣄⠀⠀⡟⡷⠃⠘⢶⣿⡎⠻⣆⠀⠀
⠀⠀⠀⡟⡿⢿⡿⠀⠀⠀⠀⠀⠙⠀⠻⢯⢷⣼⠁⠁⠀⠀⠀♢�⡄⡈⢆⠀
⠀⠀⠀⠀⡇⣿⡅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠦⠀⠀⠀⠀⠀⠀⡇⢹⢿⡀
⠀⠀⠀⠀⠁⠛⠓⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠼⠇⠁
WOLF
printf "\n"
printf "  ╔═════════════════════════════════════════════════════════════════╗\n"
printf "  ║                                                                 ║\n"
printf "  ║  :3 looni-build  •  Wine & Proton toolkit launcher  v1.2.0      ║\n"
printf "  ║                                                                 ║\n"
printf "  ╚═════════════════════════════════════════════════════════════════╝\n"
printf "${C_R}\n"

# ── Tool catalogue ────────────────────────────────────────────────────────────
declare -A TOOL_KEY TOOL_DESC
TOOL_KEY=(
    [1]="wine-builder"
    [2]="neutron-builder"
    [3]="wine-proton_hybrid"
    [4]="wine_toolz"
    [5]="wine_install_mgr"
)
TOOL_DESC=(
    [1]="🛠  wine-builder          — build Wine from source (mainline, staging, TKG, Valve…)"
    [2]="🎮  neutron-builder       — build Proton (Valve, Kron4ek, GE, TKG variants…)"
    [3]="⇌   wine-proton_hybrid    — merge any Wine build over a Proton base"
    [4]="⚙   wine_toolz            — GUI Wine toolkit (DXVK, prefixes, runtimes…)"
    [5]="📦  wine_install_mgr      — install, switch, and manage custom Wine builds"
)
TOOL_KEYS=( wine-builder neutron-builder wine-proton_hybrid wine_toolz wine_install_mgr )

# ── Launch + menu loop ────────────────────────────────────────────────────────
_launch() {
    local key="$1"
    local tool_bin
    tool_bin="$(_find_tool "$key")"
    if [ -z "$tool_bin" ]; then
        printf "\n${C_MAG}  ✖  Could not find: %s${C_R}\n" "$key"
        printf "  ${C_DIM}Make sure looni-build is installed (make install) or run from the repo root.${C_R}\n\n"
        printf "  ${C_DIM}Press Enter to return to the menu...${C_R}"
        read -r
        return
    fi
    # Run (not exec) so the process returns here when the tool exits
    bash "$tool_bin" || true
}

_build_menu_input() {
    for k in "${TOOL_KEYS[@]}"; do
        for idx in "${!TOOL_KEY[@]}"; do
            if [ "${TOOL_KEY[$idx]}" = "$k" ]; then
                printf '%s\t%s\n' "$k" "${TOOL_DESC[$idx]}"
            fi
        done
    done
    printf 'exit\t  ←  exit looni-build\n'
}

while true; do
    if command -v fzf >/dev/null 2>&1; then
        picked=$(
            _build_menu_input             | fzf \
                --prompt="looni-build > " \
                --header="Select a tool  (Esc or ← exit to quit)" \
                --with-nth=2 \
                --delimiter=$'\t' \
                --height=19% \
                --border \
                --border-label=" looni-build " \
                --border-label-pos=3 \
            || true
        )
        [ -z "$picked" ] && { printf "\n  ${C_DIM}Goodbye :3${C_R}\n\n"; exit 0; }
        key="$(printf '%s' "$picked" | cut -d$'\t' -f1)"
    else
        # Fallback: numbered menu
        printf "  ${C_B}Select a tool:${C_R}\n\n"
        for idx in 1 2 3 4 5; do
            printf "  ${C_CYN}%d)${C_R} %s\n" "$idx" "${TOOL_DESC[$idx]}"
        done
        printf "  ${C_CYN}q)${C_R}  Exit\n"
        printf "\n  ${C_B}Choice [1-5, q]:${C_R} "
        read -r _choice
        case "$_choice" in
            1|2|3|4|5) key="${TOOL_KEY[$_choice]}" ;;
            q|Q|"")  printf "\n  ${C_DIM}Goodbye :3${C_R}\n\n"; exit 0 ;;
            *) printf "\n  ${C_MAG}Invalid choice.${C_R}\n\n"; continue ;;
        esac
    fi

    case "$key" in
        exit) printf "\n  ${C_DIM}Goodbye :3${C_R}\n\n"; exit 0 ;;
        *)    _launch "$key" ;;
    esac

    # Clear and redraw banner before looping back
    clear
    printf "\n${C_MAG}${C_B}"
    cat << 'WOLF'
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠁⠸⢳⡄⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠃⠀⠀⢸⠸⠀⡠⣄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠃⠀⠀⢠⣞⣀⡿⠀⠀⣧⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⡖⠁⠀⠀⠀⢸⠈⢈⡇⠀⢀⡏⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⠩⢠⡴⠀⠀⠀⠀⠀⠈⡶⠉⠀⠀⡸⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⠎⢠⣇⠏⠀⠀⠀⠀⠀⠀⠀⠁⠀⢀⠄⡇⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⠏⠀⢸⣿⣴⠀⠀⠀⠀⠀⠀⣆⣀⢾⢟⠴⡇⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢀⣿⠀⠠⣄⠸⢹⣦⠀⠀⡄⠀⠀⢋⡟⠀⠀⠁⣇⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⡾⠁⢠⠀⣿⠃⠘⢹⣦⢠⣼⠀⠀⠉⠀⠀⠀⠀⢸⡀⠀⠀⠀⠀
⠀⠀⢀⣴⠫⠤⣶⣿⢀⡏⠀⠀⠘⢸⡟⠋⠀⠀⠀⠀⠀⠀⠀⠀⢳⠀⠀⠀⠀
⠐⠿⢿⣿⣤⣴⣿⣣⢾⡄⠀⠀⠀⠀⠳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢣⠀⠀⠀
⠀⠀⠀⣨⣟⡍⠉⠚⠹⣇⡄⠀⠀⠀⠀⠀⠀⠀⠀⠈⢦⠀⠀⢀⡀⣾⡇⠀⠀
⠀⠀⢠⠟⣹⣧⠃⠀⠀⢿⢻⡀⢄⠀⠀⠀⠀⠐⣦⡀⣸⣆⠀⣾⣧⣯⢻⠀⠀
⠀⠀⠘⣰⣿⣿⡄⡆⠀⠀⠀⠳⣼⢦⡘⣄⠀⠀⡟⡷⠃⠘⢶⣿⡎⠻⣆⠀⠀
⠀⠀⠀⡟⡿⢿⡿⠀⠀⠀⠀⠀⠙⠀⠻⢯⢷⣼⠁⠁⠀⠀⠀⠀⠀⡄⡈⢆⠀
⠀⠀⠀⠀⡇⣿⡅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠦⠀⠀⠀⠀⠀⠀⡇⢹⢿⡀
⠀⠀⠀⠀⠁⠛⠓⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠼⠇⠁
WOLF
    printf "\n"
    printf "  ╔═════════════════════════════════════════════════════════════════╗\n"
    printf "  ║                                                                 ║\n"
    printf "  ║  :3 looni-build  •  Wine & Proton toolkit launcher  v1.2.0      ║\n"
    printf "  ║                                                                 ║\n"
    printf "  ╚═════════════════════════════════════════════════════════════════╝\n"
    printf "${C_R}\n"
done
