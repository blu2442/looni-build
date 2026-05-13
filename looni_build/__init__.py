"""looni-build — Python TUI frontend over the shell build engines.

This package is a thin, modern Python layer on top of the battle-tested
``looni-*`` shell scripts. The shell scripts still do all the real build
work; Python just handles the launcher UX, config, discovery, and
orchestration.

Entry points:
  - ``looni`` console script          → :func:`looni_build.cli.main`
  - ``python -m looni_build``          → :mod:`looni_build.__main__`
"""

from __future__ import annotations

__version__ = "1.0.0"

__all__ = ["__version__"]
