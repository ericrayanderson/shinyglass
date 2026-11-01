"""0.6.0 motion, style, and font options (mirrors the R tests)."""

from __future__ import annotations

from pathlib import Path

import pytest

from shinyglass import glass_theme, update_glass_theme


def _head(theme) -> str:
    for d in theme._html_dependencies():
        if d.name == "shinyglass-preset":
            return str(d.head)
    raise AssertionError("no preset dependency")


def _names(theme) -> list[str]:
    return [d.name for d in theme._html_dependencies()]


def test_pointer_and_pill_flags():
    h = _head(glass_theme())
    assert "glassPointerSpecular='true'" in h
    assert "glassNavPill='true'" in h
    h = _head(glass_theme(pointer_specular=False, nav_pill=False))
    assert "glassPointerSpecular='false'" in h
    assert "glassNavPill='false'" in h


def test_motion_off_turns_all_motion_off():
    h = _head(glass_theme(motion=False))
    for flag in ("Motion", "AmbientMotion", "Morph", "Press", "NavMorph",
                 "MinimizeTabs", "PointerSpecular", "NavPill"):
        assert f"glass{flag}='false'" in h
    assert "glassScrollEdge='true'" in h


def test_style_sets_intensity():
    assert "var intensity=1.0000;" in _head(glass_theme(style="tinted"))
    assert "var intensity=0.1200;" in _head(glass_theme(style="clear"))
    assert "var intensity=0.5000;" in _head(glass_theme())
    assert "var intensity=0.7000;" in _head(glass_theme(style="tinted", intensity=0.7))
    assert "glassStyle='tinted'" in _head(glass_theme(style="tinted"))
    with pytest.raises(ValueError):
        glass_theme(style="frosted")


def test_update_glass_theme_new_options():
    sent = []

    class S:
        def send_custom_message(self, t, m):
            sent.append((t, m))

    update_glass_theme(S(), pointer_specular=False, nav_pill=True, style="tinted", motion=False)
    m = sent[0][1]
    assert m["pointer_specular"] is False and m["nav_pill"] is True
    assert m["style"] == "tinted" and m["intensity"] == 1.0 and m["motion"] is False


def test_bundled_inter_font():
    theme = glass_theme()
    assert "shinyglass-inter" in _names(theme)
    assert "shinyglass-inter" not in _names(glass_theme(font="system"))
    dep = next(d for d in theme._html_dependencies() if d.name == "shinyglass-inter")
    folder = Path(dep.source["subdir"])
    assert (folder / "InterVariable-latin.woff2").is_file()
    assert (folder / "OFL.txt").is_file()
    css = (folder / "shinyglass-inter.css").read_text()
    assert 'url("InterVariable-latin.woff2")' in css
    assert "http" not in css
    assert "glassFont='matched'" in _head(theme)
    with pytest.raises(ValueError):
        glass_theme(font="inter")
