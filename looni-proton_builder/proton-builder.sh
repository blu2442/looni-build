#!/usr/bin/env bash
# ╔═════════════════════════════════════════════════════════════════════════════╗
# ║            looni-proton_builder  •  multi-component  v1.0.0                ║
# ║          proton-wine  •  DXVK  •  VKD3D-Proton  •  Steam package          ║
# ╚═════════════════════════════════════════════════════════════════════════════╝
#
# Entry point for building a custom Proton compatibility tool for Steam.
#
# Phase 1 (this release):
#   • proton-wine  — Valve's Wine fork, compiled with --with-mingw + Proton flags
#   • Packaging    — Steam-loadable Proton layout (compatibilitytool.vdf etc.)
#
# Phase 2 (coming next):
#   • DXVK        — D3D9/10/11 → Vulkan (proton-dxvk-build.sh)
#   • VKD3D-Proton — D3D12 → Vulkan (proton-vkd3d-build.sh)
#
# Usage:  ./proton-builder.sh [options]
#         ./proton-builder.sh --help
#
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# ══════════════════════════════════════════════════════════════════════════════
#  Colour & output helpers
# ══════════════════════════════════════════════════════════════════════════════
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    C_R="\033[0m" C_B="\033[1m"
    C_GRN="\033[1;32m" C_BLU="\033[1;34m"
    C_YLW="\033[1;33m" C_RED="\033[1;31m"
    C_CYN="\033[1;36m" C_MAG="\033[1;35m"
    C_DIM="\033[2m"
else
    C_R="" C_B="" C_GRN="" C_BLU="" C_YLW="" C_RED="" C_CYN="" C_MAG="" C_DIM=""
fi

msg()     { printf "${C_GRN}==> ${C_R}${C_B}%s${C_R}\n" "$*"; }
msg2()    { printf "${C_BLU} -> ${C_R}%s\n" "$*"; }
ok()      { printf "${C_GRN} ✓  ${C_R}%s\n" "$*"; }
warn()    { printf "${C_YLW}warn${C_R} %s\n" "$*" >&2; }
err()     { printf "${C_RED}ERR!${C_R} %s\n" "$*" >&2; exit 1; }
section() { printf "\n${C_CYN}${C_B}── %s ──${C_R}\n" "$*"; }
dim()     { printf "${C_DIM}%s${C_R}\n" "$*"; }
run()     { printf "${C_BLU}    \$${C_R} %s\n" "$*"; [ "${DRY_RUN:-0}" -eq 1 ] || "$@"; }

# ══════════════════════════════════════════════════════════════════════════════
#  Banner
# ══════════════════════════════════════════════════════════════════════════════
print_banner() {
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
⠀⠀⠀⡟⡿⢿⡿⠀⠀⠀⠀⠀⠙⠀⠻⢯⢷⣼⠁⠁⠀⠀⠀⠙⢿⡄⡈⢆⠀
⠀⠀⠀⠀⡇⣿⡅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠦⠀⠀⠀⠀⠀⠀⡇⢹⢿⡀
⠀⠀⠀⠀⠁⠛⠓⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠼⠇⠁
WOLF
    printf "\n"
    printf "  ╔═══════════════════════════════════════════════════════════════╗\n"
    printf "  ║                                                               ║\n"
    printf "  ║  🎮  looni-proton_builder  •  multi-component v1.0.0          ║\n"
    printf "  ║      proton-wine  •  DXVK  •  VKD3D-Proton  •  package        ║\n"
    printf "  ║                                                               ║\n"
    printf "  ╚═══════════════════════════════════════════════════════════════╝\n"
    printf "${C_R}\n"
}

# ══════════════════════════════════════════════════════════════════════════════
#  Source catalogues
# ══════════════════════════════════════════════════════════════════════════════

# ── Wine source (required, pick one) ─────────────────────────────────────────
declare -A WINE_SOURCE_URL=(
    [proton-wine]="https://github.com/ValveSoftware/wine.git"
    [proton-wine-experimental]="https://github.com/ValveSoftware/wine.git"
    [kron4ek-tkg]="https://github.com/Kron4ek/wine-tkg.git"
)
declare -A WINE_SOURCE_BRANCH=(
    [proton-wine]=""              # version picker selects the branch (proton_X.Y)
    [proton-wine-experimental]="bleeding-edge"
    [kron4ek-tkg]=""              # default branch tracks latest Wine + staging + TKG + ntsync
)
declare -A WINE_SOURCE_DESC=(
    [proton-wine]="Valve proton-wine     — stable branches (version picker)"
    [proton-wine-experimental]="Valve proton-wine exp  — bleeding-edge (no version picker)"
    [kron4ek-tkg]="Kron4ek wine-tkg      — mainline + Staging + TKG patches + ntsync"
)
# Valve uses branches (proton_9.0, proton_8.0 …), not tags
declare -A WINE_SOURCE_HAS_VERSIONS=(
    [proton-wine]="true"
    [kron4ek-tkg]="true"
)
declare -A WINE_SOURCE_VERSION_REF_TYPE=(
    [proton-wine]="heads"   # branches, not tags
    [kron4ek-tkg]="tags"    # standard wine-X.Y tags
)
WINE_SOURCE_KEYS=( proton-wine proton-wine-experimental kron4ek-tkg )

# ── DXVK source (optional, Phase 2) ──────────────────────────────────────────
declare -A DXVK_SOURCE_URL=(
    [dxvk]="https://github.com/doitsujin/dxvk.git"
    [dxvk-async]="https://github.com/Sporif/dxvk-async.git"
    [none]=""
)
declare -A DXVK_SOURCE_DESC=(
    [dxvk]="DXVK        — D3D9/10/11 → Vulkan (doitsujin/dxvk)"
    [dxvk-async]="DXVK async  — DXVK + async pipeline compilation"
    [none]="None        — skip DXVK (falls back to WineD3D for D3D9/10/11)"
)

# ── VKD3D-Proton source (optional, Phase 2) ───────────────────────────────────
declare -A VKD3D_SOURCE_URL=(
    [vkd3d-proton]="https://github.com/HansKristian-Work/vkd3d-proton.git"
    [none]=""
)
declare -A VKD3D_SOURCE_DESC=(
    [vkd3d-proton]="VKD3D-Proton — D3D12 → Vulkan (HansKristian-Work)"
    [none]="None         — skip VKD3D-Proton (D3D12 games will not work)"
)

# ══════════════════════════════════════════════════════════════════════════════
#  Defaults  —  all overridable by flags
# ══════════════════════════════════════════════════════════════════════════════
DEST_ROOT="${SCRIPT_DIR}/buildz"
SRC_ROOT="${SCRIPT_DIR}/src"

WINE_SOURCE_KEY=""
WINE_SOURCE_BRANCH_ARG=""

DXVK_SOURCE_KEY="dxvk"         # default: include DXVK
DXVK_BRANCH_ARG=""
VKD3D_SOURCE_KEY="vkd3d-proton" # default: include VKD3D-Proton
VKD3D_BRANCH_ARG=""

BUILD_NAME=""
JOBS="${JOBS:-$(nproc)}"
SKIP_32BIT=false
NO_PULL=false
RESUME=false
SKIP_WINE_BUILD=false      # set by --dxvk-only / --vkd3d-only
SKIP_DXVK=false           # set by --vkd3d-only
REINSTALL_COMPONENTS=false # set by --reinstall-components
DRY_RUN=0
CUSTOM_CFG="${SCRIPT_DIR}/proton-customization.cfg"
BUILD_CORE="${SCRIPT_DIR}/proton-build-core.sh"
PACKAGER="${SCRIPT_DIR}/proton-package.sh"
DXVK_BUILDER="${SCRIPT_DIR}/proton-dxvk-build.sh"
VKD3D_BUILDER="${SCRIPT_DIR}/proton-vkd3d-build.sh"

# ── Build tuning toggles ──────────────────────────────────────────────────────
NO_CCACHE=false           # --no-ccache: disable ccache entirely
KEEP_SYMBOLS=false        # --keep-symbols: skip strip, keep debug info
BUILD_TYPE="release"      # --build-type release|debug|debugoptimized
NATIVE_MARCH=false        # --native: compile with -march=native (non-portable)
LTO=false                 # --lto: enable link-time optimisation (slow link)

