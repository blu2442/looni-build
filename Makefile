# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  looni-build  •  Makefile  (subdirectory layout)                           ║
# ║  Installs / uninstalls all builder and winetoolz scripts                   ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Usage:
#   make install          — install everything to $(PREFIX)
#   make install-proton   — install only looni-proton_builder
#   make install-wine     — install only looni-wine_builder
#   make install-hybrid   — install only looni-wine-proton_hybrid_builder
#   make install-toolz    — install only looni-winetoolz
#   make uninstall        — remove everything installed by this Makefile
#   make help             — show this reference
#
# Variables:
#   PREFIX=<dir>    Install root  (default: ~/.local)
#   DESTDIR=<dir>   Staging root  (default: empty — install live)
#
#   make install PREFIX=~/.local          # user install (default)
#   make install PREFIX=/usr/local        # system-wide (needs sudo)
#   make install DESTDIR=/tmp/pkg         # staged for packaging
#

# ── Install layout ────────────────────────────────────────────────────────────
PREFIX  ?= $(HOME)/.local
BINDIR  := $(PREFIX)/bin

# Each sub-project gets its own lib directory so internal SCRIPT_DIR-relative
# paths continue to work correctly after install.
PROTON_LIBDIR := $(PREFIX)/lib/looni-proton_builder
WINE_LIBDIR   := $(PREFIX)/lib/looni-wine_builder
HYBRID_LIBDIR := $(PREFIX)/lib/looni-wine-proton_hybrid_builder
TOOLZ_LIBDIR  := $(PREFIX)/lib/looni-winetoolz

CFGDIR  := $(HOME)/.config/looni-build
DESTDIR ?=

# ── .bashrc management ───────────────────────────────────────────────────
BASHRC          := $(HOME)/.bashrc
MARKER_PATH_B   := \# ── looni-build PATH ──
MARKER_PATH_E   := \# ── end looni-build PATH ──
MARKER_WINE_B   := \# ── looni-build wine-default ──
MARKER_WINE_E   := \# ── end looni-build wine-default ──

# ── Source roots ──────────────────────────────────────────────────────────────
ROOT   := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
LAUNCHER := $(ROOT)looni-build.sh
PROTON := $(ROOT)looni-proton_builder
WINE   := $(ROOT)looni-wine_builder
HYBRID := $(ROOT)looni-wine-proton_hybrid_builder
TOOLZ  := $(ROOT)looni-winetoolz

# ── File lists ────────────────────────────────────────────────────────────────

# proton_builder: launcher + engine scripts
PROTON_BIN  := proton-builder.sh
PROTON_LIBS := \
    proton-build-core.sh \
    proton-dxvk-build.sh \
    proton-vkd3d-build.sh \
    proton-package.sh \
    spinner.sh \
    ntsync.h \
    deps-proton-tkg
PROTON_CFG  := proton-customization.cfg

# wine_builder: launcher + engine scripts
WINE_BIN  := wine-builder.sh
WINE_LIBS := \
    wine-build-core.sh \
    build-32.sh \
    build-64.sh \
    helper.sh \
    install-from-build.sh \
    wine-tkg-patcher.sh \
    deps-tkg
WINE_CFG  := customization.cfg

# hybrid installer: launcher only
HYBRID_BIN := wine-proton_hybrid-v1.0.0.sh

# winetoolz: launcher + all modules
TOOLZ_BIN     := wine_toolz.sh
TOOLZ_MODULES := \
    modules/winetoolz-lib.sh \
    modules/shared_lib/about.sh \
    modules/shared_lib/app_launcher.sh \
    modules/shared_lib/directx_installer-local.sh \
    modules/shared_lib/dll_installer.sh \
    modules/shared_lib/dll_override_manager.sh \
    modules/shared_lib/dxvk_setup-gui.sh \
    modules/shared_lib/env_flags.sh \
    modules/shared_lib/install_components-x86_64.sh \
    modules/shared_lib/install_nvapi.sh \
    modules/shared_lib/log_viewer.sh \
    modules/shared_lib/prefix_diagnostics.sh \
    modules/shared_lib/prefix_manager.sh \
    modules/shared_lib/runtime_manager.sh \
    modules/shared_lib/runtimes_installer.sh \
    modules/shared_lib/setup_vkd3d_proton-gui.sh \
    modules/shared_lib/vcruntime_installer-gui.sh \
    modules/shared_lib/wine_tools.sh \
    modules/shared_lib/wine_install_manager.sh \
    modules/shared_lib/winetoolz-prefix-maker.sh

# ── Phony targets ─────────────────────────────────────────────────────────────
.PHONY: all install install-proton install-wine install-hybrid install-toolz \
        install-launcher uninstall help _dirs _setup-path

