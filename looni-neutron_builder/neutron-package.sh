#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║         looni-neutron_builder  •  Proton packager                          ║
# ║   Assembles a Steam-loadable compatibilitytool from compiled components   ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Called by neutron-builder.sh after all components are compiled.
# Can also be invoked standalone if the required environment vars are set.
#
# Required env vars:
#   NEUTRON_PACKAGE_DIR  — root of the Proton package being assembled
#   WINE_INSTALL_PREFIX  — where Wine was installed (= NEUTRON_PACKAGE_DIR/files)
#   BUILD_NAME           — human-readable name for this Proton build
#
# Optional env vars (neutron-builder.sh sets all of these):
#   DXVK_SOURCE_KEY      — dxvk | dxvk-async | none   (used for display only)
#   VKD3D_SOURCE_KEY     — vkd3d-proton | none          (used for display only)
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
: "${NEUTRON_PACKAGE_DIR:?NEUTRON_PACKAGE_DIR must be set}"
: "${WINE_INSTALL_PREFIX:?WINE_INSTALL_PREFIX must be set}"
: "${BUILD_NAME:?BUILD_NAME must be set}"
: "${DXVK_SOURCE_KEY:=none}"
: "${VKD3D_SOURCE_KEY:=none}"

# ── Sanity: Wine must actually be installed ───────────────────────────────────
[ -d "$WINE_INSTALL_PREFIX" ] || \
    err "Wine install prefix not found: $WINE_INSTALL_PREFIX
     Run neutron-build-core.sh (or neutron-builder.sh) first."
[ -f "${WINE_INSTALL_PREFIX}/bin/wine" ] || \
    err "Wine binary not found at: ${WINE_INSTALL_PREFIX}/bin/wine
     The Wine build may not have installed correctly."

sep "Proton Packager"
msg2 "Package dir  : ${NEUTRON_PACKAGE_DIR}"
msg2 "Wine prefix  : ${WINE_INSTALL_PREFIX}"
msg2 "Build name   : ${BUILD_NAME}"

# ══════════════════════════════════════════════════════════════════════════════
#  Get the wine version string for display and VDF fields
# ══════════════════════════════════════════════════════════════════════════════
_wine_ver="$("${WINE_INSTALL_PREFIX}/bin/wine" --version 2>/dev/null || printf 'unknown')"
_display_name="${BUILD_NAME}"
msg2 "Wine version : ${_wine_ver}"

# ══════════════════════════════════════════════════════════════════════════════
#  Write compatibilitytool.vdf
#
#  Steam reads this file to discover and display the custom Proton in the
#  game's compatibility settings dropdown.
# ══════════════════════════════════════════════════════════════════════════════
sep "Writing compatibilitytool.vdf"
cat > "${NEUTRON_PACKAGE_DIR}/compatibilitytool.vdf" << EOF
"compatibilitytools"
{
  "compat_tools"
  {
    "${BUILD_NAME}"
    {
      "install_path" "."
      "display_name" "${_display_name}"
      "from_oslist"  "windows"
      "to_oslist"    "linux"
    }
  }
}
EOF
ok "compatibilitytool.vdf written"

# ══════════════════════════════════════════════════════════════════════════════
#  Write toolmanifest.vdf
#
#  Tells Steam how to invoke this Proton build.
#  The %verb% token is replaced by Steam at runtime with the action to perform
#  (run, waitforexitandrun, runinprefix, etc.).
#
#  NOTE: "require_tool_appid" "1391110" would require the Steam Linux Runtime
#  Sniper (SteamOS 3.x container). We omit it so this Proton runs without
#  requiring the Steam Runtime container — broader host compatibility.
#  Add it back if you want full Steam Runtime isolation.
# ══════════════════════════════════════════════════════════════════════════════
sep "Writing toolmanifest.vdf"
cat > "${NEUTRON_PACKAGE_DIR}/toolmanifest.vdf" << 'EOF'
"manifest"
{
  "manifest_version"   "2"
  "commandline"        "/proton run"
  "use_sessions"       "1"
  "require_tool_appid" "1628350"
}
EOF
ok "toolmanifest.vdf written"

