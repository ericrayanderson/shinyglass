"""Locate glass assets: vendored package data first, monorepo inst/ fallback."""

from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path

# Files shipped inside the wheel under shinyglass/static/
_STATIC_DIRNAME = "static"


def _package_static() -> Path:
    return Path(__file__).resolve().parent / _STATIC_DIRNAME


def _monorepo_candidates() -> list[Path]:
    out: list[Path] = []
    env = os.environ.get("SHINYGLASS_PKG_ROOT", "").strip()
    if env:
        out.append(Path(env))
    here = Path(__file__).resolve()
    # src/shinyglass/_assets.py → parents[3] is repo root in editable monorepo layout
    out.extend(
        [
            here.parents[3],
            here.parents[2],
            Path.cwd(),
            Path.cwd().parent,
        ]
    )
    return out


@lru_cache(maxsize=1)
def package_root() -> Path | None:
    """R package / monorepo root if available (else ``None``)."""
    for root in _monorepo_candidates():
        if (root / "inst" / "scss" / "glass.scss").is_file():
            return root.resolve()
    return None


def has_vendored_static() -> bool:
    static = _package_static()
    return (static / "theme-light.css").is_file() and (
        static / "shiny-glass.js"
    ).is_file()


def static_dir() -> Path:
    """Directory with vendored CSS/JS (wheel) or raise if missing."""
    static = _package_static()
    if (static / "theme-light.css").is_file():
        return static
    raise FileNotFoundError(
        f"Vendored static assets not found under {static}. "
        "Run `python scripts/vendor_assets.py` from the monorepo, or install "
        "a built wheel that includes static/."
    )


def precompiled_theme_css(preset: str) -> Path:
    path = static_dir() / f"theme-{preset}.css"
    if not path.is_file():
        raise FileNotFoundError(path)
    return path


def js_dir() -> Path:
    """Directory containing ``shiny-glass.js`` (vendored or monorepo)."""
    static = _package_static()
    if (static / "shiny-glass.js").is_file():
        return static
    root = package_root()
    if root is not None:
        path = root / "inst" / "js"
        if (path / "shiny-glass.js").is_file():
            return path
    raise FileNotFoundError(
        "shiny-glass.js not found in package static/ or monorepo inst/js/"
    )


def scss_path() -> Path:
    """Path to ``glass.scss`` (vendored copy preferred, else monorepo)."""
    static = _package_static()
    vendored = static / "glass.scss"
    if vendored.is_file():
        return vendored
    root = package_root()
    if root is not None:
        path = root / "inst" / "scss" / "glass.scss"
        if path.is_file():
            return path
    raise FileNotFoundError(
        "glass.scss not found in package static/ or monorepo inst/scss/"
    )


def asset_source() -> str:
    """Human-readable origin for diagnostics: ``vendored`` or ``monorepo``."""
    if has_vendored_static():
        return "vendored"
    if package_root() is not None:
        return "monorepo"
    return "missing"
