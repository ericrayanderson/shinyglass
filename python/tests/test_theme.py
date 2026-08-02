"""Unit tests for shinyglass Python package."""

from __future__ import annotations

import re
from pathlib import Path

import pytest

from shinyglass import glass_theme
from shinyglass._assets import (
    asset_source,
    has_vendored_static,
    js_dir,
    package_root,
    precompiled_theme_css,
    scss_path,
    static_dir,
)


def test_assets_resolve():
    assert js_dir().joinpath("shiny-glass.js").is_file()
    assert scss_path().is_file()
    # Vendored static preferred when present
    if has_vendored_static():
        assert asset_source() == "vendored"
        assert static_dir().is_dir()
        assert precompiled_theme_css("light").is_file()
    else:
        assert package_root() is not None


def test_glass_theme_defaults_use_precompiled_when_available():
    theme = glass_theme()
    assert theme.name == "shinyglass-light"
    css = theme.to_css()
    assert isinstance(css, str)
    assert len(css) > 10_000
    if has_vendored_static():
        assert theme._precompiled_css is not None
        assert Path(theme._precompiled_css).is_file()


def test_compiled_or_precompiled_css_has_sidebar_hooks():
    css = glass_theme(preset="light").to_css()
    assert "bslib-sidebar-layout" in css
    assert re.search(r"position:\s*absolute", css)
    assert "main-sidebar" in css


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
    if has_vendored_static():
        assert any(n.startswith("shinyglass-theme-") for n in names)


def test_invalid_preset():
    with pytest.raises(ValueError):
        glass_theme(preset="neon")  # type: ignore[arg-type]


def test_custom_primary_requires_libsass_or_works_with_it():
    libsass = True
    try:
        import sass  # noqa: F401
    except ImportError:
        libsass = False

    if libsass:
        theme = glass_theme(primary="#FF0000")
        assert theme._precompiled_css is None
        css = theme.to_css()
        assert len(css) > 1000
    else:
        with pytest.raises(ImportError, match="libsass"):
            glass_theme(primary="#FF0000")