# ══════════════════════════════════════════════════════════════════════════════
#  Write the proton launcher script
#
#  Steam invokes this Python 3 script with a verb as the first argument.
#  Supported verbs:
#    run                — run the game executable directly
#    waitforexitandrun  — run and wait for exit (most games use this)
#    runinprefix        — run a command inside the Wine prefix
#    getcompatpath      — convert a Unix path to a Windows path
#    getnativepath      — convert a Windows path to a Unix path
#    stop               — kill the wineserver
#
#  Steam sets these environment variables before calling this script:
#    STEAM_COMPAT_DATA_PATH  — the game's compatibility data directory
#                              (the Wine prefix lives at $STEAM_COMPAT_DATA_PATH/pfx)
#    STEAM_COMPAT_CLIENT_INSTALL_PATH — path to the Steam client
#    STEAM_COMPAT_APP_ID     — the game's AppID (numeric string)
#
# ══════════════════════════════════════════════════════════════════════════════
sep "Writing proton launcher script"
cat > "${NEUTRON_PACKAGE_DIR}/proton" << 'PROTON_SCRIPT'
#!/usr/bin/env python3
# looni-neutron launcher
# Steam invokes this script with a verb and optional arguments.
#
# Verbs Steam uses:
#   waitforexitandrun  — most common: run the game and wait for it to exit
#   run                — run without waiting (Steam polls for exit itself)
#   runinprefix        — run a helper command inside the Wine prefix
#   getcompatpath      — convert a Unix path to a Windows path (print to stdout)
#   getnativepath      — convert a Windows path to a Unix path (print to stdout)
#   stop               — kill the wineserver for this prefix
#
# Steam sets these environment variables before calling us:
#   STEAM_COMPAT_DATA_PATH          — game's compat data dir; prefix = <path>/pfx
#   STEAM_COMPAT_CLIENT_INSTALL_PATH — Steam client installation directory
#   STEAM_COMPAT_INSTALL_PATH       — game's installation directory
#   SteamAppId                      — numeric App ID
#   SteamGameId                     — numeric Game ID (may differ from AppId)

import os
import sys
import subprocess

# ── Path resolution ────────────────────────────────────────────────────────────
SCRIPT_PATH = os.path.realpath(__file__)
PROTON_DIR  = os.path.dirname(SCRIPT_PATH)
FILES_DIR   = os.path.join(PROTON_DIR, "files")
BIN_DIR     = os.path.join(FILES_DIR, "bin")
LIB_DIR     = os.path.join(FILES_DIR, "lib")
LIB64_DIR   = os.path.join(FILES_DIR, "lib64")

# Wine binaries
WINE_PATH    = os.path.join(BIN_DIR, "wine")
WINE64_PATH  = os.path.join(BIN_DIR, "wine64")
SERVER_PATH  = os.path.join(BIN_DIR, "wineserver")
BOOT_PATH    = os.path.join(BIN_DIR, "wineboot")

# DXVK DLL directories (D3D9 / D3D10 / D3D11 / DXGI → Vulkan)
DXVK_DIR_64 = os.path.join(LIB64_DIR, "wine", "dxvk")
DXVK_DIR_32 = os.path.join(LIB_DIR,   "wine", "dxvk")

# VKD3D-Proton DLL directories (D3D12 → Vulkan)
VKD3D_DIR_64 = os.path.join(LIB64_DIR, "wine", "vkd3d-proton")
VKD3D_DIR_32 = os.path.join(LIB_DIR,   "wine", "vkd3d-proton")

def die(msg):
    print(f"proton: ERROR: {msg}", file=sys.stderr)
    sys.exit(1)

# ── Sanity check ───────────────────────────────────────────────────────────────
if not os.path.isfile(WINE_PATH):
    die(f"Wine binary not found: {WINE_PATH}\n"
        f"Make sure the Proton build completed successfully.")

if len(sys.argv) < 2:
    die("Usage: proton <verb> [args...]")

VERB       = sys.argv[1]
EXTRA_ARGS = sys.argv[2:]