# ══════════════════════════════════════════════════════════════════════════════
#  Usage
# ══════════════════════════════════════════════════════════════════════════════
print_usage() {
    cat <<USAGE
${C_B}Usage:${C_R} $0 [options]

${C_B}Wine source (required):${C_R}
  --source NAME         proton-wine | proton-wine-experimental
  --branch BRANCH       Pin proton-wine to a specific branch (e.g. proton_9.0)
                        Skips the interactive version picker when provided.
  --no-pull             Skip git pull on an existing source tree

${C_B}Component selection:${C_R}
  --dxvk NAME           DXVK variant: dxvk (default) | dxvk-async | none
                        [Phase 2 — see note below]
  --vkd3d NAME          VKD3D variant: vkd3d-proton (default) | none
                        [Phase 2 — see note below]
  --dxvk-branch BRANCH  Pin DXVK to a specific tag
  --vkd3d-branch BRANCH Pin VKD3D-Proton to a specific tag

${C_B}Build options:${C_R}
  --name NAME           Build name for install path (default: looni-proton-<ver>)
  --dest DIR            Root for build artefacts   (default: <script-dir>/buildz)
  --src-dir DIR         Root for git clones         (default: <script-dir>/src)
  --jobs N              Parallel make threads        (default: nproc = $(nproc))
  --skip-32             Skip the 32-bit Wine build
  --no-ccache           Disable ccache even if installed
  --keep-symbols        Skip strip — keep debug symbols in binaries
  --build-type TYPE     release (default) | debug | debugoptimized
  --native              Compile with -march=native (faster but non-portable)
  --lto                 Enable link-time optimisation (slower link, smaller binary)
  --resume              Skip configure if Makefile already exists
  --dxvk-only           Skip Wine entirely — jump straight to DXVK build + package
                        (requires a prior successful Wine build in buildz/install/)
  --vkd3d-only          Skip Wine entirely — jump straight to VKD3D-Proton build + package
  --reinstall-components  Skip Wine + skip building DXVK/VKD3D — just copy already-built
                        DLLs from src/*/build/ into the package and re-run the packager.
                        Use this after a Wine-only rebuild to restore DXVK/VKD3D.
  --cfg PATH            Alternate proton-customization.cfg

${C_B}General:${C_R}
  --list                Show all installed Proton builds
  --dry-run             Print planned actions without executing them
  -h | --help           Show this help

${C_B}Examples:${C_R}
  $0                                          # interactive source + version menu
  $0 --source proton-wine                     # interactive version picker
  $0 --source proton-wine --branch proton_9.0 # pin to proton_9.0
  $0 --source proton-wine-experimental        # bleeding edge, no picker
  $0 --source proton-wine --dxvk none         # Wine only, no DXVK
  $0 --source proton-wine --jobs 16           # more threads
  $0 --source proton-wine --resume            # resume an interrupted build

${C_B}Phase 2 note:${C_R}
  DXVK and VKD3D-Proton builds (--dxvk, --vkd3d) are wired into the pipeline
  but are not yet compiled.  proton-dxvk-build.sh and proton-vkd3d-build.sh
  contain the Phase 2 framework.  The packager (proton-package.sh) already
  knows where to slot them in when they become available.

${C_B}Steam installation:${C_R}
  After a successful build, copy the package directory from:
    buildz/install/<build-name>/
  into:
    ~/.local/share/Steam/compatibilitytools.d/
  Then restart Steam and enable your custom Proton in the game's
  Compatibility settings (Properties → Compatibility).
USAGE
}

# ══════════════════════════════════════════════════════════════════════════════
#  Argument parsing
# ══════════════════════════════════════════════════════════════════════════════
while [ "$#" -gt 0 ]; do
    case "$1" in
        --source)       WINE_SOURCE_KEY="$2";    shift 2 ;;
        --branch)       WINE_SOURCE_BRANCH_ARG="$2"; shift 2 ;;
        --dxvk)         DXVK_SOURCE_KEY="$2";   shift 2 ;;
        --vkd3d)        VKD3D_SOURCE_KEY="$2";  shift 2 ;;
        --dxvk-branch)  DXVK_BRANCH_ARG="$2";   shift 2 ;;
        --vkd3d-branch) VKD3D_BRANCH_ARG="$2";  shift 2 ;;
        --dest)         DEST_ROOT="$2";          shift 2 ;;
        --src-dir)      SRC_ROOT="$2";           shift 2 ;;
        --name)         BUILD_NAME="$2";         shift 2 ;;
        --jobs)         JOBS="$2";               shift 2 ;;
        --skip-32)      SKIP_32BIT=true;         shift   ;;
        --no-ccache)    NO_CCACHE=true;          shift   ;;
        --keep-symbols) KEEP_SYMBOLS=true;       shift   ;;
        --build-type)   BUILD_TYPE="$2";         shift 2 ;;
        --native)       NATIVE_MARCH=true;       shift   ;;
        --lto)          LTO=true;                shift   ;;
        --resume)       RESUME=true;             shift   ;;
        --verbose)      export VERBOSE_BUILD=true; shift   ;;
        --no-pull)      NO_PULL=true;            shift   ;;
        --dxvk-only)    SKIP_WINE_BUILD=true; DXVK_SOURCE_KEY="${DXVK_SOURCE_KEY:-dxvk}"; shift ;;
        --vkd3d-only)   SKIP_WINE_BUILD=true; SKIP_DXVK=true; VKD3D_SOURCE_KEY="${VKD3D_SOURCE_KEY:-vkd3d-proton}"; shift ;;
        --reinstall-components) SKIP_WINE_BUILD=true; REINSTALL_COMPONENTS=true; shift ;;
        --kron4ek-redist)
            # Run just the compat redist function against an existing build dir
            # Usage: ./proton-builder.sh --kron4ek-redist <BUILD_DIR> [PROTON_PKG_DIR]
            _KRON4EK_REDIST_BUILD="${2:-}"
            _KRON4EK_REDIST_PKG="${3:-}"
            shift; [ -n "$_KRON4EK_REDIST_BUILD" ] && shift || true
            [ -n "$_KRON4EK_REDIST_PKG" ] && shift || true
            ;;
        --cfg)          CUSTOM_CFG="$2";         shift 2 ;;
        --dry-run)      DRY_RUN=1;               shift   ;;
        --list)         _LIST_MODE=true;         shift   ;;
        -h|--help)      print_usage; exit 0               ;;
        *) printf "Unknown option: %s\n" "$1" >&2; print_usage; exit 1 ;;
    esac
done

# ══════════════════════════════════════════════════════════════════════════════
#  List mode
# ══════════════════════════════════════════════════════════════════════════════
if [ "${_LIST_MODE:-false}" = "true" ]; then
    section "Installed Proton builds"
    install_dir="${DEST_ROOT}/install"
    if [ ! -d "$install_dir" ] || [ -z "$(ls -A "$install_dir" 2>/dev/null)" ]; then
        msg2 "No builds found in ${install_dir}"
        exit 0
    fi
    printf "\n${C_B}  %-36s  %-28s  %s${C_R}\n" "build name" "wine version" "size"
    printf "  %s\n" "$(printf '─%.0s' {1..78})"
    for d in "$install_dir"/*/; do
        [ -d "$d" ] || continue
        _name="$(basename "$d")"
        _wine="${d}files/bin/wine"
        if [ -x "$_wine" ]; then
            _ver="$("$_wine" --version 2>/dev/null || printf 'unknown')"
        else
            _ver="(binary not found)"
        fi
        _size="$(du -sh "$d" 2>/dev/null | cut -f1)"
        printf "  ${C_CYN}%-36s${C_R}  %-28s  %s\n" "$_name" "$_ver" "$_size"
    done
    printf "\n"
    exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
#  Dependency check
# ══════════════════════════════════════════════════════════════════════════════
check_deps() {
    section "Dependency check"
    local -a missing=()
    local -a tools=(
        git make autoconf automake pkg-config
        gcc g++
        i686-linux-gnu-gcc
        x86_64-w64-mingw32-gcc
        i686-w64-mingw32-gcc
        meson ninja
    )
    for t in "${tools[@]}"; do
        if command -v "$t" >/dev/null 2>&1; then
            ok "$t"
        else
            warn "MISSING: $t"
            missing+=("$t")
        fi
    done

    # glslangValidator (for DXVK in Phase 2, but warn now)
    if command -v glslangValidator >/dev/null 2>&1; then
        ok "glslangValidator"
    else
        warn "glslangValidator not found (needed for DXVK in Phase 2)"
        warn "  Install: sudo apt install glslang-tools"
    fi

    # ccache (optional but strongly recommended)
    if command -v ccache >/dev/null 2>&1; then
        ok "ccache  (rebuilds will be much faster)"
    else
        warn "ccache not found — rebuilds will not be cached"
        warn "  Install: sudo apt install ccache"
    fi

    if [ "${#missing[@]}" -gt 0 ]; then
        err "Missing required tools: ${missing[*]}
     Use the Containerfile.proton environment or install the above.
     See the README for distro-specific install commands."
    fi
    ok "All required tools present"
}

# ══════════════════════════════════════════════════════════════════════════════
#  Disk space preflight  (warn at < 15 GB free — Proton needs more than Wine)
# ══════════════════════════════════════════════════════════════════════════════
check_disk_space() {
    local dir="$1"
    mkdir -p "$dir"
    local avail_kb
    avail_kb=$(df --output=avail "$dir" 2>/dev/null | tail -1 || true)
    [ -n "$avail_kb" ] || return 0
    local avail_gb=$(( avail_kb / 1024 / 1024 ))
    if [ "$avail_gb" -lt 15 ]; then
        warn "Only ~${avail_gb} GB free in ${dir}"
        warn "A full Proton build (Wine + DXVK + VKD3D-Proton) needs ~20 GB."
        warn "Use --dest to point to a filesystem with more space."
        printf "  ${C_B}Continue anyway? [y/N]:${C_R} "
        local ans
        read -r ans
        [[ "$ans" =~ ^[yY] ]] || exit 0
    else
        ok "Disk space: ~${avail_gb} GB free"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  fetch_source  — clone or update a git repo
#
#  Usage: fetch_source <url> <branch> <dest_dir> <shallow>
#         branch  — empty string → use default branch
#         shallow — "true" for --depth=1, "false" for full clone
# ══════════════════════════════════════════════════════════════════════════════
fetch_source() {
    local url="$1"
    local branch="$2"
    local dest="$3"
    local shallow="${4:-true}"

    local depth_flag=()
    [ "$shallow" = "true" ] && depth_flag=( "--depth=1" )

    if [ ! -d "$dest/.git" ]; then
        msg "Cloning: $url"
        [ -n "$branch" ] && msg2 "Branch: $branch"
        local branch_flag=()
        [ -n "$branch" ] && branch_flag=( "--branch" "$branch" )
        run git clone \
            "${depth_flag[@]+"${depth_flag[@]}"}" \
            "${branch_flag[@]+"${branch_flag[@]}"}" \
            "$url" "$dest"
    else
        if [ "$NO_PULL" = "true" ]; then
            msg2 "--no-pull: skipping git pull in $dest"
        else
            msg "Updating: $dest"
            run git -C "$dest" fetch origin
            if [ -n "$branch" ]; then
                run git -C "$dest" checkout "$branch"
                run git -C "$dest" pull --ff-only origin "$branch" 2>/dev/null || true
            else
                run git -C "$dest" pull --ff-only 2>/dev/null || true
            fi
        fi
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  pick_wine_version  — interactive branch/version picker for proton-wine
#
#  Proton-wine uses branches (proton_9.0, proton_8.0, …) not tags.
#  Sets global _wine_branch.
# ══════════════════════════════════════════════════════════════════════════════
pick_wine_version() {
    local url="$1" key="$2"

    [ -t 0 ]                                               || return 0
    [ "${WINE_SOURCE_HAS_VERSIONS[$key]:-false}" = "true" ] || return 0
    [ -z "$WINE_SOURCE_BRANCH_ARG" ]                        || return 0

    section "Version selection"
    msg2 "Fetching available versions from remote…"
    msg2 "(querying $url)"

    local ref_type="${WINE_SOURCE_VERSION_REF_TYPE[$key]:-tags}"
    local -a versions=()
    local raw_refs

    if [ "$ref_type" = "heads" ]; then
        # Valve proton-wine: branches named proton_X.Y
        if ! raw_refs=$(
                git ls-remote --heads --refs "$url" 2>/dev/null \
                | awk '{print $2}' \
                | sed 's|refs/heads/||' \
                | grep -E '^proton_[0-9]+\.[0-9]' \
                | sort -Vr
            ); then
            warn "Could not fetch branch list — using default branch."
            return 0
        fi
    else
        # Standard tags: wine-X.Y
        if ! raw_refs=$(
                git ls-remote --tags --refs "$url" 2>/dev/null \
                | awk '{print $2}' \
                | sed 's|refs/tags/||' \
                | grep -E '^wine-[0-9]+\.[0-9]' \
                | grep -v -- '-rc' \
                | sort -Vr
            ); then
            warn "Could not fetch tag list — using default branch."
            return 0
        fi
    fi

    while IFS= read -r v; do
        [ -n "$v" ] && versions+=("$v")
    done <<< "$raw_refs"

    if [ "${#versions[@]}" -eq 0 ]; then
        warn "No versions found — using default branch."
        return 0
    fi

    ok "Found ${#versions[@]} version(s) — showing newest first"

    local latest_label="Latest  (default — most recent commit)"

    if command -v fzf >/dev/null 2>&1; then
        local picked
        picked=$(
            { printf '%s\n' "__latest__"$'\t'"${latest_label}";
              for v in "${versions[@]}"; do
                  case "$key" in
                      kron4ek-tkg)
                          ver="${v#wine-}"
                          label="Kron4ek TKG Wine ${ver}  (tag: ${v})"
                          ;;
                      *)
                          ver="${v#proton_}"
                          label="Valve Proton ${ver}  (branch: ${v})"
                          ;;
                  esac
                  printf '%s\n' "${v}"$'\t'"${label}"
              done; } \
            | fzf \
                --prompt="Version > " \
                --header="Select a version" \
                --with-nth=2 \
                --delimiter=$'\t' \
                --height=50% \
                --border \
            || true
        )
        [ -n "$picked" ] || { ok "Using latest (default branch)"; return 0; }
        local raw
        raw="$(printf '%s' "$picked" | cut -d$'\t' -f1)"
        if [ "$raw" = "__latest__" ]; then
            ok "Using latest (default branch)"
            return 0
        fi
        _wine_branch="$raw"
        ok "Selected: ${_wine_branch}"
        return 0
    fi

    # bash select fallback
    local -a menu_items=( "$latest_label" )
    for v in "${versions[@]}"; do
        menu_items+=( "$v" )
    done
    PS3="  Version: "
    local picked_display
    select picked_display in "${menu_items[@]}"; do
        if [ "$picked_display" = "$latest_label" ] || [ -z "$picked_display" ]; then
            ok "Using latest (default branch)"; break
        fi
        _wine_branch="$picked_display"
        ok "Selected: ${_wine_branch}"; break
    done
    PS3=""
}

# ══════════════════════════════════════════════════════════════════════════════
#  run_autoreconf  — regenerate configure from configure.ac
# ══════════════════════════════════════════════════════════════════════════════
run_autoreconf() {
    local src="$1"
    section "autoreconf"
    msg2 "Running autoreconf in: $src"
    run autoreconf -fvi "$src"
    ok "autoreconf complete"
}

# ══════════════════════════════════════════════════════════════════════════════
#  fix_opencl_headers
#  Wine's configure looks for /usr/include/OpenCL/opencl.h (macOS layout).
#  On Linux the header lives at /usr/include/CL/cl.h — create a symlink.
# ══════════════════════════════════════════════════════════════════════════════
fix_opencl_headers() {
    local linux_h="/usr/include/CL/cl.h"
    local compat_h="/usr/include/OpenCL/opencl.h"

    if [ -f "$compat_h" ]; then
        ok "OpenCL compat header present"
        return
    fi

    if [ ! -f "$linux_h" ]; then
        warn "OpenCL headers not found — OpenCL will be disabled in this build."
        warn "Install with: sudo apt install ocl-icd-opencl-dev"
        return
    fi

    msg2 "Creating OpenCL compat symlink (macOS path expected by configure)..."
    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p /usr/include/OpenCL 2>/dev/null || \
            sudo mkdir -p /usr/include/OpenCL
        ln -sf "$linux_h" "$compat_h" 2>/dev/null || \
            sudo ln -sf "$linux_h" "$compat_h" || \
            warn "Could not create $compat_h — OpenCL may be disabled"
        ok "OpenCL compat symlink created"
    else
        dim "  [dry-run] ln -sf $linux_h $compat_h"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  _kron4ek_tkg_compat_redist  <BUILD_DIR>
#
#  Applies all compatibility patches needed to run proton-tkg's  make redist
#  against a Kron4ek wine build (which lacks several Valve-only APIs) and
#  runs the build inside the umu-sdk container.
#
#  Encodes every fix discovered during the looni Proton 11 build session:
#    1. Wine binary stubs  (wine64 / preloaders missing in unified builds)
#    2. Valve makedep      (Kron4ek makedep segfaults on Valve source syntax)
#    3. wine_unix_to_nt_file_name stub  (lsteamclient/vrclient)
#    4. __chkstk_ms stub   (MinGW 14 stack-probe symbol not in libgcc)
#    5. wineopenxr stubs   (Valve-only VkCreateInfoWine* types)
#    6. Stamp freeze       (prevent config.status / makedep clobber loops)
#    7. Destination dirs   (pre-create so /usr/bin/install succeeds)
#    8. install-sh fix     (noexec homefs — redirect to /usr/bin/install)
#    9. gst_plugins_rs skip (needs internet to download Rust crates)
#   10. wineopenxr skip    (Valve-only Vulkan extensions, VR not needed)
#   11. Component Makefile patching  (winecrt0 path, install-sh → /usr/bin/install)
#   12. Retry loop         (up to 5 attempts; re-freezes stamps each time)
#   13. DLL rename         (vrclient.dll → vrclient_x64.dll for Proton compat)
# ══════════════════════════════════════════════════════════════════════════════
_kron4ek_tkg_compat_redist() {
    local BUILD="$1"
    local PROTON_ROOT
    PROTON_ROOT="$(dirname "$BUILD")"
    local VALVE_SRC="/tmp/looni-valve-wine-src"
    local VALVE_BUILD="/tmp/looni-valve-wine-build"

    section "Kron4ek TKG compat redist"
    msg2 "BUILD dir  : $BUILD"
    msg2 "PROTON root: $PROTON_ROOT"

    # ── 1. Wine binary stubs ──────────────────────────────────────────────────
    msg2 "Step 1/13: wine binary stubs"
    local DST_X64="$BUILD/dst-wine-x86_64"
    local DST_I386="$BUILD/dst-wine-i386"
    for dir in "$DST_X64/bin" "$DST_I386/bin"; do
        [ -d "$dir" ] || continue
        [ -f "$dir/wine" ] || continue
        [ -f "$dir/wine64" ]           || { cp -f "$dir/wine" "$dir/wine64";           ok "  created wine64 in $dir"; }
        [ -f "$dir/wine64-preloader" ] || { cp -f "$dir/wine" "$dir/wine64-preloader"; ok "  created wine64-preloader"; }
        [ -f "$dir/wine-preloader" ]   || { cp -f "$dir/wine" "$dir/wine-preloader";   ok "  created wine-preloader"; }
    done
    # Touch build stamps so make doesn't try to rebuild wine
    for stamp in \
        "$BUILD/.wine-x86_64-post-build" "$BUILD/.wine-i386-post-build" \
        "$BUILD/.wine-x86_64-build"      "$BUILD/.wine-i386-build"; do
        [ -f "$stamp" ] || touch "$stamp"
    done

    # ── 2. Valve makedep ─────────────────────────────────────────────────────
    msg2 "Step 2/13: Valve makedep"
    local MAKEDEP="$BUILD/obj-wine-x86_64/tools/makedep"
    mkdir -p "$(dirname "$MAKEDEP")"
    # Check if we already have a good Valve makedep
    local needs_makedep=1
    if [ -f "$VALVE_BUILD/tools/makedep" ]; then
        needs_makedep=0
    fi
    if [ "$needs_makedep" -eq 1 ]; then
        msg2 "  Cloning Valve wine source for makedep..."
        if [ ! -d "$VALVE_SRC/.git" ]; then
            git clone --depth=1 https://github.com/ValveSoftware/wine.git "$VALVE_SRC" \
                || { warn "Could not clone Valve wine — makedep may fail"; }
        fi
        if [ -d "$VALVE_SRC" ]; then
            podman run --rm \
                -v "$VALVE_SRC":"$VALVE_SRC" \
                -v "$VALVE_BUILD":"$VALVE_BUILD" \
                ghcr.io/open-wine-components/umu-sdk:latest \
                bash -c "
                    set -e
                    cd '$VALVE_SRC'
                    python3 dlls/winevulkan/make_vulkan 2>/dev/null || true
                    perl tools/make_specfiles 2>/dev/null || true
                    perl tools/make_requests 2>/dev/null || true
                    autoreconf -fiv 2>/dev/null
                    mkdir -p '$VALVE_BUILD'
                    cd '$VALVE_BUILD'
                    '$VALVE_SRC/configure' --enable-win64 2>/dev/null
                    make -j\$(nproc) tools/makedep
                " && ok "  Valve makedep built" || warn "  Valve makedep build failed — will retry without"
        fi
    fi
    if [ -f "$VALVE_BUILD/tools/makedep" ]; then
        cp "$VALVE_BUILD/tools/makedep" "$MAKEDEP"
        chmod +x "$MAKEDEP"
        ok "  Valve makedep installed"
    else
        warn "  Valve makedep not available — configure segfaults may occur"
    fi

    # ── 3–5. Patch source files ───────────────────────────────────────────────
    msg2 "Step 3-5/13: patching source files"
    python3 - "$BUILD" "$PROTON_ROOT" << 'PYEOF'
import sys, os, subprocess
BUILD, PROTON_ROOT = sys.argv[1], sys.argv[2]

unix_stub = """\n/* looni compat: stub wine_unix_to_nt_file_name for Kron4ek wine */\n#ifndef STATUS_NOT_IMPLEMENTED\n#define STATUS_NOT_IMPLEMENTED ((NTSTATUS)0xC0000002L)\n#endif\nstatic inline NTSTATUS wine_unix_to_nt_file_name(const char *n, void *b, unsigned int *s)\n{ (void)n; (void)b; (void)s; return STATUS_NOT_IMPLEMENTED; }\n/* looni compat end */\n"""

chkstk_stub = """\n/* looni compat: __chkstk_ms stub for MinGW 14 */\n#if defined(__i386__) || defined(__x86_64__)\nvoid __chkstk_ms(void) {}\nvoid ___chkstk_ms(void) {}\n#endif\n/* looni chkstk end */\n"""

openxr_stub_h = """\
/* looni compat: stub Valve wine Vulkan extensions for Kron4ek wine */
#ifndef LOONI_WINE_VK_STUBS_H
#define LOONI_WINE_VK_STUBS_H
#ifndef VK_STRUCTURE_TYPE_CREATE_INFO_WINE_INSTANCE_CALLBACK
#define VK_STRUCTURE_TYPE_CREATE_INFO_WINE_INSTANCE_CALLBACK ((VkStructureType)1000467000)
#endif
#ifndef VK_STRUCTURE_TYPE_CREATE_INFO_WINE_DEVICE_CALLBACK
#define VK_STRUCTURE_TYPE_CREATE_INFO_WINE_DEVICE_CALLBACK   ((VkStructureType)1000467001)
#endif
typedef struct VkCreateInfoWineInstanceCallback {
    VkStructureType sType; const void *pNext;
    UINT64 native_create_callback; void *context;
} VkCreateInfoWineInstanceCallback;
typedef struct VkCreateInfoWineDeviceCallback {
    VkStructureType sType; const void *pNext;
    UINT64 native_create_callback; void *context;
} VkCreateInfoWineDeviceCallback;
static inline void __wine_set_unix_env(const char *v, const char *val)
{ (void)v; (void)val; }
#endif /* LOONI_WINE_VK_STUBS_H */
"""

def patch_prepend(path, stub, marker):
    if not os.path.exists(path): return
    lines = open(path).readlines()
    if any(marker in l for l in lines):
        print(f'  already patched: {os.path.basename(path)}'); return
    last_inc = max((i for i,l in enumerate(lines) if l.strip().startswith('#include')), default=0)
    lines.insert(last_inc + 1, stub)
    open(path, 'w').write(''.join(lines))
    print(f'  patched: {os.path.basename(path)}')

# unix_to_nt stub — lsteamclient unixlib + vrclient json_converter
for name in ['unixlib.cpp', 'json_converter.cpp']:
    r = subprocess.run(['find', PROTON_ROOT, '-name', name], capture_output=True, text=True)
    for f in r.stdout.strip().split('\n'):
        if f.strip():
            patch_prepend(f.strip(), unix_stub, 'looni compat: stub wine_unix')

# chkstk stub — steamclient_main + vrclient_main
r = subprocess.run(['find', PROTON_ROOT, '(', '-name', 'steamclient_main.c', '-o', '-name', 'vrclient_main.c', ')'],
                   capture_output=True, text=True)
for f in r.stdout.strip().split('\n'):
    if f.strip():
        patch_prepend(f.strip(), chkstk_stub, 'looni compat: __chkstk')

# wineopenxr stub header + include injection
r = subprocess.run(['find', PROTON_ROOT, '-name', 'openxr_loader.c'], capture_output=True, text=True)
for f in r.stdout.strip().split('\n'):
    if not f.strip(): continue
    d = os.path.dirname(f.strip())
    open(os.path.join(d, 'looni-wine-vk-stubs.h'), 'w').write(openxr_stub_h)
    content = open(f.strip()).read()
    if 'looni-wine-vk-stubs.h' not in content:
        open(f.strip(), 'w').write('#include "looni-wine-vk-stubs.h"\n' + content)
        print(f'  patched: openxr_loader.c in {d}')

print('Source patching done.')
PYEOF

    # ── 6. Stamp freeze helper (called repeatedly) ────────────────────────────
    _freeze_all_stamps() {
        local B="$1"
        local V="${2:-/tmp/looni-valve-wine-build}"
        # makedep
        [ -f "$V/tools/makedep" ] && {
            cp "$V/tools/makedep" "$B/obj-wine-x86_64/tools/makedep" 2>/dev/null || true
            chmod +x "$B/obj-wine-x86_64/tools/makedep" 2>/dev/null || true
        }
        touch -t 203001010000 \
            "$B/obj-wine-x86_64/tools/makedep" \
            "$B/.wine-x86_64-configure"  "$B/.wine-x86_64-tools" \
            "$B/.wine-x86_64-build"      "$B/.wine-x86_64-post-build" \
            "$B/.wine-i386-configure"    "$B/.wine-i386-tools" \
            "$B/.wine-i386-build"        "$B/.wine-i386-post-build" \
            "$B/.lsteamclient-x86_64-configure" "$B/.lsteamclient-i386-configure" \
            "$B/.vrclient-x86_64-configure"     "$B/.vrclient-i386-configure" \
            "$B/.wineopenxr-x86_64-configure"   "$B/.wineopenxr-x86_64-build" \
            "$B/.wineopenxr-x86_64-dist"        "$B/.wineopenxr-x86_64-post-build" \
            "$B/.steamexe-x86_64-configure"     "$B/.steamexe-i386-configure" \
            "$B/.steamexe-x86_64-build"         "$B/.steamexe-x86_64-post-build" \
            "$B/.steamexe-i386-build"            "$B/.steamexe-i386-post-build" \
            "$B/.gst_plugins_rs-i386-configure"  "$B/.gst_plugins_rs-i386-build" \
            "$B/.gst_plugins_rs-i386-dist"       "$B/.gst_plugins_rs-i386-post-build" \
            "$B/.gst_plugins_rs-x86_64-configure" "$B/.gst_plugins_rs-x86_64-build" \
            "$B/.gst_plugins_rs-x86_64-dist"     "$B/.gst_plugins_rs-x86_64-post-build" \
            2>/dev/null || true
        find "$B/obj-wine-x86_64" "$B/obj-wine-i386" \
            -name "Makefile" 2>/dev/null | xargs touch -t 203001010000 2>/dev/null || true
    }

    msg2 "Step 6/13: freezing stamps"
    _freeze_all_stamps "$BUILD" "$VALVE_BUILD"

    # ── 7. Pre-create destination directories ─────────────────────────────────
    msg2 "Step 7/13: pre-creating destination dirs"
    mkdir -p \
        "$BUILD/dst-lsteamclient-i386/lib/wine/i386-windows" \
        "$BUILD/dst-lsteamclient-i386/lib/wine/i386-unix" \
        "$BUILD/dst-lsteamclient-x86_64/lib/wine/x86_64-windows" \
        "$BUILD/dst-lsteamclient-x86_64/lib/wine/x86_64-unix" \
        "$BUILD/dst-vrclient-i386/lib/wine/i386-windows" \
        "$BUILD/dst-vrclient-i386/lib/wine/i386-unix" \
        "$BUILD/dst-vrclient-x86_64/lib/wine/x86_64-windows" \
        "$BUILD/dst-vrclient-x86_64/lib/wine/x86_64-unix" \
        "$BUILD/dst-steamexe-x86_64/lib/wine/x86_64-windows" \
        "$BUILD/dst-steamexe-i386/lib/wine/i386-windows"

    # ── 8. install-sh fix (noexec homefs) ────────────────────────────────────
    msg2 "Step 8/13: install-sh fix"
    mkdir -p "$BUILD/src-wine/tools"
    python3 -c "
import os, stat
path = '$BUILD/src-wine/tools/install-sh'
script = '#!/bin/sh\nmode=\"\" src=\"\" dst=\"\"\nwhile [ \$# -gt 0 ]; do\n  case \"\$1\" in\n    -m) mode=\"\$2\"; shift 2;;\n    -d) shift; mkdir -p \"\$1\"; shift;;\n    -*) shift;;\n    *) if [ -z \"\$src\" ]; then src=\"\$1\"; else dst=\"\$1\"; fi; shift;;\n  esac\ndone\n[ -n \"\$src\" ] && [ -n \"\$dst\" ] && cp \"\$src\" \"\$dst\"\n[ -n \"\$mode\" ] && [ -n \"\$dst\" ] && chmod \"\$mode\" \"\$dst\"\nexit 0\n'
open(path, 'w', newline='\n').write(script)
os.chmod(path, 0o755)
print('  install-sh written')
"

    # ── 9–10. Skip gst_plugins_rs and wineopenxr (done via stamps above) ─────
    msg2 "Step 9-10/13: gst_plugins_rs and wineopenxr skipped via stamps"

    # ── 11–12. Redist build with retry loop ───────────────────────────────────
    msg2 "Step 11-12/13: running make CONTAINER=1 redist (up to 5 attempts)"
    local attempt=1
    local max_attempts=5
    local exit_code=1
    local WINECRT_W64="$BUILD/dst-wine-x86_64/lib/wine/x86_64-windows"
    local WINECRT_LIB="$BUILD/dst-wine-x86_64/lib/x86_64-linux-gnu"
    local LOG_BASE="/tmp/looni-redist"

    _patch_component_makefiles() {
        local B="$1"
        local CRT_W64="$2"
        local CRT_LIB="$3"
        for mf in \
            "$B/obj-lsteamclient-x86_64/Makefile" \
            "$B/obj-lsteamclient-i386/Makefile" \
            "$B/obj-vrclient-x86_64/Makefile" \
            "$B/obj-vrclient-i386/Makefile" \
            "$B/obj-steamexe-x86_64/Makefile" \
            "$B/obj-steamexe-i386/Makefile"; do
            [ -f "$mf" ] || continue
            sed -i \
                "s|[^ ]*/src-wine/tools/install-sh[^ ]*|/usr/bin/install|g;
                 s|-lwinecrt0|-L${CRT_W64} -L${CRT_LIB} -lwinecrt0|g" \
                "$mf" 2>/dev/null || true
            touch -t 203001010000 "$mf" 2>/dev/null || true
        done
    }

    while [ "$attempt" -le "$max_attempts" ] && [ "$exit_code" -ne 0 ]; do
        msg2 "  redist attempt $attempt/$max_attempts..."
        _freeze_all_stamps "$BUILD" "$VALVE_BUILD"
        _patch_component_makefiles "$BUILD" "$WINECRT_W64" "$WINECRT_LIB"

        podman run --rm \
            -v "$BUILD":"$BUILD" \
            -v "$(dirname "$BUILD")":"$(dirname "$BUILD")" \
            -w "$BUILD" -e MAKEFLAGS \
            ghcr.io/open-wine-components/umu-sdk:latest \
            make -j"$(nproc)" CONTAINER=1 redist \
            > "${LOG_BASE}-${attempt}.log" 2>&1
        exit_code=$?

        if [ "$exit_code" -eq 0 ]; then
            ok "  redist succeeded on attempt $attempt"
        else
            warn "  attempt $attempt failed (exit $exit_code) — see ${LOG_BASE}-${attempt}.log"
            grep -E "error:|Error [0-9]|undefined ref|not found|No such" \
                "${LOG_BASE}-${attempt}.log" 2>/dev/null | tail -5 >&2 || true
            attempt=$((attempt + 1))
            # Touch any new stamps the failed run created
            find "$BUILD" -name ".*-build" -newer "$BUILD/.wine-x86_64-build" \
                2>/dev/null | xargs touch -t 203001010000 2>/dev/null || true
        fi
    done

    if [ "$exit_code" -ne 0 ]; then
        warn "redist failed after $max_attempts attempts"
        warn "Last log: ${LOG_BASE}-$((attempt-1)).log"
        return 1
    fi

    # ── 13. DLL rename (vrclient.dll → vrclient_x64.dll) ─────────────────────
    msg2 "Step 13/13: renaming vrclient.dll → vrclient_x64.dll"
    local VRCLIENT_W64="$BUILD/dst-vrclient-x86_64/lib/wine/x86_64-windows"
    local VRCLIENT_UNIX="$BUILD/dst-vrclient-x86_64/lib/wine/x86_64-unix"
    if [ -f "$VRCLIENT_W64/vrclient.dll" ] && [ ! -f "$VRCLIENT_W64/vrclient_x64.dll" ]; then
        cp "$VRCLIENT_W64/vrclient.dll" "$VRCLIENT_W64/vrclient_x64.dll"
        ok "  vrclient.dll → vrclient_x64.dll"
    fi
    if [ -f "$VRCLIENT_UNIX/vrclient.so" ] && [ ! -f "$VRCLIENT_UNIX/vrclient_x64.so" ]; then
        cp "$VRCLIENT_UNIX/vrclient.so" "$VRCLIENT_UNIX/vrclient_x64.so" 2>/dev/null || true
    fi

    ok "Kron4ek TKG compat redist complete"
    return 0
}

# ══════════════════════════════════════════════════════════════════════════════
#  _kron4ek_tkg_install_redist_to_proton  <BUILD_DIR> <PROTON_PKG_DIR>
#
#  Copies the redist output (lsteamclient, vrclient, steamexe) from the
#  proton-tkg build tree into the assembled Proton package.
# ══════════════════════════════════════════════════════════════════════════════
_kron4ek_tkg_install_redist_to_proton() {
    local BUILD="$1"
    local PKG="$2"

    section "Installing TKG redist into Proton package"

    local WINE_LIB="$PKG/files/lib/wine"
    mkdir -p \
        "$WINE_LIB/x86_64-windows" "$WINE_LIB/x86_64-unix" \
        "$WINE_LIB/i386-windows"   "$WINE_LIB/i386-unix"

    local copied=0
    for src_dir \
        "$BUILD/dst-lsteamclient-x86_64/lib/wine/x86_64-windows" \
        "$BUILD/dst-vrclient-x86_64/lib/wine/x86_64-windows" \
        "$BUILD/dst-steamexe-x86_64/lib/wine/x86_64-windows"; do
        [ -d "$src_dir" ] || continue
        find "$src_dir" -name "*.dll" | while read -r f; do
            cp -f "$f" "$WINE_LIB/x86_64-windows/" && copied=$((copied+1))
        done
    done
    for src_dir \
        "$BUILD/dst-lsteamclient-x86_64/lib/wine/x86_64-unix" \
        "$BUILD/dst-vrclient-x86_64/lib/wine/x86_64-unix"; do
        [ -d "$src_dir" ] || continue
        find "$src_dir" -name "*.so" | while read -r f; do
            cp -f "$f" "$WINE_LIB/x86_64-unix/" 2>/dev/null || true
        done
    done
    for src_dir \
        "$BUILD/dst-lsteamclient-i386/lib/wine/i386-windows" \
        "$BUILD/dst-vrclient-i386/lib/wine/i386-windows"; do
        [ -d "$src_dir" ] || continue
        find "$src_dir" -name "*.dll" | while read -r f; do
            cp -f "$f" "$WINE_LIB/i386-windows/" && copied=$((copied+1))
        done
    done

    # Ensure vrclient_x64.dll name exists
    [ -f "$WINE_LIB/x86_64-windows/vrclient.dll" ] && \
    [ ! -f "$WINE_LIB/x86_64-windows/vrclient_x64.dll" ] && \
        cp "$WINE_LIB/x86_64-windows/vrclient.dll" \
           "$WINE_LIB/x86_64-windows/vrclient_x64.dll" && \
        ok "  vrclient.dll → vrclient_x64.dll"

    ok "Redist DLLs installed into Proton package"
}

# ══════════════════════════════════════════════════════════════════════════════
#  pregen_headers
#  Pre-generate headers that makedep needs before configure/autoreconf runs.
#  Must be called on the source tree BEFORE run_autoreconf.
#
#  Generates three files using scripts bundled in the source tree:
#    include/wine/vulkan.h      — from dlls/winevulkan/make_vulkan  (Python)
#    dlls/ntdll/ntsyscalls.h    — from tools/make_specfiles          (Perl)
#    include/wine/server_protocol.h — from tools/make_requests       (Perl)
# ══════════════════════════════════════════════════════════════════════════════
pregen_headers() {
    local src="$1"
    section "Pre-generating headers"

    # ── wine/vulkan.h ─────────────────────────────────────────────────────────
    local vulkan_out="${src}/include/wine/vulkan.h"
    local vulkan_script="${src}/dlls/winevulkan/make_vulkan"
    if [ ! -f "$vulkan_out" ]; then
        msg2 "Generating wine/vulkan.h ..."
        if [ -f "$vulkan_script" ]; then
            if [ "$DRY_RUN" -eq 0 ]; then
                ( cd "$src" && python3 dlls/winevulkan/make_vulkan ) \
                    || err "make_vulkan failed.
     The script needs python3 and the Vulkan registry XML.
     Inside the container these should both be present.
     Check: python3 --version  and  ls ${src}/dlls/winevulkan/"
                ok "wine/vulkan.h generated"
            else
                dim "  [dry-run] python3 dlls/winevulkan/make_vulkan"
            fi
        else
            warn "make_vulkan not found at ${vulkan_script}"
            warn "wine/vulkan.h will be missing — configure will likely fail."
        fi
    else
        ok "wine/vulkan.h  (already present)"
    fi

    # ── ntsyscalls.h  (Wine 10.x+, not present in all trees) ─────────────────
    local ntsys_out="${src}/dlls/ntdll/ntsyscalls.h"
    local specfiles="${src}/tools/make_specfiles"
    if [ ! -f "$ntsys_out" ] && [ -f "$specfiles" ]; then
        msg2 "Generating ntsyscalls.h ..."
        if [ "$DRY_RUN" -eq 0 ]; then
            ( cd "$src" && perl tools/make_specfiles ) \
                || err "make_specfiles failed. Install: sudo apt install perl"
            ok "ntsyscalls.h generated"
        else
            dim "  [dry-run] perl tools/make_specfiles"
        fi
    else
        ok "ntsyscalls.h  (present or not required by this tree)"
    fi

    # ── server_protocol.h ─────────────────────────────────────────────────────
    local proto_out="${src}/include/wine/server_protocol.h"
    local make_req="${src}/tools/make_requests"
    if [ -f "$make_req" ]; then
        if [ ! -f "$proto_out" ] || [ "$make_req" -nt "$proto_out" ]; then
            msg2 "Generating server_protocol.h ..."
            if [ "$DRY_RUN" -eq 0 ]; then
                ( cd "$src" && perl tools/make_requests ) \
                    || err "make_requests failed. Install: sudo apt install perl"
                ok "server_protocol.h generated"
            else
                dim "  [dry-run] perl tools/make_requests"
            fi
        else
            ok "server_protocol.h  (up to date)"
        fi
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  _install_logged  — run make install with a magenta/cyan progress bar
#
#  Tracks lines matching "tools/install" to count files being installed.
#  Falls back to plain output in non-interactive or --verbose mode.
# ══════════════════════════════════════════════════════════════════════════════
_install_logged() {
    # $@ = make -C <dir> install args

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        run make "$@" install; return
    fi

    # Count total install operations via dry-run
    local _total=0
    if [ -t 1 ] && [ "${VERBOSE_BUILD:-false}" != "true" ]; then
        printf "${C_DIM}  Counting install steps...${C_R}"
        _total=$(
            make "$@" install -n 2>/dev/null \
            | grep -c 'tools/install' || true
        )
        printf "\r\033[K"
        [ "$_total" -eq 0 ] && _total=1
    fi

    if [ -t 1 ] && [ "${VERBOSE_BUILD:-false}" != "true" ]; then
        local _cur=0 _start _now _elapsed _elapsed_str _pct _filled _bar _i
        local _tmp_out _make_exit
        _tmp_out=$(mktemp)
        _start=$(date +%s)

        # Print 2 reserved lines for the install HUD
        printf "\n\n"

        _draw_install() {
            local cur="$1" tot="$2" phase="$3" start="$4"
            [ "$tot" -eq 0 ] && tot=1
            local w=50 f pct bar="" i=0
            f=$(( cur * w / tot )); pct=$(( cur * 100 / tot ))
            while [ "$i" -lt "$f" ]; do bar="${bar}█"; i=$(( i+1 )); done
            while [ "$i" -lt "$w" ]; do bar="${bar}░"; i=$(( i+1 )); done
            local now e estr="0s"
            now=$(date +%s); e=$(( now - start ))
            if   [ "$e" -ge 3600 ]; then estr="$(( e/3600 ))h$(( (e%3600)/60 ))m$(( e%60 ))s"
            elif [ "$e" -ge 60   ]; then estr="$(( e/60 ))m$(( e%60 ))s"
            else                         estr="${e}s"; fi
            printf "\033[2A"
            printf "\033[K${C_MAG}  [%s] %3d%%${C_R}  ${C_DIM}(%d / %d)${C_R}\n" \
                "$bar" "$pct" "$cur" "$tot"
            printf "\033[K  ${C_CYN}elapsed${C_R} %-10s  ${C_CYN}installing${C_R} %s\n" \
                "$estr" "$phase"
        }

        _draw_install 0 "$_total" "starting..." "$_start"

        set +e
        make "$@" install > "$_tmp_out" 2>&1 &
        local _make_pid=$!

        while kill -0 "$_make_pid" 2>/dev/null || [ -s "$_tmp_out" ]; do
            while IFS= read -r _line; do
                printf '%s\n' "$_line" >> "${BUILD_LOG:-/dev/null}"
                if printf '%s' "$_line" | grep -q 'tools/install'; then
                    _cur=$(( _cur + 1 ))
                    # Extract last path component being installed
                    local _dest
                    _dest=$(printf '%s' "$_line" | grep -oE '[^ ]+$' | tail -1)
                    _dest="${_dest##*/}"
                    _draw_install "$_cur" "$_total" "$_dest" "$_start"
                fi
            done < "$_tmp_out"
            kill -0 "$_make_pid" 2>/dev/null && > "$_tmp_out" || break
            sleep 0.1
        done

        wait "$_make_pid"; _make_exit=$?
        # drain remaining
        while IFS= read -r _line; do
            printf '%s\n' "$_line" >> "${BUILD_LOG:-/dev/null}"
        done < "$_tmp_out"
        rm -f "$_tmp_out"
        set -e

        _draw_install "$_total" "$_total" "complete ✓" "$_start"
        printf "\n"

        [ "$_make_exit" -ne 0 ] && return "$_make_exit"
    else
        make "$@" install 2>&1 | tee -a "${BUILD_LOG:-/dev/null}"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  install_wine  — make install the built Wine into the files/ directory
# ══════════════════════════════════════════════════════════════════════════════
install_wine() {
    local build_run_dir="$1"
    local install_prefix="$2"

    section "Installing Wine"
    mkdir -p "$install_prefix"

    local build64="${build_run_dir}/wine64"
    local build32="${build_run_dir}/wine32"

    if [ -d "$build64" ]; then
        msg2 "make install  (64-bit)"
        _install_logged -C "$build64"
        ok "64-bit Wine installed"
    fi

    if [ "${SKIP_32BIT}" != "true" ] && [ -d "$build32" ]; then
        msg2 "make install  (32-bit)"
        _install_logged -C "$build32"
        ok "32-bit Wine installed"
    fi

    ok "Wine installed to: $install_prefix"
}

# ══════════════════════════════════════════════════════════════════════════════
#  _write_build_manifest  — record this build in buildz/builds.log
# ══════════════════════════════════════════════════════════════════════════════
_write_build_manifest() {
    local install_prefix="$1"
    local elapsed_fmt="$2"
    local manifest="${DEST_ROOT}/builds.log"
    mkdir -p "${DEST_ROOT}"
    {
        printf '%-25s  source=%-30s  elapsed=%s  date=%s\n' \
            "$(basename "$install_prefix")" \
            "${WINE_SOURCE_KEY}" \
            "$elapsed_fmt" \
            "$(date '+%Y-%m-%d %H:%M:%S')"
    } >> "$manifest"
}

# ══════════════════════════════════════════════════════════════════════════════
#  print_summary
# ══════════════════════════════════════════════════════════════════════════════
print_summary() {
    local install_prefix="$1"
    local elapsed_fmt="$2"

    section "Build Summary"
    ok "Build complete in ${elapsed_fmt}"
    printf "\n"
    printf "  ${C_B}Proton name  :${C_R} %s\n" "$(basename "$install_prefix")"
    printf "  ${C_B}Install path :${C_R} %s\n" "$install_prefix"

    local wine_bin="${install_prefix}/files/bin/wine"
    if [ -x "$wine_bin" ]; then
        local wine_ver
        wine_ver="$("$wine_bin" --version 2>/dev/null || printf 'unknown')"
        printf "  ${C_B}Wine version :${C_R} %s\n" "$wine_ver"
    fi

    # Phase 2 component status
    printf "\n  ${C_B}Component status:${C_R}\n"
    printf "    ${C_GRN}✓${C_R}  proton-wine   — built and installed\n"
    if [ "${DXVK_SOURCE_KEY}" != "none" ]; then
        printf "    ${C_YLW}◌${C_R}  DXVK          — Phase 2 (not yet built)\n"
    else
        printf "    ${C_DIM}-${C_R}  DXVK          — skipped (--dxvk none)\n"
    fi
    if [ "${VKD3D_SOURCE_KEY}" != "none" ]; then
        printf "    ${C_YLW}◌${C_R}  VKD3D-Proton  — Phase 2 (not yet built)\n"
    else
        printf "    ${C_DIM}-${C_R}  VKD3D-Proton  — skipped (--vkd3d none)\n"
    fi

    printf "\n  ${C_B}To use with Steam:${C_R}\n"
    printf "    cp -r %s\n" "$install_prefix"
    printf "       ~/.local/share/Steam/compatibilitytools.d/\n"
    printf "    Then restart Steam and enable in game Properties → Compatibility.\n"
    printf "\n"
}

# ══════════════════════════════════════════════════════════════════════════════
#  Source menu  — interactive selector when --source is not given
# ══════════════════════════════════════════════════════════════════════════════
pick_source() {
    section "Source selection"

    if command -v fzf >/dev/null 2>&1; then
        local picked
        picked=$(
            for k in "${WINE_SOURCE_KEYS[@]}"; do
                printf '%s\t%s\n' "$k" "${WINE_SOURCE_DESC[$k]}"
            done \
            | fzf \
                --prompt="Wine source > " \
                --header="Select a proton-wine source" \
                --with-nth=2 \
                --delimiter=$'\t' \
                --height=40% \
                --border \
            || true
        )
        [ -n "$picked" ] || err "No source selected."
        WINE_SOURCE_KEY="$(printf '%s' "$picked" | cut -d$'\t' -f1)"
    else
        printf "\n  ${C_B}Select a proton-wine source:${C_R}\n\n"
        PS3="  Source: "
        local -a menu_keys=()
        local -a menu_desc=()
        for k in "${WINE_SOURCE_KEYS[@]}"; do
            menu_keys+=("$k")
            menu_desc+=("${WINE_SOURCE_DESC[$k]}")
        done
        local choice
        select choice in "${menu_desc[@]}"; do
            [ -z "$choice" ] && continue
            local i
            for i in "${!menu_desc[@]}"; do
                [ "${menu_desc[$i]}" = "$choice" ] && \
                    WINE_SOURCE_KEY="${menu_keys[$i]}" && break
            done
            [ -n "$WINE_SOURCE_KEY" ] && break
        done
        PS3=""
    fi
    ok "Selected source: ${WINE_SOURCE_KEY}"
}

# ══════════════════════════════════════════════════════════════════════════════
#  pick_build_name  — interactive prompt for the tool name
#
#  Asks for a base name (e.g. "looni-proton" or "my-gaming-proton").
#  The actual Wine version number is appended automatically after the build,
#  so the final directory name will be e.g. "looni-proton-11.4.r0.gabcdef".
#  Skipped when --name was given on the command line or in non-interactive mode.
# ══════════════════════════════════════════════════════════════════════════════
pick_build_name() {
    # Only prompt interactively when stdin is a terminal and --name wasn't given
    [ -t 0 ] || return 0
    [ -z "$BUILD_NAME" ] || return 0

    section "Tool name"
    printf "  Enter a base name for this Proton build.\n"
    printf "  The Wine version number will be appended automatically.\n"
    printf "  ${C_DIM}Example: looni-proton  →  looni-proton-11.4.r0.gabcdef${C_R}\n\n"
    printf "  ${C_B}Base name${C_R} [default: looni-proton]: "

    local _input
    read -r _input
    if [ -n "$_input" ]; then
        # Sanitize: spaces to hyphens, strip characters invalid in dir names
        BUILD_NAME="$(printf '%s' "$_input" \
            | tr ' ' '-' \
            | tr -cd 'a-zA-Z0-9._-' \
            | sed 's/--*/-/g; s/^-//; s/-$//')"
        ok "Build name: ${BUILD_NAME}"
    else
        BUILD_NAME="looni-proton"
        ok "Build name: ${BUILD_NAME}  (default)"
    fi
}
print_banner

# ── Early dispatch: --kron4ek-redist standalone mode ─────────────────────────
if [ -n "${_KRON4EK_REDIST_BUILD:-}" ]; then
    [ -d "$_KRON4EK_REDIST_BUILD" ] || \
        err "BUILD dir not found: $_KRON4EK_REDIST_BUILD"
    _kron4ek_tkg_compat_redist "$_KRON4EK_REDIST_BUILD"
    if [ -n "${_KRON4EK_REDIST_PKG:-}" ] && [ -d "$_KRON4EK_REDIST_PKG" ]; then
        _kron4ek_tkg_install_redist_to_proton "$_KRON4EK_REDIST_BUILD" \
            "$_KRON4EK_REDIST_PKG"
    fi
    exit 0
fi

# Validate wine source key if provided
if [ -n "$WINE_SOURCE_KEY" ]; then
    if [ -z "${WINE_SOURCE_URL[$WINE_SOURCE_KEY]+x}" ]; then
        err "Unknown --source: '${WINE_SOURCE_KEY}'
     Valid options: ${WINE_SOURCE_KEYS[*]}"
    fi
else
    # Interactive source picker
    if [ -t 0 ]; then
        pick_source
    else
        err "--source is required in non-interactive mode.
     Use: --source proton-wine  or  --source proton-wine-experimental"
    fi
fi

# Validate DXVK key
if [ -z "${DXVK_SOURCE_URL[$DXVK_SOURCE_KEY]+x}" ]; then
    err "Unknown --dxvk: '${DXVK_SOURCE_KEY}'
 Valid options: dxvk | dxvk-async | none"
fi

# Validate VKD3D key
if [ -z "${VKD3D_SOURCE_URL[$VKD3D_SOURCE_KEY]+x}" ]; then
    err "Unknown --vkd3d: '${VKD3D_SOURCE_KEY}'
 Valid options: vkd3d-proton | none"
fi

# ── Dependency check ──────────────────────────────────────────────────────────
check_deps

# ── Build name ────────────────────────────────────────────────────────────────
pick_build_name

# ══════════════════════════════════════════════════════════════════════════════
#  pick_build_options  — interactive wizard for build tuning
# ══════════════════════════════════════════════════════════════════════════════
pick_build_options() {
    [ -t 0 ] || return 0

    section "Build options"

    # Jobs
    local _cpu_count; _cpu_count=$(nproc)
    printf "  ${C_CYN}Jobs${C_R} (parallel compile threads)\n"
    printf "  Your CPU has ${C_B}${_cpu_count}${C_R} threads.\n"
    printf "  ${C_DIM}Suggestions: all=${_cpu_count}  leave-one-free=$(( _cpu_count - 1 ))  half=$(( _cpu_count / 2 ))${C_R}\n"
    printf "  Jobs [default: ${_cpu_count}]: "
    local _j; read -r _j
    if [ -n "$_j" ] && [ "$_j" -gt 0 ] 2>/dev/null; then
        JOBS="$_j"; ok "Jobs: ${JOBS}"
    else
        JOBS="$_cpu_count"; ok "Jobs: ${JOBS}  (default)"
    fi
    printf "\n"

    # 32-bit
    printf "  ${C_CYN}32-bit build${C_R}  Needed for 32-bit games.\n"
    printf "  Skip 32-bit? [y/N]: "
    local _s32; read -r _s32
    case "$_s32" in
        [yY]*) SKIP_32BIT=true;  ok "32-bit: skipped" ;;
        *)     SKIP_32BIT=false; ok "32-bit: enabled" ;;
    esac
    printf "\n"

    # Build type
    printf "  ${C_CYN}Build type${C_R}\n"
    printf "    ${C_B}release${C_R}         — optimised, stripped  ${C_DIM}(default)${C_R}\n"
    printf "    ${C_B}debugoptimized${C_R}  — optimised + debug symbols\n"
    printf "    ${C_B}debug${C_R}           — no optimisation, full symbols\n"
    printf "  Build type [release]: "
    local _bt; read -r _bt
    case "$_bt" in
        debug|debugoptimized) BUILD_TYPE="$_bt"; ok "Build type: ${BUILD_TYPE}" ;;
        *) BUILD_TYPE="release"; ok "Build type: release  (default)" ;;
    esac
    printf "\n"

    # ccache
    if command -v ccache >/dev/null 2>&1; then
        printf "  ${C_CYN}ccache${C_R}  Disable ccache? [y/N]: "
        local _cc; read -r _cc
        case "$_cc" in
            [yY]*) NO_CCACHE=true;  ok "ccache: disabled" ;;
            *)     NO_CCACHE=false; ok "ccache: enabled" ;;
        esac
        printf "\n"
    fi

    # Symbols
    printf "  ${C_CYN}Debug symbols${C_R}  Keep symbols? (larger binaries)  [y/N]: "
    local _ks; read -r _ks
    case "$_ks" in
        [yY]*) KEEP_SYMBOLS=true;  ok "Symbols: kept" ;;
        *)     KEEP_SYMBOLS=false; ok "Symbols: stripped  (default)" ;;
    esac
    printf "\n"

    # -march=native
    printf "  ${C_CYN}-march=native${C_R}  Optimise for this CPU only? (non-portable)  [y/N]: "
    local _nm; read -r _nm
    case "$_nm" in
        [yY]*) NATIVE_MARCH=true;  ok "-march=native: enabled" ;;
        *)     NATIVE_MARCH=false; ok "-march=native: disabled  (default)" ;;
    esac
    printf "\n"

    # LTO
    printf "  ${C_CYN}LTO${C_R}  Link-time optimisation? (slow link, smaller binary)  [y/N]: "
    local _lto; read -r _lto
    case "$_lto" in
        [yY]*) LTO=true;  ok "LTO: enabled" ;;
        *)     LTO=false; ok "LTO: disabled  (default)" ;;
    esac
    printf "\n"

    ok "Build options set:"
    msg2 "Jobs=${JOBS}  32bit=$([ "$SKIP_32BIT" = true ] && echo skip || echo yes)  type=${BUILD_TYPE}  ccache=$([ "$NO_CCACHE" = true ] && echo off || echo on)  symbols=$([ "$KEEP_SYMBOLS" = true ] && echo keep || echo strip)  native=${NATIVE_MARCH}  lto=${LTO}"
}

