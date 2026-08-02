#!/usr/bin/env python3
"""Vendor shared SCSS/JS into the Python package and precompile theme CSS.

Run from monorepo::

    python python/scripts/vendor_assets.py

Or from ``python/``::

    python scripts/vendor_assets.py

Outputs under ``src/shinyglass/static/``:

* ``glass.scss`` — copy of shared source
* ``shiny-glass.js`` — copy of shared JS
* ``theme-light.css`` / ``theme-dark.css`` — full Bootstrap + glass (default knobs)
* ``glass-rules-light.css`` / ``glass-rules-dark.css`` — glass.scss only (debug)

Requires monorepo ``inst/`` (or ``SHINYGLASS_PKG_ROOT``) at vendor time.
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

PYTHON_ROOT = Path(__file__).resolve().parents[1]
STATIC = PYTHON_ROOT / "src" / "shinyglass" / "static"
REPO_ROOT = PYTHON_ROOT.parent


def _monorepo_root() -> Path:
    env = os.environ.get("SHINYGLASS_PKG_ROOT", "").strip()
    if env and (Path(env) / "inst" / "scss" / "glass.scss").is_file():
        return Path(env).resolve()
    if (REPO_ROOT / "inst" / "scss" / "glass.scss").is_file():
        return REPO_ROOT.resolve()
    raise FileNotFoundError(
        "Monorepo inst/scss/glass.scss not found. Set SHINYGLASS_PKG_ROOT or "
        "run this script from the shinyglass git checkout."
    )


def _bootstrap_stubs() -> str:
    return """
@mixin media-breakpoint-up($name) {
  @if $name == sm {
    @media (min-width: 576px) { @content; }
  } @else if $name == md {
    @media (min-width: 768px) { @content; }
  } @else if $name == lg {
    @media (min-width: 992px) { @content; }
  } @else if $name == xl {
    @media (min-width: 1200px) { @content; }
  } @else {
    @content;
  }
}
"""


def _compile_glass_rules(scss_text: str, tokens: dict[str, str], blur: int, saturation: int, radius: str) -> str:
    import sass

    defaults = "\n".join(
        [
            f"$primary: #007AFF !default;",
            f"$success: #34C759 !default;",
            f"$danger: #FF3B30 !default;",
            f"$warning: #FF9500 !default;",
            f"$info: #5AC8FA !default;",
            f"$body-color: {tokens['body_color']} !default;",
            f"$prefix: bs- !default;",
            f"$glass-bg: {tokens['glass_bg']} !default;",
            f"$glass-bg-hover: {tokens['glass_bg_hover']} !default;",
            f"$glass-border: {tokens['glass_border']} !default;",
            f"$glass-shadow: {tokens['glass_shadow']} !default;",
            f"$glass-elevated-shadow: {tokens['glass_elevated_shadow']} !default;",
            f"$glass-blur: {blur}px !default;",
            f"$glass-saturate: {saturation}% !default;",
            f"$glass-radius: {radius} !default;",
            f"$glass-highlight: {tokens['glass_highlight']} !default;",
            f"$glass-specular: {tokens['glass_specular']} !default;",
            f"$glass-menu-bg: {tokens['glass_menu_bg']} !default;",
            f"$glass-menu-color: {tokens['glass_menu_color']} !default;",
            f"$glass-page-bg: {tokens['page_bg']} !default;",
            f"$glass-orb-1: {tokens['orb_1']} !default;",
            f"$glass-orb-2: {tokens['orb_2']} !default;",
            f"$glass-orb-3: {tokens['orb_3']} !default;",
        ]
    )
    return sass.compile(
        string=defaults + _bootstrap_stubs() + scss_text,
        output_style="compressed",
    )


def vendor(*, quiet: bool = False) -> Path:
    """Copy assets + precompile CSS into ``static/``. Returns static dir."""
    root = _monorepo_root()
    scss_src = root / "inst" / "scss" / "glass.scss"
    js_src = root / "inst" / "js" / "shiny-glass.js"
    if not scss_src.is_file():
        raise FileNotFoundError(scss_src)
    if not js_src.is_file():
        raise FileNotFoundError(js_src)

    STATIC.mkdir(parents=True, exist_ok=True)

    # Ensure package imports resolve when run as a script
    sys.path.insert(0, str(PYTHON_ROOT / "src"))

    from shinyglass.theme import (  # noqa: WPS433
        _tokens,
        glass_theme,
    )

    shutil.copy2(scss_src, STATIC / "glass.scss")
    shutil.copy2(js_src, STATIC / "shiny-glass.js")

    scss_text = scss_src.read_text(encoding="utf-8")

    for preset in ("light", "dark"):
        tokens = _tokens(preset)  # type: ignore[arg-type]
        rules_css = _compile_glass_rules(scss_text, tokens, 28, 200, "1.25rem")
        (STATIC / f"glass-rules-{preset}.css").write_text(rules_css, encoding="utf-8")

        theme = glass_theme(preset=preset, _allow_compile=True)  # type: ignore[call-arg]
        # Force Sass compile path for vendoring (ignore existing precompiled)
        theme._precompiled_css = None  # type: ignore[attr-defined]
        full_css = theme.to_css()
        (STATIC / f"theme-{preset}.css").write_text(full_css, encoding="utf-8")

        if not quiet:
            print(
                f"  theme-{preset}.css  {len(full_css):,} bytes  "
                f"glass-rules-{preset}.css  {len(rules_css):,} bytes"
            )

    # Marker for runtime detection
    (STATIC / "MANIFEST.txt").write_text(
        "\n".join(
            [
                "shinyglass static assets",
                f"source={root}",
                "files=glass.scss,shiny-glass.js,theme-light.css,theme-dark.css,"
                "glass-rules-light.css,glass-rules-dark.css",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    if not quiet:
        print(f"Vendored → {STATIC}")
    return STATIC


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-q", "--quiet", action="store_true")
    args = parser.parse_args(argv)
    try:
        vendor(quiet=args.quiet)
    except Exception as exc:  # pragma: no cover
        print(f"vendor_assets failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