# ── Steam environment ──────────────────────────────────────────────────────────
COMPAT_DATA    = os.environ.get("STEAM_COMPAT_DATA_PATH", "")
WINE_PREFIX    = os.path.join(COMPAT_DATA, "pfx") if COMPAT_DATA else ""
STEAM_ROOT     = os.environ.get("STEAM_COMPAT_CLIENT_INSTALL_PATH", "")
GAME_INSTALL   = os.environ.get("STEAM_COMPAT_INSTALL_PATH", "")
APP_ID         = os.environ.get("SteamAppId", "")
GAME_ID        = os.environ.get("SteamGameId", APP_ID)

# ── Build the Wine environment ─────────────────────────────────────────────────
env = os.environ.copy()

# ── Wine binary pointers ───────────────────────────────────────────────────────
env["WINE"]       = WINE_PATH
env["WINE64"]     = WINE64_PATH
env["WINESERVER"] = SERVER_PATH
env["WINEBOOT"]   = BOOT_PATH

# ── Wine prefix ───────────────────────────────────────────────────────────────
if WINE_PREFIX:
    env["WINEPREFIX"] = WINE_PREFIX
    os.makedirs(WINE_PREFIX, exist_ok=True)

# ── PATH: our bin dir first ────────────────────────────────────────────────────
env["PATH"] = BIN_DIR + ":" + env.get("PATH", "/usr/bin:/bin")

# ── LD_LIBRARY_PATH ───────────────────────────────────────────────────────────
# Include our Wine libs, DXVK dirs, VKD3D dirs, and the Steam overlay libs.
# The Steam overlay injects gameoverlayrenderer.so — it needs to find it.
overlay_paths = []
if STEAM_ROOT:
    overlay_paths += [
        os.path.join(STEAM_ROOT, "ubuntu12_64"),
        os.path.join(STEAM_ROOT, "ubuntu12_32"),
    ]

ld_parts = [LIB64_DIR, LIB_DIR,
            DXVK_DIR_64, DXVK_DIR_32,
            VKD3D_DIR_64, VKD3D_DIR_32] + overlay_paths
existing_ld = env.get("LD_LIBRARY_PATH", "")
env["LD_LIBRARY_PATH"] = ":".join(p for p in ld_parts + [existing_ld] if p)

# ── WINEDLLPATH: where Wine looks for Windows DLLs ───────────────────────────
# This is what makes DXVK and VKD3D-Proton actually get loaded.
# Wine searches these directories for .dll files before its own builtins.
dll_paths = []
for d in [DXVK_DIR_64, VKD3D_DIR_64, DXVK_DIR_32, VKD3D_DIR_32]:
    if os.path.isdir(d):
        dll_paths.append(d)
if dll_paths:
    existing_dllpath = env.get("WINEDLLPATH", "")
    env["WINEDLLPATH"] = ":".join(dll_paths + ([existing_dllpath] if existing_dllpath else []))

# ── WINEDLLOVERRIDES: force DXVK and VKD3D DLLs to native ────────────────────
# Without these overrides Wine uses its own built-in WineD3D even if DXVK
# DLLs are present in WINEDLLPATH.  "n,b" = try native first, then builtin.
dxvk_overrides = "d3d9=n,b;d3d10=n,b;d3d10_1=n,b;d3d10core=n,b;d3d11=n,b;dxgi=n,b"
vkd3d_overrides = "d3d12=n,b;d3d12core=n,b"

# Only add overrides for components that are actually installed
active_overrides = []
if os.path.isdir(DXVK_DIR_64) and any(
        f.endswith(".dll") for f in os.listdir(DXVK_DIR_64)):
    active_overrides.append(dxvk_overrides)
if os.path.isdir(VKD3D_DIR_64) and any(
        f.endswith(".dll") for f in os.listdir(VKD3D_DIR_64)):
    active_overrides.append(vkd3d_overrides)

if active_overrides:
    existing_overrides = env.get("WINEDLLOVERRIDES", "")
    combined = ";".join(active_overrides)
    env["WINEDLLOVERRIDES"] = (combined + ";" + existing_overrides
                               if existing_overrides else combined)

# ── Synchronization primitives ────────────────────────────────────────────────
# Detect what sync modes are compiled into the wineserver binary and enable
# the best available one automatically — no manual env var needed.
#
# Priority: ntsync (kernel module, fastest) > fsync > esync > server-side
#
# ntsync activates by itself when /dev/ntsync exists AND the binary has
# ntsync support compiled in — no env var needed for it.
# fsync/esync require WINEFSYNC=1 / WINEESYNC=1 to activate.
#
# If the user has already set these externally we respect their choice.