# ── Build options wizard ──────────────────────────────────────────────────────
pick_build_options

# ── Export toggles for build-core and packager ────────────────────────────────
export JOBS NO_CCACHE KEEP_SYMBOLS BUILD_TYPE NATIVE_MARCH LTO SKIP_32BIT

# ── Disk space preflight ──────────────────────────────────────────────────────
section "System preflight"
check_disk_space "$DEST_ROOT"

# ── Resolve build directories ─────────────────────────────────────────────────
# BUILD_NAME is either from --name, pick_build_name, or the source key default.
# The Wine version number is appended to the final package dir after the build.
[ -n "$BUILD_NAME" ] || BUILD_NAME="looni-proton"
WINE_SOURCE_DIR="${SRC_ROOT}/${WINE_SOURCE_KEY}"
BUILD_RUN_DIR="${DEST_ROOT}/build-run/${BUILD_NAME}"
# Proton's Wine installs to <package>/files/ — not the package root
PROTON_PACKAGE_DIR="${DEST_ROOT}/install/${BUILD_NAME}"
WINE_INSTALL_PREFIX="${PROTON_PACKAGE_DIR}/files"
BUILD_LOG="${BUILD_RUN_DIR}/build.log"

msg2 "Wine source dir  : ${WINE_SOURCE_DIR}"
msg2 "Build run dir    : ${BUILD_RUN_DIR}"
msg2 "Proton package   : ${PROTON_PACKAGE_DIR}"
msg2 "Wine prefix      : ${WINE_INSTALL_PREFIX}"

