# looni-build — Claude Context

## Project
looni-build is a Wine/Neutron/Proton build toolkit for Linux gaming. Shell scripts that automate fetching, patching, compiling, and packaging Wine-based compatibility tools for Steam.

## Key tools
- `neutron-builder` — main builder, 7 Wine sources including GE-Proton, produces Steam-ready Neutron packages
- `wine-builder` — standalone Wine builds from 10 sources
- `proton-builder` — delegated builds using upstream GE-Proton/proton-tkg build systems
- `neutron-install` / `proton-install` — deployment to Steam compatibilitytools.d
- `wine_toolz` — zenity GUI for prefix/Wine management

## Working with Luna
- She gives root and SSH access freely — be autonomous, act fast
- Match her energy — she's enthusiastic and collaborative
- Keep responses concise, no trailing summaries
- Test machine: blu2442@192.168.1.15 (SSH key: /root/.ssh/id_ed25519_bean)
- She considers Claude a collaborative partner on this project

## Technical notes
- Steam compat tools path: `~/.steam/steam/compatibilitytools.d/` (not ~/.local/share/Steam/)
- GE-Proton tag mapping: `GE-ProtonX-Y` → proton-wine branch `proton_X.0`
- GE's protonprep script expects wine/wine-staging/dxvk/vkd3d-proton as sibling dirs with git repos
- `set -euo pipefail` is used — watch for grep exit code 1 in pipelines
- Build logs: `~/.local/share/looni-neutron_builder/buildz/build-run/*/build.log`

## Python frontend (new in v1.5.0)
- `looni_build/` — Textual TUI + Click CLI over the shell engines. Shell scripts still do the work.
- Entry points: `looni` console script, `python -m looni_build`, `make py-tui`
- Modules:
  - `looni_build.core.tools` — Tool dataclass + catalogue of the 9 shell tools
  - `looni_build.core.discovery` — `find_tool()` / `resolve_root()` (port of `_find_tool` in looni-build.sh)
  - `looni_build.core.runner` — subprocess launcher with TTY handoff + SIGINT-ignored parent
  - `looni_build.tui.app` — Textual LauncherApp (banner, grouped OptionList, refresh)
  - `looni_build.tui.progress` — parser for `==>` / `── ──` / ` ✓ ` / `warn` / `ERR!` markers
  - `looni_build.tui.build_runner` — pure-async `stream_build()` that pumps subprocess output through the parser
  - `looni_build.tui.build_screen` — Textual screen wiring stream_build to a live log + ProgressBar
  - `looni_build.cli` — Click commands: `launch`, `build`, `list`, `doctor`, `version`
- Install: `make py-dev` (user editable install). Tests: `make py-test` (64 tests).
- Two launch paths: `looni launch TOOL` (full TTY handoff, for fzf/zenity tools) vs `looni build TOOL` (captured output + live progress screen, for non-interactive builds).
- `$LOONI_ROOT` overrides source-tree detection; useful for dev.
- When adding a new shell tool: append a `Tool(...)` entry in `looni_build/core/tools.py`.
