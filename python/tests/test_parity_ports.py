"""Tests for the functions ported from R for 0.6.0, plus the progress bar and
range slider styling shared with the R package."""

from __future__ import annotations

import pytest

from shinyglass import (
    glass_intensity_slider,
    glass_plot_colors,
    glass_plot_surface_input,
    glass_resolved_preset,
    glass_theme,
    observe_glass,
    observe_glass_intensity,
    observe_glass_plot_surface,
)
from shinyglass._assets import js_dir, precompiled_theme_css, static_dir


# Progress bar and range slider (CSS and JS shared with R) ------------------


@pytest.mark.parametrize("preset", ["light", "dark"])
def test_theme_css_has_glass_progress_and_range(preset):
    css = glass_theme(preset).to_css()
    assert ".progress-bar" in css
    assert ".progress-bar-striped" in css
    assert "form-range::-webkit-slider-thumb" in css
    assert "form-range::-moz-range-progress" in css
    assert "--glass-range-fill" in css


def test_shared_js_keeps_range_fill_in_sync():
    js = js_dir().joinpath("shiny-glass.js").read_text(encoding="utf-8")
    assert "--glass-range-fill" in js
    assert ".form-range" in js


def test_vendored_rules_include_progress_and_range():
    for name in ("glass-rules-light.css", "glass-rules-dark.css"):
        css = static_dir().joinpath(name).read_text(encoding="utf-8")
        assert ".progress-bar" in css
        assert ".form-range" in css
    assert precompiled_theme_css("light").is_file()


# glass_intensity_slider -----------------------------------------------------


def test_intensity_slider_defaults_match_r():
    html = str(glass_intensity_slider())
    assert 'min="0"' in html and 'max="1"' in html and 'step="0.01"' in html
    assert "glass-intensity-preview" in html
    assert "glass-intensity-hint" in html
    assert 'aria-labelledby="glass_intensity-label"' in html
    # No explicit value: the slider follows the page intensity.
    assert "data-glass-initial-intensity" not in html


def test_intensity_slider_options():
    html = str(
        glass_intensity_slider(
            "g", label=None, value=0.3, min=0.2, max=0.8, step=0.1,
            preview=False, width="240px",
        )
    )
    assert 'data-glass-initial-intensity="0.3"' in html
    assert 'min="0.2"' in html and 'max="0.8"' in html and 'step="0.1"' in html
    assert "glass-intensity-preview" not in html
    assert "<label" not in html
    assert 'aria-label="Liquid Glass intensity"' in html
    assert "width:240px;" in html
    assert "width:300px;" in str(glass_intensity_slider(width=300))


@pytest.mark.parametrize(
    "kwargs",
    [
        {"min": 0.5, "max": 0.5},
        {"min": -0.1},
        {"max": 1.5},
        {"step": 0},
        {"value": 0.9, "max": 0.8},
        {"value": 2},
    ],
)
def test_intensity_slider_rejects_bad_range(kwargs):
    with pytest.raises(ValueError):
        glass_intensity_slider(**kwargs)


# glass_plot_surface_input ---------------------------------------------------


def test_plot_surface_input_marks_select():
    html = str(glass_plot_surface_input(selected="opaque"))
    assert 'id="plot_surface"' in html
    assert 'data-glass-plot-surface-input="plot_surface"' in html
    assert "glass-plot-surface-input" in html
    assert "Clear (show wallpaper)" in html
    with pytest.raises(ValueError):
        glass_plot_surface_input(selected="frosted")


# glass_resolved_preset and glass_plot_colors --------------------------------


def test_resolved_preset_order():
    assert glass_resolved_preset() == "light"
    assert glass_resolved_preset(default="dark") == "dark"
    assert glass_resolved_preset({"glass_resolved_preset": "dark"}) == "dark"
    assert glass_resolved_preset({"preset": "auto", "glass_preset": "dark"}) == "dark"
    assert glass_resolved_preset({"preset": "auto"}, default="dark") == "dark"
    # Shiny inputs are callables
    assert glass_resolved_preset({"glass_resolved_preset": lambda: "dark"}) == "dark"
    with pytest.raises(ValueError):
        glass_resolved_preset(default="auto")


def test_plot_colors_match_r():
    light = glass_plot_colors("light")
    assert light == {
        "preset": "light",
        "ink": "#1d1d1f",
        "grid": "rgba(29,29,31,0.10)",
        "fill": "#007AFF",
        "paper": "rgba(0,0,0,0)",
        "surface": "clear",
    }
    assert glass_plot_colors("dark", surface="opaque")["paper"] == "rgba(28,28,30,0.94)"
    assert glass_plot_colors(input={"glass_resolved_preset": "dark"})["ink"] == "#f5f5f7"
    with pytest.raises(ValueError):
        glass_plot_colors("auto")


# glass_theme(tokens=) -------------------------------------------------------


def test_glass_theme_tokens_argument():
    theme = glass_theme(tokens={"blur": "28px"})
    assert theme._glass_tokens == {"--glass-blur": "28px"}


# Observers -------------------------------------------------------------------


class _Session:
    def __init__(self):
        self.sent = []

    def send_custom_message(self, kind, payload):
        self.sent.append((kind, payload))


def test_observers_reject_empty_id():
    with pytest.raises(ValueError):
        observe_glass_intensity({}, _Session(), id="")
    with pytest.raises(ValueError):
        observe_glass_plot_surface({}, _Session(), id="")
    assert callable(observe_glass)
