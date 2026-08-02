"""Sanity checks that vendored static is self-contained (no monorepo required)."""

from __future__ import annotations

from pathlib import Path
from unittest import mock

import pytest

from shinyglass._assets import (
    has_vendored_static,
    js_dir,
    precompiled_theme_css,
    static_dir,
)
from shinyglass.theme import glass_theme

pytestmark = pytest.mark.skipif(
    not has_vendored_static(),
    reason="static/ not vendored yet — run scripts/vendor_assets.py",
)


def test_works_without_monorepo_env(monkeypatch):
    monkeypatch.delenv("SHINYGLASS_PKG_ROOT", raising=False)
    with mock.patch("shinyglass._assets.package_root", return_value=None):
        theme = glass_theme(preset="dark")
        css = theme.to_css()
        assert "bslib-sidebar-layout" in css
        assert js_dir().joinpath("shiny-glass.js").is_file()
        assert precompiled_theme_css("dark").is_file()


def test_precompiled_files_exist():
    static = static_dir()
    for name in (
        "theme-light.css",
        "theme-dark.css",
        "glass.scss",
        "shiny-glass.js",
        "glass-rules-light.css",
        "glass-rules-dark.css",
        "MANIFEST.txt",
    ):
        assert (static / name).is_file(), f"{static / name}"