mkdir -p "$DEST_ROOT" "$SRC_ROOT" "$BUILD_RUN_DIR" "$WINE_INSTALL_PREFIX"

# ── Determine wine branch ─────────────────────────────────────────────────────
_wine_branch="${WINE_SOURCE_BRANCH[$WINE_SOURCE_KEY]}"
[ -n "$WINE_SOURCE_BRANCH_ARG" ] && _wine_branch="$WINE_SOURCE_BRANCH_ARG"

# Interactive version picker (only for proton-wine stable, not experimental)
pick_wine_version "${WINE_SOURCE_URL[$WINE_SOURCE_KEY]}" "$WINE_SOURCE_KEY"
# _wine_branch may have been updated by pick_wine_version

# ── Fetch proton-wine source ──────────────────────────────────────────────────
section "Fetching proton-wine"
# Full clone required: Valve's fork needs complete history for git describe
# to produce proper version strings (wine-8.0-15630-gabcdef).
msg2 "Full clone — required for Valve version strings (git describe)"
fetch_source \
    "${WINE_SOURCE_URL[$WINE_SOURCE_KEY]}" \
    "$_wine_branch" \
    "$WINE_SOURCE_DIR" \
    "false"

[ -d "$WINE_SOURCE_DIR" ] || \
    err "Wine source directory not found after fetch: $WINE_SOURCE_DIR"