def _binary_has(binary_path, search_string):
    """Check if a binary contains a given string (like `strings | grep`)."""
    try:
        with open(binary_path, "rb") as f:
            return search_string.encode() in f.read()
    except OSError:
        return False

_has_ntsync = _binary_has(SERVER_PATH, "ntsync")
_has_fsync  = _binary_has(SERVER_PATH, "fsync")
_has_esync  = _binary_has(SERVER_PATH, "esync")

if _has_ntsync:
    # ntsync is compiled in — it activates automatically via /dev/ntsync,
    # no env var needed. Still set fsync as fallback for when the module
    # isn't loaded.
    if _has_fsync:
        env.setdefault("WINEFSYNC", "1")
    if _has_esync:
        env.setdefault("WINEESYNC", "1")
elif _has_fsync:
    # No ntsync (e.g. Valve proton-wine) — enable fsync explicitly.
    env.setdefault("WINEFSYNC", "1")
    if _has_esync:
        env.setdefault("WINEESYNC", "1")
elif _has_esync:
    # Older Wine without fsync — esync only.
    env.setdefault("WINEESYNC", "1")
# else: server-side sync only — nothing to set
env.setdefault("WINE_LARGE_ADDRESS_AWARE", "1")
env.setdefault("WINEDEBUG",               "-all")  # suppress noise; override externally if needed
env.setdefault("DXVK_LOG_LEVEL",          "none")  # suppress DXVK HUD spam by default

# ── Synchronization primitives ────────────────────────────────────────────────
# fsync uses Linux futex operations for Wine's synchronization objects.
# It is much faster than the default server-side sync and is already compiled
# into Valve's proton-wine — it just needs to be enabled here.
# esync is the older eventfd-based approach; fsync supersedes it but we enable
# both so Wine picks the best one available on the running kernel.
# ntsync (kernel module / Linux 6.14+) is auto-detected by Wine when available;
# setting WINEFSYNC=1 does not conflict with it.
env.setdefault("WINEFSYNC", "1")
env.setdefault("WINEESYNC", "1")

# Steam App ID forwarding
if APP_ID:
    env.setdefault("SteamAppId",  APP_ID)
    env.setdefault("SteamGameId", GAME_ID)

# ── Prefix initialization ──────────────────────────────────────────────────────
def init_prefix():
    """Initialize the Wine prefix if it hasn't been set up yet."""
    if not WINE_PREFIX:
        return
    system_reg = os.path.join(WINE_PREFIX, "system.reg")
    if not os.path.isfile(system_reg):
        print("proton: initializing Wine prefix...", file=sys.stderr)
        subprocess.run(
            [BOOT_PATH, "--init"],
            env=env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
        )

# ── Verb handlers ──────────────────────────────────────────────────────────────
def verb_run(args, wait=True):
    """Run a Windows executable through Wine."""
    init_prefix()
    # Steam passes the full Windows path to the executable as args.
    # Use wine64 if available (it handles both 32 and 64-bit exes on a
    # WoW64-configured prefix), otherwise fall back to wine.
    runner = WINE64_PATH if os.path.isfile(WINE64_PATH) else WINE_PATH
    cmd = [runner] + args
    proc = subprocess.Popen(cmd, env=env)
    if wait:
        try:
            proc.wait()
        except KeyboardInterrupt:
            proc.terminate()
        sys.exit(proc.returncode)
    sys.exit(0)

def verb_runinprefix(args):
    """Run a helper command inside the Wine prefix."""
    init_prefix()
    runner = WINE64_PATH if os.path.isfile(WINE64_PATH) else WINE_PATH
    proc = subprocess.run([runner] + args, env=env)
    sys.exit(proc.returncode)

def verb_getcompatpath(args):
    """Convert a Unix path to a Windows path (printed to stdout for Steam)."""
    unix_path = args[0] if args else ""
    runner = WINE64_PATH if os.path.isfile(WINE64_PATH) else WINE_PATH
    result = subprocess.run(
        [runner, "winepath", "-w", unix_path],
        env=env, capture_output=True, text=True,
    )
    print(result.stdout.strip())
    sys.exit(result.returncode)

