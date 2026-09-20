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


def test_plot_surface_marked_in_head():
    theme = glass_theme(plot_surface="opaque")
    preset = next(d for d in theme._html_dependencies() if d.name == "shinyglass-preset")
    markup = str(preset.head or "")
    assert "plotSurface='opaque'" in markup
    assert "glassPlotSurface=plotSurface" in markup
    with pytest.raises(ValueError, match="plot_surface"):
        glass_theme(plot_surface="frosted")


def test_intensity_scene_flatten_in_head():
    theme = glass_theme(
        intensity=0.2,
        scene="aurora",
        flatten=True,
        persist=True,
        plot_surface="opaque",
    )
    preset = next(d for d in theme._html_dependencies() if d.name == "shinyglass-preset")
    markup = str(preset.head or "")
    assert "intensity=0.2000" in markup
    assert "scene='aurora'" in markup
    assert "flatten=true" in markup
    assert "persist=true" in markup
    assert "glass_flatten" in markup
    with pytest.raises(ValueError, match="scene"):
        glass_theme(scene="neon")
    with pytest.raises(ValueError, match="intensity"):
        glass_theme(intensity=1.5)


def test_vendored_scss_has_ios27_nudge_and_plot_panel():
    scss = scss_path().read_text(encoding="utf-8")
    assert "--glass-border: rgba(255, 255, 255, 0.78)" in scss
    assert "--glass-border: rgba(255, 255, 255, 0.44)" in scss
    assert "--glass-specular: rgba(255, 255, 255, 0.64)" in scss
    assert "data-glass-plot-surface" in scss
    assert "glass-plot-surface-opaque" in scss
    assert "data-glass-scene=\"aurora\"" in scss
    assert "data-glass-flatten" in scss
    assert "max-width: 480px" in scss
    js = js_dir().joinpath("shiny-glass.js").read_text(encoding="utf-8")
    assert "setPlotSurface" in js
    assert "setFlatten" in js
    assert "setScene" in js
    assert "borderA: 0.36" in js


def test_update_glass_theme_payload():
    from shinyglass import update_glass_theme

    sent: list[tuple[str, object]] = []

    class _Session:
        def send_custom_message(self, type: str, message: object) -> None:
            sent.append((type, message))

    update_glass_theme(
        _Session(),
        intensity=0.8,
        plot_surface="opaque",
        scene="harbor",
        flatten=True,
    )
    assert sent[0][0] == "shinyglass"
    assert sent[0][1]["intensity"] == 0.8
    assert sent[0][1]["plot_surface"] == "opaque"
    assert sent[0][1]["scene"] == "harbor"
    assert sent[0][1]["flatten"] is True


def test_auto_preset_uses_light_pack_and_marks_mode():
    theme = glass_theme(preset="auto")
    assert theme._glass_preset == "auto"
    head = theme._html_dependencies()
    preset = next(d for d in head if d.name == "shinyglass-preset")
    markup = str(preset.head or "")
    assert "var p=" in markup
    assert "auto" in markup


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