[ -f "${WINE_SOURCE_DIR}/configure.ac" ] || \
    err "configure.ac not found in: $WINE_SOURCE_DIR
     This does not look like a Wine source tree."

# ── PHASE 2 HOOK: Fetch DXVK ─────────────────────────────────────────────────
if [ "${DXVK_SOURCE_KEY}" != "none" ]; then
    section "DXVK source  [Phase 2]"
    DXVK_SOURCE_DIR="${SRC_ROOT}/dxvk-${DXVK_SOURCE_KEY}"
    _dxvk_branch="${DXVK_BRANCH_ARG:-}"
    msg2 "Source key : ${DXVK_SOURCE_KEY}"
    msg2 "Source dir : ${DXVK_SOURCE_DIR}"
    msg2 "URL        : ${DXVK_SOURCE_URL[$DXVK_SOURCE_KEY]}"
    fetch_source \
        "${DXVK_SOURCE_URL[$DXVK_SOURCE_KEY]}" \
        "$_dxvk_branch" \
        "$DXVK_SOURCE_DIR" \
        "true"
    ok "DXVK source fetched"
    export DXVK_SOURCE_DIR DXVK_SOURCE_KEY
fi

# ── PHASE 2 HOOK: Fetch VKD3D-Proton ─────────────────────────────────────────
if [ "${VKD3D_SOURCE_KEY}" != "none" ]; then
    section "VKD3D-Proton source  [Phase 2]"
    VKD3D_SOURCE_DIR="${SRC_ROOT}/vkd3d-proton"
    _vkd3d_branch="${VKD3D_BRANCH_ARG:-}"
    msg2 "Source key : ${VKD3D_SOURCE_KEY}"
    msg2 "Source dir : ${VKD3D_SOURCE_DIR}"
    msg2 "URL        : ${VKD3D_SOURCE_URL[$VKD3D_SOURCE_KEY]}"
    fetch_source \
        "${VKD3D_SOURCE_URL[$VKD3D_SOURCE_KEY]}" \
        "$_vkd3d_branch" \
        "$VKD3D_SOURCE_DIR" \
        "true"
    ok "VKD3D-Proton source fetched"
    export VKD3D_SOURCE_DIR VKD3D_SOURCE_KEY
