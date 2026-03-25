#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║         looni-neutron_builder  •  DXVK build                               ║
# ║   Cross-compiles DXVK (D3D9/10/11 → Vulkan) for both x86 and x86_64      ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Required env vars (set by neutron-builder.sh):
#   DXVK_SOURCE_DIR     — path to the cloned DXVK source tree
#   DXVK_SOURCE_KEY     — dxvk | dxvk-async
#   NEUTRON_PACKAGE_DIR  — root of the Proton package being assembled
#
# DXVK output layout inside the Proton package:
#   files/lib/wine/dxvk/   — 32-bit .dll files (d3d9, d3d10*, d3d11, dxgi)
#   files/lib64/wine/dxvk/ — 64-bit .dll files
#
# HOW THIS WORKS:
#   DXVK bundles its own Vulkan, SPIRV, and DirectX headers as git submodules
#   under include/vulkan/, include/spirv/, include/native/directx/.
#   We initialize those submodules first, then create thin compiler wrapper
#   scripts that pass -I<dxvk>/include to every MinGW compiler invocation.
#   Meson's internal has_header() checks use those wrappers, so header
#   detection works correctly without touching system paths or pkg-config.
#
set -euo pipefail

# ── Output helpers ────────────────────────────────────────────────────────────
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    _R="\033[0m" _B="\033[1m" _GRN="\033[1;32m" _BLU="\033[1;34m"
    _YLW="\033[1;33m" _RED="\033[1;31m" _DIM="\033[2m"
else
    _R="" _B="" _GRN="" _BLU="" _YLW="" _RED="" _DIM=""
fi
msg()  { printf "${_GRN}==> ${_R}${_B}%s${_R}\n" "$*"; }
msg2() { printf "${_BLU} -> ${_R}%s\n" "$*"; }
ok()   { printf "${_GRN} ✓  ${_R}%s\n" "$*"; }
warn() { printf "${_YLW}warn${_R} %s\n" "$*" >&2; }
err()  { printf "${_RED}ERR!${_R} %s\n" "$*" >&2; exit 1; }
sep()  { printf "\n${_BLU}${_B}── %s ──${_R}\n" "$*"; }

# ── Validate required env ─────────────────────────────────────────────────────
: "${DXVK_SOURCE_DIR:?DXVK_SOURCE_DIR must be set to the DXVK source tree}"
: "${NEUTRON_PACKAGE_DIR:?NEUTRON_PACKAGE_DIR must be set to the Proton package root}"
: "${DXVK_SOURCE_KEY:=dxvk}"
: "${JOBS:=$(nproc)}"

[ -d "$DXVK_SOURCE_DIR" ] || \
    err "DXVK source directory not found: $DXVK_SOURCE_DIR"
[ -f "${DXVK_SOURCE_DIR}/meson.build" ] || \
    err "meson.build not found in: $DXVK_SOURCE_DIR"

# ── Paths ─────────────────────────────────────────────────────────────────────
DXVK_DEST_32="${NEUTRON_PACKAGE_DIR}/files/lib/wine/dxvk"
DXVK_DEST_64="${NEUTRON_PACKAGE_DIR}/files/lib64/wine/dxvk"
BUILD_DIR_32="${DXVK_SOURCE_DIR}/build/x32"
BUILD_DIR_64="${DXVK_SOURCE_DIR}/build/x64"
DXVK_INCLUDE_DIR="${DXVK_SOURCE_DIR}/include"
WRAPPER_DIR="${DXVK_SOURCE_DIR}/.compiler-wrappers"

MINGW64_CC="${MINGW_CC_64:-x86_64-w64-mingw32-gcc}"
MINGW64_CXX="${MINGW_CXX_64:-x86_64-w64-mingw32-g++}"
MINGW32_CC="${MINGW_CC_32:-i686-w64-mingw32-gcc}"
MINGW32_CXX="${MINGW_CXX_32:-i686-w64-mingw32-g++}"

sep "DXVK build  (${DXVK_SOURCE_KEY})"
msg2 "Source dir  : ${DXVK_SOURCE_DIR}"
msg2 "64-bit dest : ${DXVK_DEST_64}"
msg2 "32-bit dest : ${DXVK_DEST_32}"
msg2 "Jobs        : ${JOBS}"

