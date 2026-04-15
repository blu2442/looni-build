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