all: help

# ── install ───────────────────────────────────────────────────────────────────
install: _dirs install-launcher install-proton install-wine install-hybrid install-toolz _setup-path
	@printf "\n\033[1;32m ✓  looni-build installed to %s\033[0m\n\n" "$(DESTDIR)$(PREFIX)"
	@printf "  looni-build        → $(DESTDIR)$(BINDIR)/looni-build\n"
	@printf "  proton-builder     → $(DESTDIR)$(BINDIR)/proton-builder\n"
	@printf "  wine-builder       → $(DESTDIR)$(BINDIR)/wine-builder\n"
	@printf "  wine_toolz         → $(DESTDIR)$(BINDIR)/wine_toolz\n"
	@printf "  wine-proton_hybrid → $(DESTDIR)$(BINDIR)/wine-proton_hybrid\n"
	@printf "  config             → $(DESTDIR)$(CFGDIR)/\n\n"
	@printf "  Make sure \033[1m$(PREFIX)/bin\033[0m is in your PATH.\n\n"

_dirs:
	install -d "$(DESTDIR)$(BINDIR)"
	install -d "$(DESTDIR)$(PROTON_LIBDIR)"
	install -d "$(DESTDIR)$(PROTON_LIBDIR)/patches"
	install -d "$(DESTDIR)$(WINE_LIBDIR)"
	install -d "$(DESTDIR)$(WINE_LIBDIR)/patches"
	install -d "$(DESTDIR)$(HYBRID_LIBDIR)"
	install -d "$(DESTDIR)$(HYBRID_LIBDIR)/buildz"
	install -d "$(DESTDIR)$(TOOLZ_LIBDIR)/modules/shared_lib"
	install -d "$(DESTDIR)$(CFGDIR)"

# ── looni-proton_builder ──────────────────────────────────────────────────────
install-proton: _dirs
	@printf "\033[1;36m── looni-proton_builder\033[0m\n"
	install -m 755 "$(PROTON)/$(PROTON_BIN)" \
	    "$(DESTDIR)$(BINDIR)/proton-builder"
	@printf "  \033[1;32m+\033[0m $(DESTDIR)$(BINDIR)/proton-builder\n"
	@for f in $(PROTON_LIBS); do \
	    src="$(PROTON)/$$f"; \
	    [ -f "$$src" ] || { printf "  \033[2mskip (not found): $$f\033[0m\n"; continue; }; \
	    install -m 755 "$$src" "$(DESTDIR)$(PROTON_LIBDIR)/$$f"; \
	    printf "  \033[1;32m+\033[0m $(DESTDIR)$(PROTON_LIBDIR)/$$f\n"; \
	done
	@src="$(PROTON)/$(PROTON_CFG)"; dest="$(DESTDIR)$(CFGDIR)/$(PROTON_CFG)"; \
	[ -f "$$src" ] || exit 0; \
	if [ -f "$$dest" ]; then \
	    printf "  \033[2m~ keep existing: $$dest\033[0m\n"; \
	else \
	    install -m 644 "$$src" "$$dest"; \
	    printf "  \033[1;32m+\033[0m $$dest\n"; \
	fi

# ── looni-wine_builder ────────────────────────────────────────────────────────
install-wine: _dirs
	@printf "\033[1;36m── looni-wine_builder\033[0m\n"
	install -m 755 "$(WINE)/$(WINE_BIN)" \
	    "$(DESTDIR)$(BINDIR)/wine-builder"
	@printf "  \033[1;32m+\033[0m $(DESTDIR)$(BINDIR)/wine-builder\n"
	@for f in $(WINE_LIBS); do \
	    src="$(WINE)/$$f"; \
	    [ -f "$$src" ] || { printf "  \033[2mskip (not found): $$f\033[0m\n"; continue; }; \
	    install -m 755 "$$src" "$(DESTDIR)$(WINE_LIBDIR)/$$f"; \
	    printf "  \033[1;32m+\033[0m $(DESTDIR)$(WINE_LIBDIR)/$$f\n"; \
	done
	@src="$(WINE)/$(WINE_CFG)"; dest="$(DESTDIR)$(CFGDIR)/$(WINE_CFG)"; \
	[ -f "$$src" ] || exit 0; \
	if [ -f "$$dest" ]; then \
	    printf "  \033[2m~ keep existing: $$dest\033[0m\n"; \
	else \
	    install -m 644 "$$src" "$$dest"; \
	    printf "  \033[1;32m+\033[0m $$dest\n"; \
	fi