# ══════════════════════════════════════════════════════════════════════════════
#  Auto-detect pre-built DLLs
#
#  If DLLs already exist in the expected build output directories, skip the
#  full Meson + Ninja build and install them directly.  This covers the common
#  case where DXVK was built in a prior run and the user just wants to
#  (re)package it into a new Wine build without rebuilding from source.
#
#  Pass FORCE_REBUILD=true (or --dxvk-only from neutron-builder.sh) to skip
#  this check and always rebuild from source.
# ══════════════════════════════════════════════════════════════════════════════
_dxvk_prebuilt_count_64=$(find "$BUILD_DIR_64" -name '*.dll' 2>/dev/null | wc -l || true)
_dxvk_prebuilt_count_32=$(find "$BUILD_DIR_32" -name '*.dll' 2>/dev/null | wc -l || true)

if [ "${FORCE_REBUILD:-false}" != "true" ] \
   && [ "$_dxvk_prebuilt_count_64" -gt 0 ]; then
    sep "DXVK — installing from pre-built DLLs"
    ok "Found ${_dxvk_prebuilt_count_64} pre-built 64-bit DLLs in: ${BUILD_DIR_64}"
    mkdir -p "$DXVK_DEST_64" "$DXVK_DEST_32"
    find "$BUILD_DIR_64" -name '*.dll' -exec cp {} "$DXVK_DEST_64/" \;
    _n=$(find "$DXVK_DEST_64" -name '*.dll' | wc -l)
    ok "DXVK 64-bit installed: ${_n} DLLs"
    if [ "$_dxvk_prebuilt_count_32" -gt 0 ]; then
        ok "Found ${_dxvk_prebuilt_count_32} pre-built 32-bit DLLs in: ${BUILD_DIR_32}"
        find "$BUILD_DIR_32" -name '*.dll' -exec cp {} "$DXVK_DEST_32/" \;
        _n=$(find "$DXVK_DEST_32" -name '*.dll' | wc -l)
        ok "DXVK 32-bit installed: ${_n} DLLs"
    else
        warn "No pre-built 32-bit DLLs found in: ${BUILD_DIR_32}"
        warn "Pass FORCE_REBUILD=true to rebuild DXVK from source."
    fi
    ok "DXVK ${DXVK_SOURCE_KEY} installed from pre-built DLLs (${_dxvk_prebuilt_count_64} x86_64 + ${_dxvk_prebuilt_count_32} i686)"
    exit 0
fi

# ── glslangValidator check ────────────────────────────────────────────────────
if command -v glslangValidator >/dev/null 2>&1; then
    ok "glslangValidator: $(glslangValidator --version 2>&1 | head -1)"
else
    err "glslangValidator not found — install: sudo apt install glslang-tools"
fi

# ══════════════════════════════════════════════════════════════════════════════
#  Clean up any previously staged header files
#
#  Earlier runs may have copied system headers into include/vulkan/ or
#  include/spirv/ — those are git submodule target paths.  Git refuses to
#  clone into non-empty directories, so we remove any untracked content first.
# ══════════════════════════════════════════════════════════════════════════════
sep "Cleaning stale staged headers"
for _dir in \
    "${DXVK_INCLUDE_DIR}/vulkan" \
    "${DXVK_INCLUDE_DIR}/spirv" \
    "${DXVK_INCLUDE_DIR}/vk_video" \
    "${DXVK_INCLUDE_DIR}/native"; do
    if [ -d "$_dir" ] && [ ! -f "${_dir}/.git" ] && [ ! -d "${_dir}/.git" ]; then
        _rel="${_dir#${DXVK_SOURCE_DIR}/}"
        # Only remove if it is a registered submodule path
        if git -C "$DXVK_SOURCE_DIR" config --file .gitmodules \
                --get-regexp "submodule\..*\.path" 2>/dev/null \
                | grep -qF "$_rel"; then
            msg2 "Removing stale content at submodule path: $_rel"
            rm -rf "$_dir"
        fi
    fi
done
ok "Cleanup done"

