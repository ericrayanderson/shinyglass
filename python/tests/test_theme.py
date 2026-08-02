"""Unit tests for the shinyglass Python spike."""

from __future__ import annotations

import re

import pytest

from shinyglass import glass_theme
from shinyglass._assets import js_dir, package_root, scss_path


def test_assets_resolve_from_monorepo():
    root = package_root()
    assert (root / "inst" / "scss" / "glass.scss").is_file()
    assert scss_path().is_file()
    assert (js_dir() / "shiny-glass.js").is_file()


def test_glass_theme_returns_theme():
    theme = glass_theme()
    assert theme.name == "shinyglass-light"
    css = theme.to_css()
    assert isinstance(css, str)
    assert len(css) > 10_000
    assert "glass-sidebar-reserve" in css or "glass-sidebar-reserve" in css.replace(
        "\\", ""
    )


def test_compiled_css_has_sidebar_and_adminlte_hooks():
    css = glass_theme(preset="light").to_css()
    # Nested / float sidebar rules from shared SCSS
    assert "bslib-sidebar-layout" in css
    assert re.search(r"position:\s*absolute", css)
    assert "main-sidebar" in css  # AdminLTE overlay


def test_dark_preset_differs():
    light = glass_theme(preset="light").to_css()
    dark = glass_theme(preset="dark").to_css()
    assert light != dark


def test_html_deps_include_js():
    theme = glass_theme()
    deps = theme._html_dependencies()
    names = [d.name for d in deps]
    assert "shinyglass" in names
    assert "shinyglass-preset" in names


def test_invalid_preset():
    with pytest.raises(ValueError):
        glass_theme(preset="neon")  # type: ignore[arg-type]
