"""Locate shared SCSS/JS assets from the R package tree (Option 2)."""

from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path


def _candidates() -> list[Path]:
    """Ordered paths that may contain ``inst/scss/glass.scss``."""
    out: list[Path] = []

    env = os.environ.get("SHINYGLASS_PKG_ROOT", "").strip()
    if env:
        out.append(Path(env))

    # python/src/shinyglass/_assets.py → repo root is parents[3]
    here = Path(__file__).resolve()
    out.extend(
        [
            here.parents[3],  # .../shinyglass (repo root)
            here.parents[2],  # .../python
            Path.cwd(),
            Path.cwd().parent,
        ]
    )
    return out


@lru_cache(maxsize=1)
def package_root() -> Path:
    """Return the shinyglass repo / R package root that holds ``inst/``."""
    for root in _candidates():
        scss = root / "inst" / "scss" / "glass.scss"
        if scss.is_file():
            return root.resolve()
    searched = ", ".join(str(p) for p in _candidates())
    raise FileNotFoundError(
        "Could not find inst/scss/glass.scss. Run from the shinyglass git "
        "checkout (Option 2: python/ next to inst/), or set SHINYGLASS_PKG_ROOT "
        f"to the R package root. Looked in: {searched}"
    )


def scss_path() -> Path:
    return package_root() / "inst" / "scss" / "glass.scss"


def js_dir() -> Path:
    path = package_root() / "inst" / "js"
    if not (path / "shiny-glass.js").is_file():
        raise FileNotFoundError(f"shiny-glass.js not found under {path}")
    return path
