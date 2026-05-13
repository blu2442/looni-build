"""Shared test fixtures."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Iterator

import pytest

from looni_build.core.tools import TOOLS


@pytest.fixture
def fake_source_tree(tmp_path: Path) -> Path:
    """Build a fake looni-build source-tree checkout at *tmp_path*.

    Creates empty shell scripts at every :attr:`Tool.source_relpath` plus
    the root markers needed by :func:`resolve_root`. Returns the root.
    """
    # Root markers
    (tmp_path / "looni-build.sh").write_text("#!/usr/bin/env bash\n")
    (tmp_path / "looni-neutron_builder").mkdir()
    (tmp_path / "looni-wine_builder").mkdir()

    # Every tool script
    for tool in TOOLS:
        script = tmp_path / tool.source_relpath
        script.parent.mkdir(parents=True, exist_ok=True)
        script.write_text(f"#!/usr/bin/env bash\necho {tool.key}\n")
        script.chmod(0o755)

    return tmp_path


@pytest.fixture
def clean_env(monkeypatch: pytest.MonkeyPatch) -> Iterator[None]:
    """Unset LOONI_ROOT and strip PATH to /usr/bin only so discovery falls
    through to source-tree / install-prefix probing deterministically."""
    monkeypatch.delenv("LOONI_ROOT", raising=False)
    monkeypatch.setenv("PATH", "/nonexistent-path-for-tests")
    # Redirect HOME so we don't see the user's real ~/.local/bin.
    monkeypatch.setenv("HOME", "/nonexistent-home-for-tests")
    yield