fi

# ── Start build timer ─────────────────────────────────────────────────────────
_BUILD_START=$(date +%s)

# ══════════════════════════════════════════════════════════════════════════════
#  COMPILE + INSTALL  — proton-wine  (skipped with --dxvk-only / --vkd3d-only)
# ══════════════════════════════════════════════════════════════════════════════
if [ "$SKIP_WINE_BUILD" = "true" ]; then
    section "Skipping Wine build (--dxvk-only / --vkd3d-only)"
    # Verify a prior Wine install actually exists before proceeding
    [ -f "${WINE_INSTALL_PREFIX}/bin/wine" ] || \
        err "No prior Wine install found at: ${WINE_INSTALL_PREFIX}/bin/wine
     Run a full build first before using --dxvk-only / --vkd3d-only."
    ok "Using existing Wine install at: ${WINE_INSTALL_PREFIX}"
else
    # ── Pre-build fixes and header generation ──────────────────────────────
    section "Pre-build headers"
    fix_opencl_headers
    pregen_headers "$WINE_SOURCE_DIR"

    # ── autoreconf ──────────────────────────────────────────────────────────
    if [ "$RESUME" = "true" ] && [ -f "${BUILD_RUN_DIR}/wine64/Makefile" ]; then
        msg2 "--resume: skipping autoreconf"
    else
        run_autoreconf "$WINE_SOURCE_DIR"
    fi

    # ── Validate build scripts ──────────────────────────────────────────────
    [ -f "$BUILD_CORE" ] || \
        err "Build core script not found: $BUILD_CORE
     Expected alongside proton-builder.sh as proton-build-core.sh"
    [ -x "$BUILD_CORE" ] || chmod +x "$BUILD_CORE"

    [ -f "$PACKAGER" ] || \
        err "Packager script not found: $PACKAGER
     Expected alongside proton-builder.sh as proton-package.sh"
    [ -x "$PACKAGER" ] || chmod +x "$PACKAGER"

    # ── Load configuration ──────────────────────────────────────────────────
    [ -f "$CUSTOM_CFG" ] || \
        err "Configuration file not found: $CUSTOM_CFG
     Copy and edit proton-customization.cfg — see the README for details."
    # shellcheck source=/dev/null
    source "$CUSTOM_CFG"

    # ── Export env to build-core ────────────────────────────────────────────
    export WINE_SOURCE="$WINE_SOURCE_DIR"
    export PREFIX="$WINE_INSTALL_PREFIX"
    export WINE_BUILD="${BUILD_NAME//-/_}"
    export PROTON_SOURCE_KEY="$WINE_SOURCE_KEY"
    export JOBS
    export SKIP_32BIT
    export BUILD_RUN_DIR
    export CUSTOM_CFG
    export RESUME
    export BUILD_LOG

    # ── Compile ─────────────────────────────────────────────────────────────
    section "Compiling proton-wine"
    msg "Handing off to: $BUILD_CORE"
    mkdir -p "$BUILD_RUN_DIR"
    cd "$DEST_ROOT"
    "$BUILD_CORE"

    # ── Install ─────────────────────────────────────────────────────────────
    install_wine "$BUILD_RUN_DIR" "$WINE_INSTALL_PREFIX"

    # ── Kron4ek TKG: run compat redist + install DLLs ───────────────────────
    # For kron4ek-tkg builds the proton-tkg build system generates lsteamclient,
    # vrclient, steamexe via  make CONTAINER=1 redist  rather than the standard
    # Wine make install.  Apply all Kron4ek compat patches and run it here.
    if [ "$WINE_SOURCE_KEY" = "kron4ek-tkg" ]; then
        section "Kron4ek TKG — running compat redist"
        # Locate the proton-tkg build dir (proton-tkg clones it alongside src-wine)
        local _tkg_build=""
        for _candidate in \
            "$WINE_SOURCE_DIR/../build" \
            "$SRC_ROOT/proton-tkg/proton-tkg/external-resources/Proton/build" \
            "$SRC_ROOT/kron4ek-tkg/proton-tkg/external-resources/Proton/build"; do
            if [ -f "$_candidate/../Makefile.in" ]; then
                _tkg_build="$_candidate"
                break
            fi
        done
        if [ -n "$_tkg_build" ]; then
            msg2 "proton-tkg build dir: $_tkg_build"
            _kron4ek_tkg_compat_redist "$_tkg_build" && \
                _kron4ek_tkg_install_redist_to_proton "$_tkg_build" \
                    "$PROTON_PACKAGE_DIR" || \
                warn "Kron4ek TKG redist failed — lsteamclient/vrclient may be missing"
        else
            warn "Could not locate proton-tkg build dir — skipping redist"
            warn "Run manually:  $0 --kron4ek-redist <BUILD_DIR> $PROTON_PACKAGE_DIR"
        fi
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
#  PHASE 2 HOOK: Build DXVK
#
#  When proton-dxvk-build.sh is implemented, it will be called here.
#  It receives the DXVK source dir and the Proton package dir, compiles
#  DXVK with Meson + MinGW, and places the .dll files under:
#    ${PROTON_PACKAGE_DIR}/files/lib/wine/dxvk/   (32-bit)
#    ${PROTON_PACKAGE_DIR}/files/lib64/wine/dxvk/  (64-bit)
# ══════════════════════════════════════════════════════════════════════════════
section "DXVK build  [Phase 2]"
if [ "${SKIP_DXVK:-false}" = "true" ]; then
    msg2 "Skipping DXVK (--vkd3d-only)"