# ── looni-build launcher ─────────────────────────────────────────────────────
install-launcher: _dirs
	@printf "\033[1;36m── looni-build launcher\033[0m\n"
	install -m 755 "$(LAUNCHER)" \
	    "$(DESTDIR)$(BINDIR)/looni-build"
	@printf "  \033[1;32m+\033[0m $(DESTDIR)$(BINDIR)/looni-build\n"

# ── looni-wine-proton_hybrid_builder ─────────────────────────────────────────
install-hybrid: _dirs
	@printf "\033[1;36m── looni-wine-proton_hybrid_builder\033[0m\n"
	install -m 755 "$(HYBRID)/$(HYBRID_BIN)" \
	    "$(DESTDIR)$(BINDIR)/wine-proton_hybrid"
	@printf "  \033[1;32m+\033[0m $(DESTDIR)$(BINDIR)/wine-proton_hybrid\n"

# ── looni-winetoolz ───────────────────────────────────────────────────────────
install-toolz: _dirs
	@printf "\033[1;36m── looni-winetoolz\033[0m\n"
	install -m 755 "$(TOOLZ)/$(TOOLZ_BIN)" \
	    "$(DESTDIR)$(BINDIR)/wine_toolz"
	@printf "  \033[1;32m+\033[0m $(DESTDIR)$(BINDIR)/wine_toolz\n"
	@for f in $(TOOLZ_MODULES); do \
	    src="$(TOOLZ)/$$f"; \
	    [ -f "$$src" ] || { printf "  \033[2mskip (not found): $$f\033[0m\n"; continue; }; \
	    install -m 755 "$$src" "$(DESTDIR)$(TOOLZ_LIBDIR)/$$f"; \
	    printf "  \033[1;32m+\033[0m $(DESTDIR)$(TOOLZ_LIBDIR)/$$f\n"; \
	done

# ── .bashrc PATH setup (skipped during staged/packaged installs) ─────────────
_setup-path:
	@if [ -n "$(DESTDIR)" ]; then exit 0; fi; \
	if [ -f "$(BASHRC)" ] && grep -qF '$(MARKER_PATH_B)' "$(BASHRC)"; then \
	    printf "  \033[2m~/.bashrc: looni-build PATH block already present — skipped\033[0m\n"; \
	else \
	    { printf '\n$(MARKER_PATH_B)\n'; \
	      printf 'export PATH="%s/bin:$$PATH"\n' "$(PREFIX)"; \
	      printf '$(MARKER_PATH_E)\n'; \
	    } >> "$(BASHRC)"; \
	    printf "  \033[1;32m+\033[0m ~/.bashrc: added looni-build PATH block\n"; \
	    printf "    \033[2mRun:  source ~/.bashrc   (or open a new terminal)\033[0m\n"; \
	fi

# ── uninstall ─────────────────────────────────────────────────────────────────
uninstall:
	@printf "\033[1;33mRemoving looni-build from %s ...\033[0m\n" "$(DESTDIR)$(PREFIX)"
	@for cmd in looni-build proton-builder wine-builder wine_toolz wine-proton_hybrid; do \
	    f="$(DESTDIR)$(BINDIR)/$$cmd"; \
	    [ -f "$$f" ] && { rm -f "$$f"; printf "  \033[1;31m-\033[0m $$f\n"; } || true; \
	done
	@for d in "$(DESTDIR)$(PROTON_LIBDIR)" \
	          "$(DESTDIR)$(WINE_LIBDIR)" \
	          "$(DESTDIR)$(HYBRID_LIBDIR)" \
	          "$(DESTDIR)$(TOOLZ_LIBDIR)"; do \
	    [ -d "$$d" ] && { rm -rf "$$d"; printf "  \033[1;31m-\033[0m $$d/\n"; } || true; \
	done
	@printf "\n\033[1;32m ✓  Uninstall complete.\033[0m\n"
	@printf "    Config in \033[1m$(DESTDIR)$(CFGDIR)\033[0m left in place — remove manually if needed.\n\n"
	@if [ -n "$(DESTDIR)" ]; then exit 0; fi; \
	_has_path=false; _has_wine=false; \
	if [ -f "$(BASHRC)" ] && grep -qF '$(MARKER_PATH_B)' "$(BASHRC)"; then _has_path=true; fi; \
	if [ -f "$(BASHRC)" ] && grep -qF '$(MARKER_WINE_B)' "$(BASHRC)"; then _has_wine=true; fi; \
	if [ "$$_has_path" = "true" ] || [ "$$_has_wine" = "true" ]; then \
	    printf "\033[1;33m  looni-build entries found in ~/.bashrc:\033[0m\n"; \
	    [ "$$_has_path" = "true" ] && printf "    • looni-build PATH block\n"; \
	    [ "$$_has_wine" = "true" ] && printf "    • Wine default block\n"; \
	    printf "\n  Remove these entries? [y/N] "; \
	    read -r _ans; \
	    case "$$_ans" in \
	        [yY]|[yY][eE][sS]) \
	            sed -i '\,^$(MARKER_PATH_B)$$,, \,^$(MARKER_PATH_E)$$, d' "$(BASHRC)" 2>/dev/null || true; \
	            sed -i '\,^$(MARKER_WINE_B)$$,, \,^$(MARKER_WINE_E)$$, d' "$(BASHRC)" 2>/dev/null || true; \
	            printf "  \033[1;31m-\033[0m ~/.bashrc: looni-build entries removed\n"; \
	            printf "    \033[2mRun:  source ~/.bashrc   (or open a new terminal)\033[0m\n\n"; \
	            ;; \
	        *) printf "  \033[2m~/.bashrc: entries left in place\033[0m\n\n" ;; \
	    esac; \
	fi

