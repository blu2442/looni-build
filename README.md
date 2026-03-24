# looni-build

**Wine & Proton builders, hybrid installer, and GUI toolkit for Linux — all in one repo.**

Build Wine from 10 upstream sources, compile full Proton packages for Steam, merge
custom Wine over existing Proton installs, manage installations with one-click
switching, and handle prefixes, DXVK, runtimes, and DLL overrides through a
zenity-based GUI. Or do it all from the CLI.

```
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
                looni-build v1.2.0
```

---

## Table of Contents

- [Quick Start](#quick-start)
- [Install](#install)
- [Tools](#tools)
  - [wine-builder](#-wine-builder--looni-wine_builder)
  - [neutron-builder](#-neutron-builder--looni-neutron_builder)
  - [wine-proton_hybrid](#-wine-proton_hybrid--looni-wine-proton_hybrid_builder)
  - [wine_toolz](#-wine_toolz--looni-winetoolz)
  - [Wine Install Manager](#-wine-install-manager)
- [Project Layout](#project-layout)
- [Data Directories](#data-directories)
- [Building with Containers (Recommended)](#building-with-containers-recommended)
- [Requirements](#requirements)
- [Uninstall](#uninstall)

---

## Quick Start

```bash
git clone https://github.com/blu2442/looni-build
cd looni-build
make install            # installs to ~/.local (adds PATH to ~/.bashrc)
source ~/.bashrc

looni-build             # main menu — pick any tool
wine-builder            # build Wine interactively
neutron-builder          # build Proton interactively
wine_toolz              # open the GUI toolkit
wine-proton_hybrid      # hybrid installer
```

---

## Install

```bash
make install                        # user install → ~/.local  (default)
make install PREFIX=/usr/local      # system-wide  (needs sudo)
make install DESTDIR=/tmp/pkg       # staged for packaging
```

Selective install:

```bash
make install-neutron     # neutron_builder only
make install-wine       # wine_builder only
make install-hybrid     # hybrid_builder only
make install-toolz      # winetoolz only
make install-launcher   # looni-build main menu only
```

The installer adds a `PATH` block to `~/.bashrc` automatically. If `~/.local/bin`
is already in your `PATH`, it's skipped. Run `source ~/.bashrc` after first install.

---

## Tools

### 🍷 wine-builder — looni-wine_builder

Builds Wine from 10 upstream sources with full 32+64-bit cross-compile, ccache
support, TKG patch integration, and automated staging application.

```bash
wine-builder                            # interactive source + version picker
wine-builder --source mainline          # upstream Wine (stable tags)
wine-builder --source staging           # Wine-Staging (pre-patched)
wine-builder --source tkg-patched       # mainline + staging patches (automated)
wine-builder --source proton            # Valve proton-wine (branch picker)
wine-builder --source kron4ek           # Kron4ek wine-tkg build
wine-builder --source custom --url <git-url> --branch main
wine-builder --source local --local-dir ~/my-wine-src
wine-builder --resume                   # continue an interrupted build
wine-builder --list                     # show completed builds
wine-builder --uninstall                # remove a build (interactive picker)
```

#### Wine Sources

| Key | Source | Notes |
|-----|--------|-------|
| `mainline` | Wine mainline | Official WineHQ stable releases |
| `experimental` | Wine experimental | WineHQ bleeding-edge (master) |
| `staging` | Wine-Staging | Mainline + community patches, pre-applied |
| `tkg-patched` | Wine + Staging (automated) | Mainline with staging applied automatically |
| `proton` | Valve proton-wine | Valve's Wine fork (interactive branch picker) |
| `proton-experimental` | Valve Bleeding Edge | Valve's latest experiments |
| `wine-tkg` | wine-tkg (Frogging-Family) | Community patchset framework |
| `kron4ek` | Kron4ek wine-tkg | Kron4ek's Wine + Staging + TKG + ntsync |
| `local` | Local source | Use an existing directory (requires `--local-dir`) |
| `custom` | Custom URL | Any git repo (requires `--url`) |

#### Full CLI Reference

| Flag | Description |
|------|-------------|
| `--source NAME` | Wine source key (see table above) |
| `--branch BRANCH` | Pin to a specific branch or tag |
| `--url URL` | Git URL (required with `--source custom`) |
| `--local-dir PATH` | Existing source tree (required with `--source local`) |
| `--no-pull` | Skip `git pull` on existing source |
| `--dest DIR` | Root for `build-run/` and `install/` output |
| `--src-dir DIR` | Root for git-cloned sources |
| `--name NAME` | Custom build name (default: auto-generated) |
| `--jobs N` | Parallel make jobs (default: `nproc`) |
| `--cfg PATH` | Alternate `customization.cfg` |
| `--skip-32` | Skip 32-bit build |
| `--no-ccache` | Disable ccache |
| `--keep-symbols` | Keep debug symbols (skip strip) |
| `--build-type TYPE` | `release` (default) \| `debug` \| `debugoptimized` |
| `--native` | Compile with `-march=native` (faster, non-portable) |
| `--lto` | Enable link-time optimisation |
| `--resume` | Continue an interrupted build (skip configure) |
| `--verbose` | Stream raw make output |
| `--list` | Show installed builds |
| `--uninstall [NAME]` | Remove a build (interactive if no name given) |
| `--update` | Re-fetch and rebuild last-used source |
| `--dry-run` | Print planned actions without executing |

Build output lands in `buildz/install/<name>/` — a complete Wine prefix-ready
tree with `bin/wine`, `lib/`, etc.

---

### 🎮 neutron-builder — looni-neutron_builder

Builds a complete custom Proton package for Steam from source: proton-wine + DXVK +
VKD3D-Proton, assembled into a `compatibilitytool.vdf` package ready to drop into
Steam.

```bash
neutron-builder                                  # interactive wizard
neutron-builder --source proton-wine             # Valve proton-wine (branch picker)
neutron-builder --source proton-wine --branch proton_9.0
neutron-builder --source kron4ek-tkg             # Kron4ek wine-tkg + ntsync
neutron-builder --dxvk-only                      # rebuild DXVK only, skip Wine
neutron-builder --vkd3d-only                     # rebuild VKD3D-Proton only
neutron-builder --reinstall-components           # re-package without rebuilding
neutron-builder --list                           # show installed Proton builds
```

#### Proton Wine Sources

| Key | Source | Notes |
|-----|--------|-------|
| `proton-wine` | Valve proton-wine | Stable branches with interactive version picker |
| `proton-wine-experimental` | Valve proton-wine experimental | Bleeding-edge, no picker |
| `kron4ek-tkg` | Kron4ek wine-tkg | Mainline + Staging + TKG patches + ntsync |

#### DXVK & VKD3D-Proton Options

| DXVK Key | Description |
|----------|-------------|
| `dxvk` | Standard DXVK — D3D9/10/11 → Vulkan (default) |
| `dxvk-async` | DXVK + async pipeline compilation |
| `none` | Skip DXVK (falls back to WineD3D) |

| VKD3D Key | Description |
|-----------|-------------|
| `vkd3d-proton` | VKD3D-Proton — D3D12 → Vulkan (default) |
| `none` | Skip VKD3D-Proton (D3D12 games won't work) |

#### Full CLI Reference

| Flag | Description |
|------|-------------|
| `--source NAME` | Wine source key |
| `--branch BRANCH` | Pin proton-wine to a specific branch |
| `--no-pull` | Skip `git pull` |
| `--dxvk NAME` | DXVK variant (`dxvk` \| `dxvk-async` \| `none`) |
| `--vkd3d NAME` | VKD3D variant (`vkd3d-proton` \| `none`) |
| `--dxvk-branch BRANCH` | Pin DXVK to specific tag |
| `--vkd3d-branch BRANCH` | Pin VKD3D-Proton to specific tag |
| `--name NAME` | Build name (default: `looni-neutron-<ver>`) |
| `--dest DIR` | Root for build artefacts |
| `--src-dir DIR` | Root for git clones |
| `--jobs N` | Parallel make threads (default: `nproc`) |
| `--skip-32` | Skip 32-bit Wine build |
| `--no-ccache` | Disable ccache |
| `--keep-symbols` | Keep debug symbols |
| `--build-type TYPE` | `release` \| `debug` \| `debugoptimized` |
| `--native` | `-march=native` optimisation |
| `--lto` | Link-time optimisation |
| `--resume` | Continue interrupted build |
| `--dxvk-only` | Rebuild DXVK only (skip Wine) |
| `--vkd3d-only` | Rebuild VKD3D-Proton only (skip Wine) |
| `--reinstall-components` | Re-package without rebuilding |
| `--cfg PATH` | Alternate `neutron-customization.cfg` |
| `--list` | Show installed Proton builds |
| `--dry-run` | Print planned actions |

#### Installing to Steam

After a successful build:

```bash
cp -r ~/.local/share/looni-neutron_builder/buildz/install/<name> \
      ~/.steam/debian-installation/compatibilitytools.d/
```

Restart Steam, then go to a game's Properties → Compatibility → select your build.

---

### 🔀 wine-proton_hybrid — looni-wine-proton_hybrid_builder

Merges any Wine build directly over an existing Proton install, preserving Proton's
DXVK, VKD3D-Proton, Steam overlay DLLs, and Python launcher. Run your custom Wine
inside Proton's infrastructure — get the best of both worlds.

```bash
wine-proton_hybrid                          # interactive wizard
wine-proton_hybrid \
    --wine-src ~/builds/wine-staging-10.5 \
    --proton-src ~/.steam/steam/compatibilitytools.d/GE-Proton10-32 \
    --name my-hybrid \
    --install-mode steam
wine-proton_hybrid --uninstall --name my-hybrid
```

#### CLI Reference

| Flag | Description |
|------|-------------|
| `--wine-src DIR` | Path to the custom Wine build directory |
| `--proton-src DIR` | Path to the Proton/GE-Proton source |
| `--name NAME` | Tool name (default: `wine-proton_looni`) |
| `--protonfixes-dir DIR` | Path to protonfixes source (umu-protonfixes, etc.) |
| `--install-mode MODE` | `steam` \| `steam-pick` \| `custom` |
| `--install-dir DIR` | Parent directory for custom installs |
| `--dry-run` | Show commands without executing |
| `--verbose` | Print every command before running |
| `--debug` | Dump Proton lib/wine layout after install |
| `--uninstall` | Remove a previously installed hybrid |

#### Standalone Launcher Environment Variables

The hybrid installs a standalone launcher script. Control it with:

| Variable | Description |
|----------|-------------|
| `LOONI_PREFIX` | Exact prefix path (default: `~/.wine-proton-pfx`) |
| `WINE_USE_START` | Set to `1` for launcher-wrapped games (e.g., GTA IV) |
| `PROTON_LOG` | Set to `1` for verbose Wine debug log in `/tmp/` |
| `DXVK_HUD` | Set to `1` for DXVK overlay |
| `WINEARCH` | `win64` (default) or `win32` |

---

### 🛠️ wine_toolz — looni-winetoolz

A zenity-based GUI for managing Wine prefixes, installing graphics layers, runtimes,
and components. 20+ modules across 7 categories.

```bash
wine_toolz
```

#### Categories & Modules

| Category | Module | Description |
|----------|--------|-------------|
| **Graphics** | DXVK Installer | Install/uninstall DXVK (D3D8/9/10/11 → Vulkan) into a prefix |
| | VKD3D-Proton Installer | Install/uninstall VKD3D-Proton (D3D12 → Vulkan) |
| | DXVK-NVAPI Installer | NVIDIA API layer for DLSS / NvAPI support |
| **Runtimes** | Runtime Libraries | .NET, XNA, XACT, VC++, DirectPlay, OpenAL, and more |
| | DirectX Jun 2010 | Legacy DirectX offline redistributable |
| **Wine** | Wine Tools | Uninstaller, control panel, taskmgr, regedit, explorer, wineboot |
| | DLL Override Manager | View, apply presets, add custom, remove DLL overrides |
| | **Wine Install Manager** | **Install, switch, uninstall, and manage custom Wine builds** |
| **Prefix** | Create Prefix | Bootstrap a new Wine/Proton prefix from scratch |
| | Winecfg | Open Wine configuration for an existing prefix |
| | Prefix Manager | Backup, restore, regedit, kill processes |
| | Prefix Diagnostics | Health check — arch, Windows ver, DXVK, disk usage, integrity |
| **Launch** | App Launcher | Save and launch Wine app shortcuts with env profiles |
| | Env Flags | Manage DXVK/VKD3D/Wine/Mesa environment variable profiles |
| | Log Viewer | Run an app and capture Wine stderr to a log file |
| **Components** | DLL Installer | Curated DLLs — d3dx9/10/11, d3dcomp, xinput, msxml, physx, more |
| | System File Installer | Extract + install DLLs from any archive into a prefix |
| **System** | About / Help | Dependency checker, module reference, config paths |

#### Smart Wine Binary Detection

Every module that needs a Wine binary uses `wt_select_wine_bin`, which auto-scans:

1. Custom Wine builds under `~/wine-custom/buildz/`
2. Proton/GE-Proton in `~/.steam/debian-installation/compatibilitytools.d/`
3. System `wine` / `wine64` on `$PATH`
4. Manual browse fallback

Proton wrappers are automatically resolved to their inner wine binary.

#### Environment Profiles (Env Flags)

Create reusable environment variable profiles for launching games:

- **DXVK:** `DXVK_HUD`, `DXVK_ASYNC`, `DXVK_FRAME_RATE`
- **VKD3D:** `VKD3D_DEBUG`, `VKD3D_SHADER_DEBUG`
- **Wine:** `WINEDEBUG`, `WINEESYNC`, `WINEFSYNC`, `STAGING_SHARED_MEMORY`
- **Mesa/AMD:** `mesa_glthread`, `RADV_PERFTEST`
- **Vulkan ICD:** Force AMD or NVIDIA ICD

Profiles are saved to `~/.config/winetoolz/env_profiles/<name>.env` and can be
attached to app launcher shortcuts.

#### Prefix Diagnostics

Run a full health check on any prefix:

- Architecture detection (win32 vs win64)
- Windows version from registry
- Disk usage breakdown
- DLL override count
- Translation layer detection (DXVK, VKD3D presence)
- Key file integrity (system.reg, wineboot.exe, explorer.exe, etc.)
- Overall health verdict with actionable issue listing

---

### 📦 Wine Install Manager

**NEW in v1.2.0** — a dedicated manager for installing, switching between, and
uninstalling custom Wine builds. Accessible from both the main `looni-build` menu
and winetoolz's Wine category.

**Install location:** `~/.local/share/looni-wine-installs/<name>/`
**Symlink directory:** `~/.local/bin/`

#### Features

| Action | Description |
|--------|-------------|
| **Install** | Install a Wine build from wine-builder output, a local directory, or a tarball (.tar.gz/.xz/.zst/.bz2) |
| **List** | Show all managed installations with version, install date, and active status |
| **Switch** | Set which Wine build is the system default (swaps symlinks in `~/.local/bin/`) |
| **Uninstall** | Remove one or more builds — cleans up symlinks and install directory |
| **Info** | Disk usage, version, source, architecture, contents breakdown |

#### How It Works

1. **Install** copies (via rsync) or extracts the Wine build into its own directory
   under `~/.local/share/looni-wine-installs/`.
2. A `.looni-meta` metadata file is written with version, source, and install date.
3. **Switch** creates symlinks (`wine`, `wine64`, `wineserver`, `wineboot`, `winecfg`,
   etc.) in `~/.local/bin/` pointing to the active install.
4. Only symlinks managed by looni-build are touched — existing system Wine is never modified.
5. **Uninstall** removes the install directory and cleans up any symlinks pointing to it.

#### Source Detection

When installing from wine-builder output, the manager scans:

- `~/.local/share/looni-wine_builder/buildz/install/`
- `~/wine-custom/buildz/`

Any directory containing `bin/wine` or `bin/wine64` is a valid source.

---

## Project Layout

```
looni-build/
├── looni-build.sh                              Main launcher menu (fzf or numbered)
├── Makefile                                    Install / uninstall
├── README.md
│
├── looni-wine_builder/
│   ├── wine-builder.sh                         Entry point (CLI + interactive)
│   ├── wine-build-core.sh                      Build engine
│   ├── build-32.sh                             32-bit compile wrapper
│   ├── build-64.sh                             64-bit compile wrapper
│   ├── helper.sh                               Utility functions
│   ├── install-from-build.sh                   Post-build installation
│   ├── wine-tkg-patcher.sh                     TKG patch applicator
│   ├── customization.cfg                       Build config (compiler flags, configure args)
│   ├── patches/                                Drop .patch/.diff files here
│   └── deps-tkg                                TKG dependency list
│
├── looni-neutron_builder/
│   ├── neutron-builder.sh                        Entry point
│   ├── neutron-build-core.sh                     Build engine
│   ├── neutron-dxvk-build.sh                     DXVK builder (meson/ninja)
│   ├── neutron-vkd3d-build.sh                    VKD3D-Proton builder
│   ├── neutron-package.sh                        Steam package assembler
│   ├── spinner.sh                               Progress animation
│   ├── ntsync.h                                 Kernel header for ntsync support
│   ├── neutron-customization.cfg                 Build config
│   ├── patches/                                 Drop .patch/.diff files here
│   └── deps-neutron-tkg                          TKG dependency list
│
├── looni-wine-proton_hybrid_builder/
│   ├── wine-proton_hybrid-v1.0.0.sh            Hybrid installer
│   └── buildz/                                  Build output (local mode)
│
└── looni-winetoolz/
    ├── wine_toolz.sh                            Main launcher (zenity GUI)
    └── modules/
        ├── winetoolz-lib.sh                     Shared library (dialogs, Wine resolution)
        └── shared_lib/
            ├── about.sh                          Help / dependency checker
            ├── app_launcher.sh                   App shortcut manager
            ├── directx_installer-local.sh        DirectX Jun 2010 installer
            ├── dll_installer.sh                  Component DLL installer
            ├── dll_override_manager.sh           DLL override management
            ├── dxvk_setup-gui.sh                 DXVK install/uninstall
            ├── env_flags.sh                      Environment variable profiles
            ├── install_components-x86_64.sh      System component installer
            ├── install_nvapi.sh                  DXVK-NVAPI installer
            ├── log_viewer.sh                     Wine stderr log capture
            ├── prefix_diagnostics.sh             Prefix health checker
            ├── prefix_manager.sh                 Prefix backup/restore
            ├── runtime_manager.sh                Runtime version manager
            ├── runtimes_installer.sh             .NET/VC++/XNA installer
            ├── setup_vkd3d_proton-gui.sh         VKD3D-Proton installer
            ├── vcruntime_installer-gui.sh        Visual C++ runtime installer
            ├── wine_install_manager.sh           Wine Install Manager (NEW)
            ├── wine_tools.sh                     Wine control/regedit/explorer
            └── winetoolz-prefix-maker.sh         Prefix creation wizard
```

---

## Data Directories

Everything lives under your home directory. Nothing touches system paths unless you
explicitly `make install PREFIX=/usr/local`.

### Install Layout (after `make install`)

```
~/.local/
├── bin/
│   ├── looni-build             Main menu
│   ├── neutron-builder          Proton builder
│   ├── wine-builder            Wine builder
│   ├── wine_toolz              winetoolz GUI
│   └── wine-proton_hybrid      Hybrid installer
└── lib/
    ├── looni-neutron_builder/   Engine scripts + patches/
    ├── looni-wine_builder/     Engine scripts + patches/
    ├── looni-wine-proton_hybrid_builder/
    └── looni-winetoolz/        Modules + shared_lib/
```

### Runtime Data (created by scripts on first use)

```
~/.local/share/
├── looni-wine_builder/
│   ├── buildz/
│   │   ├── install/            Completed Wine builds
│   │   └── build-run/          In-progress build trees
│   └── src/                    Git-cloned Wine sources
│
├── looni-neutron_builder/
│   ├── buildz/
│   │   ├── install/            Completed Proton packages
│   │   └── build-run/          In-progress builds
│   └── src/                    Git clones (proton-wine, dxvk, vkd3d-proton)
│
└── looni-wine-installs/        Managed Wine installations (Wine Install Manager)
    ├── wine-staging-10.5/
    │   ├── bin/wine
    │   ├── lib/ lib64/ share/
    │   └── .looni-meta         Version, source, install date
    └── wine-tkg-custom/
        └── ...
```

### Configuration

```
~/.config/looni-build/
├── customization.cfg           wine-builder compile flags (never overwritten on reinstall)
├── neutron-customization.cfg    neutron-builder compile flags
└── winetoolz.cfg               winetoolz preferences

~/.config/winetoolz/
├── launchers/                  App launcher shortcut configs
├── env_profiles/               Environment variable profiles (.env)
└── icons/                      Cached .exe icons (PNG)
```

### Other Runtime Directories

```
~/wine-custom/buildz/           Runtime manager downloads (GE-Proton, Kron4ek, etc.)
~/winetoolz/
├── backups/                    Prefix backup archives
├── logs/                       Wine stderr capture logs
└── dxvk-vkd3d_proton-files/   Downloaded DXVK/VKD3D-Proton releases
```

---

## Building with Containers (Recommended)

**Containers are the recommended way to build Wine and Proton.** They provide a
clean, reproducible Ubuntu 24.04 environment with every dependency pre-installed —
no risk of polluting your host system with hundreds of dev packages.

Both builders ship their own Containerfiles:

| Builder | Containerfile | Image name |
|---------|--------------|------------|
| wine-builder | `looni-wine_builder/Containerfile` | `wine-builder` |
| neutron-builder | `looni-neutron_builder/Containerfile.neutron` | `looni-neutron_builder` |

Podman (rootless) is strongly recommended. Docker works too — just drop the `:z`
volume flags if SELinux is not in use.

### Wine Builder Container

**Build the image** (once):

```bash
cd looni-wine_builder

podman build \
    --build-arg BUILD_USER="$(whoami)" \
    --build-arg BUILD_UID="$(id -u)" \
    --build-arg BUILD_GID="$(id -g)" \
    -t wine-builder .
```

**Run a build:**

```bash
podman run --rm -it \
    -v "$(pwd)":/home/"$(whoami)"/wine-builder:z \
    -v "${HOME}/wine-builds":/home/"$(whoami)"/wine-builds:z \
    wine-builder \
    bash wine-builder.sh --source staging
```

### Proton Builder Container

**Build the image** (once):

```bash
cd looni-neutron_builder

podman build \
    --build-arg BUILD_USER="$(whoami)" \
    --build-arg BUILD_UID="$(id -u)" \
    --build-arg BUILD_GID="$(id -g)" \
    -t looni-neutron_builder \
    -f Containerfile.neutron .
```

**Run a build:**

```bash
podman run --rm -it \
    -v "$(pwd)":/home/"$(whoami)"/looni-neutron_builder:z \
    -v looni-neutron_builder-ccache:/home/"$(whoami)"/.ccache:z \
    looni-neutron_builder \
    bash neutron-builder.sh --source proton-wine
```

### Container Notes

- **Build args** (`BUILD_USER`, `BUILD_UID`, `BUILD_GID`) match your host user so
  bind-mounted files have correct ownership — no root permission headaches.
- **ccache volume** — the proton container example uses a named volume for ccache.
  This persists across runs so rebuilds are dramatically faster.
- **Image size** is ~5–6 GB. Only rebuild when the Containerfile changes.
- **ntsync header** — the proton container includes a bundled `ntsync.h` (Linux 6.14+
  kernel header) since Ubuntu 24.04's `linux-libc-dev` predates ntsync. No manual
  download needed.
- All interactive features (fzf pickers, version selectors) work inside the container
  as long as you pass `-it` for an interactive TTY.

### Installing Podman

```bash
sudo apt install podman            # Debian / Ubuntu
sudo dnf install podman            # Fedora
sudo pacman -S podman              # Arch
```

---

## Requirements

> **Using containers?** Skip straight to
> [Building with Containers](#building-with-containers-recommended) — the
> Containerfiles handle all build dependencies. The requirements below are only
> needed for native (host) builds.

### Core

| Tool | Used by | Notes |
|------|---------|-------|
| `bash` 4.4+ | All | Required |
| `git` | wine-builder, neutron-builder | Source fetching |
| `zenity` | winetoolz, Wine Install Manager | GUI dialogs |
| `fzf` | All builders, main menu | Optional — nicer interactive pickers |

### Build Dependencies

| Tool | Used by |
|------|---------|
| `make`, `gcc`, `g++`, `autoconf`, `automake` | wine-builder, neutron-builder |
| `pkg-config` | wine-builder, neutron-builder |
| `i686-linux-gnu-gcc`, `i686-linux-gnu-g++` | 32-bit Wine builds |
| `x86_64-w64-mingw32-gcc`, `x86_64-w64-mingw32-g++` | MinGW cross-compile |
| `meson`, `ninja` | neutron-builder (DXVK / VKD3D-Proton) |
| `glslangValidator` | neutron-builder (DXVK / VKD3D-Proton) |
| `ccache` | Optional — strongly recommended for rebuilds |

### Runtime Dependencies

| Tool | Used by |
|------|---------|
| `rsync` | wine-proton_hybrid, Wine Install Manager |
| `python3` | wine-proton_hybrid |
| `curl` | winetoolz (GitHub release downloads) |
| `tar`, `zstd` | winetoolz (archive extraction) |

### One-Liner (Debian/Ubuntu)

```bash
sudo apt install git make gcc g++ autoconf automake pkg-config \
    gcc-i686-linux-gnu g++-i686-linux-gnu \
    gcc-mingw-w64 g++-mingw-w64 \
    meson ninja-build glslang-tools \
    rsync python3 curl ccache fzf zenity zstd
```

---

## Uninstall

```bash
make uninstall
```

This removes all installed scripts and lib directories. You'll be asked whether to
clean up `~/.bashrc` entries.

**Config files** in `~/.config/looni-build/` are **kept** — remove manually if wanted.

**Build output** in `~/.local/share/looni-wine_builder/` and
`~/.local/share/looni-neutron_builder/` is **kept** — these are your compiled builds.

**Managed Wine installs** in `~/.local/share/looni-wine-installs/` are **kept** —
use the Wine Install Manager to remove individual builds first, or delete the
directory manually.

---

*looni edition — made with love :3*
