"""Allow ``python -m looni_build`` as an alternate entry point."""

from __future__ import annotations

from looni_build.cli import main

if __name__ == "__main__":
    main()