# ── help ──────────────────────────────────────────────────────────────────────
help:
	@printf "\n\033[1mlooni-build — Wine / Proton builders + winetoolz\033[0m\n\n"
	@printf "\033[1mTargets:\033[0m\n"
	@printf "  \033[1;36mmake install\033[0m           Install all sub-projects + add PATH to ~/.bashrc\n"
	@printf "  \033[1;36mmake install-launcher\033[0m  looni-build launcher only\n"
	@printf "  \033[1;36mmake install-proton\033[0m    looni-proton_builder only\n"
	@printf "  \033[1;36mmake install-wine\033[0m      looni-wine_builder only\n"
	@printf "  \033[1;36mmake install-hybrid\033[0m    looni-wine-proton_hybrid_builder only\n"
	@printf "  \033[1;36mmake install-toolz\033[0m     looni-winetoolz only\n"
	@printf "  \033[1;36mmake uninstall\033[0m         Remove all installed files (asks about ~/.bashrc)\n"
	@printf "  \033[1;36mmake help\033[0m              Show this message\n"
	@printf "\n\033[1mVariables:\033[0m\n"
	@printf "  PREFIX=<dir>    Install root  (default: $(HOME)/.local)\n"
	@printf "  DESTDIR=<dir>   Staging root  (default: empty)\n"
	@printf "\n\033[1mInstall layout:\033[0m\n"
	@printf "  $(PREFIX)/bin/\n"
	@printf "      proton-builder  wine-builder  wine_toolz  wine-proton_hybrid\n"
	@printf "  $(PREFIX)/lib/looni-proton_builder/\n"
	@printf "      *.sh  ntsync.h  deps-proton-tkg\n"
	@printf "  $(PREFIX)/lib/looni-proton_builder/patches/\n"
	@printf "      ← drop .patch/.diff here to apply before proton-wine configure\n"
	@printf "  $(PREFIX)/lib/looni-wine-proton_hybrid_builder/buildz/\n"
	@printf "      ← hybrid builds install here when using 'local' mode\n"
	@printf "  $(PREFIX)/lib/looni-wine_builder/\n"
	@printf "      *.sh  deps-tkg\n"
	@printf "  $(PREFIX)/lib/looni-wine_builder/patches/\n"
	@printf "      ← drop .patch/.diff here to apply before Wine configure\n"
	@printf "  $(PREFIX)/lib/looni-winetoolz/modules/shared_lib/\n"
	@printf "  $(HOME)/.config/looni-build/    ← cfg files (never overwritten)\n"
	@printf "\n\033[1mRuntime dirs (created by scripts on first run):\033[0m\n"
	@printf "  <data-dir>/buildz/install/       ← finished Wine / Proton installs\n"
	@printf "  <data-dir>/buildz/build-run/     ← in-progress build trees\n"
	@printf "  <data-dir>/src/                  ← git-cloned sources\n"
	@printf "  (data-dir defaults to the lib dir; override with --dest / --src-dir)\n"
	@printf "\n\033[1mQuick start:\033[0m\n"
	@printf "  looni-build                     # launch the main menu\n"
	@printf "  proton-builder                  # build Proton interactively\n"
	@printf "  wine-builder                    # build Wine interactively\n"
	@printf "  wine_toolz                      # open winetoolz\n"
	@printf "  wine-proton_hybrid              # hybrid installer\n\n"
	@printf "\033[1m~/.bashrc management:\033[0m\n"
	@printf "  make install   adds a PATH block so looni-build commands are available.\n"
	@printf "  wine-builder   offers to set a completed build as your default Wine\n"
	@printf "                 (adds PATH + WINEPREFIX + WINESERVER exports).\n"
	@printf "  make uninstall asks whether to remove both blocks.\n"
	@printf "  Both blocks are skipped when DESTDIR is set (packaging mode).\n\n"