elif [ "${REINSTALL_COMPONENTS:-false}" = "true" ]; then
    section "DXVK reinstall from existing build"
    _dxvk_build_64="${SRC_ROOT}/dxvk-${DXVK_SOURCE_KEY}/build/x64"
    _dxvk_build_32="${SRC_ROOT}/dxvk-${DXVK_SOURCE_KEY}/build/x32"
    _dxvk_dest_64="${WINE_INSTALL_PREFIX}/lib64/wine/dxvk"
    _dxvk_dest_32="${WINE_INSTALL_PREFIX}/lib/wine/dxvk"
    if [ ! -d "$_dxvk_build_64" ]; then
        warn "DXVK 64-bit build dir not found: $_dxvk_build_64"
        warn "Run --dxvk-only first to build DXVK"
    else
        mkdir -p "$_dxvk_dest_64" "$_dxvk_dest_32"
        find "$_dxvk_build_64" -name '*.dll' -exec cp {} "$_dxvk_dest_64/" \;
        _n=$(find "$_dxvk_dest_64" -name '*.dll' | wc -l)
        ok "DXVK 64-bit: ${_n} DLLs installed"
        if [ -d "$_dxvk_build_32" ]; then
            find "$_dxvk_build_32" -name '*.dll' -exec cp {} "$_dxvk_dest_32/" \;
            _n=$(find "$_dxvk_dest_32" -name '*.dll' | wc -l)
            ok "DXVK 32-bit: ${_n} DLLs installed"
        fi
    fi