# ══════════════════════════════════════════════════════════════════════════════
#  Initialize DXVK git submodules
#
#  DXVK's submodules provide all the headers the cross-compiler needs:
#    include/vulkan/          — Vulkan-Headers
#    include/spirv/           — SPIRV-Headers
#    include/native/directx/  — mingw-directx-headers
# ══════════════════════════════════════════════════════════════════════════════
sep "Initializing DXVK git submodules"
git -C "$DXVK_SOURCE_DIR" submodule update --init --recursive
ok "Submodules initialized"

[ -f "${DXVK_INCLUDE_DIR}/vulkan/include/vulkan/vulkan.h" ] || \
[ -f "${DXVK_INCLUDE_DIR}/vulkan/vulkan.h" ] || \
    err "vulkan.h missing after submodule init — expected at include/vulkan/include/vulkan/vulkan.h"
[ -f "${DXVK_INCLUDE_DIR}/spirv/include/spirv/unified1/spirv.hpp" ] || \
[ -f "${DXVK_INCLUDE_DIR}/spirv/unified1/spirv.hpp" ] || \
    err "spirv.hpp missing after submodule init — expected at include/spirv/include/spirv/unified1/spirv.hpp"
ok "Vulkan headers present"
ok "SPIRV headers present"

# Determine the actual include roots by finding where vulkan.h lives
# The Vulkan-Headers submodule layout is: include/vulkan/include/vulkan/vulkan.h
# So the include root for -I is: include/vulkan/include
if [ -f "${DXVK_INCLUDE_DIR}/vulkan/include/vulkan/vulkan.h" ]; then
    VULKAN_INCLUDE_ROOT="${DXVK_INCLUDE_DIR}/vulkan/include"
    SPIRV_INCLUDE_ROOT="${DXVK_INCLUDE_DIR}/spirv/include"
    msg2 "Submodule layout: include/<name>/include/  (standard Khronos layout)"
else
    VULKAN_INCLUDE_ROOT="${DXVK_INCLUDE_DIR}"
    SPIRV_INCLUDE_ROOT="${DXVK_INCLUDE_DIR}"
    msg2 "Submodule layout: flat include/  (headers directly in submodule root)"
fi
msg2 "Vulkan include root: ${VULKAN_INCLUDE_ROOT}"
msg2 "SPIRV  include root: ${SPIRV_INCLUDE_ROOT}"

# ══════════════════════════════════════════════════════════════════════════════
#  Create MinGW compiler wrapper scripts
#
#  Meson 1.3.x does not reliably forward [built-in options] c_args/cpp_args
#  to its internal has_header() test compilations.  Thin wrappers that bake
#  -I<dxvk>/include into every compiler call solve this unconditionally.
# ══════════════════════════════════════════════════════════════════════════════
sep "Creating MinGW compiler wrappers"
mkdir -p "$WRAPPER_DIR"

_make_wrapper() {
    local real_bin="$1"
    local real_path
    real_path="$( command -v "${real_bin}" )" || \
        err "MinGW compiler not found: ${real_bin}
     Install: sudo apt install gcc-mingw-w64 g++-mingw-w64"
    # Derive the MinGW sysroot include path from the compiler triple
    # (x86_64-w64-mingw32-gcc → /usr/x86_64-w64-mingw32/include).
    # This must come FIRST so MinGW's stdint.h/corecrt.h win over
    # Linux system headers (/usr/include) that meson may inject via
    # pkg-config, preventing uintptr_t redefinition conflicts.
    local _triple="${real_bin%-*}"   # strip trailing -gcc or -g++
    local _mingw_inc="/usr/${_triple}/include"
    local wrapper="${WRAPPER_DIR}/${real_bin}"
    printf '#!/bin/sh\nexec "%s" -I"%s" -I"%s" -I"%s" "$@"\n' \
        "$real_path" "$_mingw_inc" "$VULKAN_INCLUDE_ROOT" "$SPIRV_INCLUDE_ROOT" > "$wrapper"
    chmod +x "$wrapper"
    ok "Wrapper: ${real_bin}  (sysroot: ${_mingw_inc})"
}