def verb_getnativepath(args):
    """Convert a Windows path to a Unix path (printed to stdout for Steam)."""
    win_path = args[0] if args else ""
    runner = WINE64_PATH if os.path.isfile(WINE64_PATH) else WINE_PATH
    result = subprocess.run(
        [runner, "winepath", "-u", win_path],
        env=env, capture_output=True, text=True,
    )
    print(result.stdout.strip())
    sys.exit(result.returncode)

def verb_stop():
    """Kill the wineserver for the current prefix."""
    subprocess.run([SERVER_PATH, "-k"], env=env)
    sys.exit(0)

# ── Dispatch ───────────────────────────────────────────────────────────────────
if VERB in ("run", "waitforexitandrun"):
    verb_run(EXTRA_ARGS, wait=True)
elif VERB == "runinprefix":
    verb_runinprefix(EXTRA_ARGS)
elif VERB == "getcompatpath":
    verb_getcompatpath(EXTRA_ARGS)
elif VERB == "getnativepath":
    verb_getnativepath(EXTRA_ARGS)
elif VERB == "stop":
    verb_stop()
else:
    # Forward-compatibility: unknown verbs attempted as wine commands
    print(f"proton: unknown verb '{VERB}', forwarding to wine", file=sys.stderr)
    verb_run([VERB] + EXTRA_ARGS)
PROTON_SCRIPT

chmod +x "${NEUTRON_PACKAGE_DIR}/proton"
ok "proton launcher written"

# ══════════════════════════════════════════════════════════════════════════════
#  Write a minimal README inside the package
# ══════════════════════════════════════════════════════════════════════════════
sep "Writing package README"
cat > "${NEUTRON_PACKAGE_DIR}/README.md" << EOF
# ${BUILD_NAME}

Built by **looni-neutron_builder**.

| Component       | Status                                       |
|-----------------|----------------------------------------------|
| proton-wine     | ${_wine_ver}                                 |
| DXVK            | ${DXVK_SOURCE_KEY}                           |
| VKD3D-Proton    | ${VKD3D_SOURCE_KEY}                          |

## Installation

Copy this directory into Steam's compatibility tools folder and restart Steam:

\`\`\`bash
cp -r "$(basename "$NEUTRON_PACKAGE_DIR")" ~/.local/share/Steam/compatibilitytools.d/
\`\`\`

Then open a game's Properties → Compatibility and select **${_display_name}**.

## Built with

- [looni-neutron_builder](https://github.com/blu2442/looni-neutron_builder)
- [ValveSoftware/wine](https://github.com/ValveSoftware/wine)
EOF
ok "README written"

# ══════════════════════════════════════════════════════════════════════════════
#  Verify the package structure
# ══════════════════════════════════════════════════════════════════════════════
sep "Verifying package"

_verify() {
    local path="$1" label="$2"
    if [ -e "$path" ]; then
        ok "$label"
    else
        warn "Expected file missing: $path"
    fi
}

_verify "${NEUTRON_PACKAGE_DIR}/compatibilitytool.vdf" "compatibilitytool.vdf"
_verify "${NEUTRON_PACKAGE_DIR}/toolmanifest.vdf"       "toolmanifest.vdf"
_verify "${NEUTRON_PACKAGE_DIR}/proton"                 "proton launcher"
_verify "${WINE_INSTALL_PREFIX}/bin/wine"              "files/bin/wine"
_verify "${WINE_INSTALL_PREFIX}/bin/wineserver"        "files/bin/wineserver"
_verify "${WINE_INSTALL_PREFIX}/bin/wine64"            "files/bin/wine64"

# ── Package size ──────────────────────────────────────────────────────────────
_pkg_size="$(du -sh "$NEUTRON_PACKAGE_DIR" 2>/dev/null | cut -f1)"
ok "Package size: ${_pkg_size}"

sep "Packaging complete"
ok "Proton package ready at: ${NEUTRON_PACKAGE_DIR}"
msg2 "To install:  cp -r ${NEUTRON_PACKAGE_DIR} ~/.local/share/Steam/compatibilitytools.d/"
msg2 "Then restart Steam and enable in game Properties → Compatibility."