elif [ "${DXVK_SOURCE_KEY}" != "none" ]; then
    if [ -x "$DXVK_BUILDER" ]; then
        export PROTON_PACKAGE_DIR
        "$DXVK_BUILDER"
    else
        warn "DXVK build (Phase 2) — proton-dxvk-build.sh not yet implemented"
        warn "D3D9/D3D10/D3D11 games will fall back to WineD3D (software Vulkan wrapper)"
        warn "DXVK source is available at: ${DXVK_SOURCE_DIR:-${SRC_ROOT}/dxvk-${DXVK_SOURCE_KEY}}"
    fi
else
    msg2 "DXVK skipped (--dxvk none)"
fi

# ══════════════════════════════════════════════════════════════════════════════
#  PHASE 2 HOOK: Build VKD3D-Proton
#
#  When proton-vkd3d-build.sh is implemented, it will be called here.
#  It compiles VKD3D-Proton with Meson + MinGW and places d3d12.dll under:
#    ${PROTON_PACKAGE_DIR}/files/lib/wine/vkd3d-proton/   (32-bit)
#    ${PROTON_PACKAGE_DIR}/files/lib64/wine/vkd3d-proton/  (64-bit)
# ══════════════════════════════════════════════════════════════════════════════
section "VKD3D-Proton build  [Phase 2]"
if [ "${REINSTALL_COMPONENTS:-false}" = "true" ]; then
    section "VKD3D-Proton reinstall from existing build"
    _vkd3d_build_64="${SRC_ROOT}/vkd3d-proton/build/x64"
    _vkd3d_build_32="${SRC_ROOT}/vkd3d-proton/build/x32"
    _vkd3d_dest_64="${WINE_INSTALL_PREFIX}/lib64/wine/vkd3d-proton"
    _vkd3d_dest_32="${WINE_INSTALL_PREFIX}/lib/wine/vkd3d-proton"
    if [ ! -d "$_vkd3d_build_64" ]; then
        warn "VKD3D-Proton 64-bit build dir not found: $_vkd3d_build_64"
        warn "Run --vkd3d-only first to build VKD3D-Proton"
    else
        mkdir -p "$_vkd3d_dest_64" "$_vkd3d_dest_32"
        find "$_vkd3d_build_64" -name '*.dll' -exec cp {} "$_vkd3d_dest_64/" \;
        _n=$(find "$_vkd3d_dest_64" -name '*.dll' | wc -l)
        ok "VKD3D-Proton 64-bit: ${_n} DLLs installed"
        if [ -d "$_vkd3d_build_32" ]; then
            find "$_vkd3d_build_32" -name '*.dll' -exec cp {} "$_vkd3d_dest_32/" \;
            _n=$(find "$_vkd3d_dest_32" -name '*.dll' | wc -l)
            ok "VKD3D-Proton 32-bit: ${_n} DLLs installed"
        fi
    fi
elif [ "${VKD3D_SOURCE_KEY}" != "none" ]; then
    if [ -x "$VKD3D_BUILDER" ]; then
        export PROTON_PACKAGE_DIR
        "$VKD3D_BUILDER"
    else
        warn "VKD3D-Proton build (Phase 2) — proton-vkd3d-build.sh not yet implemented"
        warn "DirectX 12 games will not work until Phase 2 is complete"
        warn "VKD3D-Proton source is available at: ${VKD3D_SOURCE_DIR:-${SRC_ROOT}/vkd3d-proton}"
    fi
else
    msg2 "VKD3D-Proton skipped (--vkd3d none)"
fi

# ══════════════════════════════════════════════════════════════════════════════
#  PACKAGE  — generate Steam Proton layout
# ══════════════════════════════════════════════════════════════════════════════
section "Packaging Proton"
export PROTON_PACKAGE_DIR WINE_INSTALL_PREFIX
export DXVK_SOURCE_KEY VKD3D_SOURCE_KEY
export BUILD_NAME
"$PACKAGER"

# ══════════════════════════════════════════════════════════════════════════════
#  Version rename  — append actual wine version string to the package dir
#  Final name: <BUILD_NAME>-<version>  e.g. looni-proton-11.4.r0.gabcdef
# ══════════════════════════════════════════════════════════════════════════════
_wine_bin="${WINE_INSTALL_PREFIX}/bin/wine"
if [ -x "$_wine_bin" ]; then
    _raw_ver="$("$_wine_bin" --version 2>/dev/null || true)"
    if [ -n "$_raw_ver" ]; then
        # Strip leading "wine-" prefix — user just wants the number
        _clean_ver="${_raw_ver#wine-}"
        _clean_ver="$(printf '%s' "$_clean_ver" \
            | tr ' ' '-' | tr -d '()[]:'  | sed 's/--*/-/g; s/-$//')"
        _new_pkg="${DEST_ROOT}/install/${BUILD_NAME}-${_clean_ver}"
        if [ "$PROTON_PACKAGE_DIR" != "$_new_pkg" ] && [ ! -e "$_new_pkg" ]; then
            mv "$PROTON_PACKAGE_DIR" "$_new_pkg"
            PROTON_PACKAGE_DIR="$_new_pkg"
            WINE_INSTALL_PREFIX="${_new_pkg}/files"
            ok "Package: ${_new_pkg}"
        fi
    fi
fi

# ── Summary + manifest ────────────────────────────────────────────────────────
_BUILD_END=$(date +%s)
_ELAPSED=$(( _BUILD_END - _BUILD_START ))
_ELAPSED_FMT="$(( _ELAPSED / 3600 ))h $(( (_ELAPSED % 3600) / 60 ))m $(( _ELAPSED % 60 ))s"
print_summary "$PROTON_PACKAGE_DIR" "$_ELAPSED_FMT"
_write_build_manifest "$PROTON_PACKAGE_DIR" "$_ELAPSED_FMT"