_make_wrapper "x86_64-w64-mingw32-gcc"
_make_wrapper "x86_64-w64-mingw32-g++"
_make_wrapper "i686-w64-mingw32-gcc"
_make_wrapper "i686-w64-mingw32-g++"

# ══════════════════════════════════════════════════════════════════════════════
#  _write_cross_file  —  Meson cross-compilation file pointing at wrappers
#  Usage: _write_cross_file <arch>   arch = x86_64 | i686
# ══════════════════════════════════════════════════════════════════════════════
_write_cross_file() {
    local arch="$1"
    local cross_file="${DXVK_SOURCE_DIR}/build-cross-${arch}.txt"
    local cpu cpu_family

    case "$arch" in
        x86_64) cpu="x86_64"; cpu_family="x86_64" ;;
        i686)   cpu="i686";   cpu_family="x86"    ;;
        *)      err "_write_cross_file: unknown arch '$arch'" ;;
    esac

    cat > "$cross_file" << EOF
[binaries]
c       = '${WRAPPER_DIR}/${arch}-w64-mingw32-gcc'
cpp     = '${WRAPPER_DIR}/${arch}-w64-mingw32-g++'
ar      = '${arch}-w64-mingw32-ar'
strip   = '${arch}-w64-mingw32-strip'
windres = '${arch}-w64-mingw32-windres'

[properties]
needs_exe_wrapper = true

[host_machine]
system     = 'windows'
cpu_family = '${cpu_family}'
cpu        = '${cpu}'
endian     = 'little'
EOF
    printf '%s' "$cross_file"
}

# ══════════════════════════════════════════════════════════════════════════════
#  _build_dxvk_arch  —  configure + build one arch
#  Usage: _build_dxvk_arch <arch> <build_dir> <dest_dir>
# ══════════════════════════════════════════════════════════════════════════════
_build_dxvk_arch() {
    local arch="$1" build_dir="$2" dest_dir="$3"

    sep "DXVK ${arch} configure"
    local cross_file
    cross_file="$(_write_cross_file "$arch")"
    ok "Cross file: $cross_file"

    if [ -d "$build_dir" ]; then
        msg2 "Wiping existing build directory: $build_dir"
        rm -rf "$build_dir"
    fi
    mkdir -p "$(dirname "$build_dir")"

    meson setup \
        --cross-file="$cross_file" \
        --buildtype=release \
        --strip \
        "$build_dir" \
        "$DXVK_SOURCE_DIR"

    sep "DXVK ${arch} compile  (jobs=${JOBS})"
    ninja -C "$build_dir" -j"${JOBS}"
    ok "DXVK ${arch} build complete"

    sep "DXVK ${arch} install → ${dest_dir}"
    mkdir -p "$dest_dir"
    local _count=0
    while IFS= read -r dll_path; do
        cp "$dll_path" "$dest_dir/"
        ok "  $(basename "$dll_path")"
        _count=$(( _count + 1 ))
    done < <(find "$build_dir" -name '*.dll' 2>/dev/null | sort)
    [ "$_count" -gt 0 ] || err "No .dll files found in DXVK ${arch} build tree: $build_dir"
    ok "DXVK ${arch} installed: ${_count} DLLs"
}

# ══════════════════════════════════════════════════════════════════════════════
#  Build both architectures
# ══════════════════════════════════════════════════════════════════════════════
_build_dxvk_arch "x86_64" "$BUILD_DIR_64" "$DXVK_DEST_64"
_build_dxvk_arch "i686"   "$BUILD_DIR_32" "$DXVK_DEST_32"

# ══════════════════════════════════════════════════════════════════════════════
#  Verify output
# ══════════════════════════════════════════════════════════════════════════════
sep "Verifying DXVK install"
_total=0
for dir in "$DXVK_DEST_64" "$DXVK_DEST_32"; do
    _count=$(find "$dir" -name '*.dll' 2>/dev/null | wc -l)
    ok "$(basename "$dir"): ${_count} .dll files"
    _total=$(( _total + _count ))
done
[ "$_total" -gt 0 ] || err "No DXVK .dll files were installed."
ok "DXVK ${DXVK_SOURCE_KEY} installed successfully (${_total} total DLL files)"
