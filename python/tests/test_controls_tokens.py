"""Tests for the controls and token helpers ported from R."""

from __future__ import annotations

import pytest

import shinyglass as sg


class FakeSession:
    def __init__(self) -> None:
        self.messages: list[tuple[str, object]] = []

    def send_custom_message(self, kind: str, payload: object) -> None:
        self.messages.append((kind, payload))


def test_system_colors_match_r():
    cols = sg.glass_system_colors()
    assert list(cols) == ["blue", "purple", "pink", "orange", "green", "teal"]
    assert cols["blue"] == "#007AFF"


def test_accent_input_marks_selected_well():
    html = str(sg.glass_accent_input(selected="green"))
    assert 'data-glass-accent-input="glass_accent"' in html
    assert 'class="glass-accent-well is-selected"' in html
    assert html.count("is-selected") == 1
    assert 'data-glass-primary="#34C759"' in html


def test_accent_input_accepts_hex_and_falls_back():
    assert "is-selected" in str(sg.glass_accent_input(selected="#ff9500"))
    html = str(sg.glass_accent_input(selected="nope"))
    assert html.count("is-selected") == 1
    with pytest.raises(ValueError):
        sg.glass_accent_input(colors={})


def test_preset_input_marks_select():
    html = str(sg.glass_preset_input(selected="dark"))
    assert 'data-glass-preset-input="glass_preset"' in html
    assert "glass-preset-input" in html
    with pytest.raises(ValueError):
        sg.glass_preset_input(choices={"sepia": "Sepia"})
    with pytest.raises(ValueError):
        sg.glass_preset_input(selected="dark", choices={"light": "Light"})


def test_scene_input_marks_select_and_validates():
    html = str(sg.glass_scene_input(selected="harbor"))
    assert 'data-glass-scene-input="glass_scene"' in html
    for scene in sg.glass_scenes():
        assert f'value="{scene}"' in html
    with pytest.raises(ValueError):
        sg.glass_scene_input(choices={"moon": "Moon"})


def test_scenes_match_glass_scenes_constant():
    assert tuple(sg.glass_scenes()) == sg.GLASS_SCENES


def test_theme_toggle_buttons():
    html = str(sg.glass_theme_toggle(selected="dark"))
    for mode in ("light", "dark", "auto"):
        assert f'id="glass_toggle_{mode}"' in html
        assert f'data-glass-preset-mode="{mode}"' in html
    assert html.count('aria-pressed="true"') == 1
    with pytest.raises(ValueError):
        sg.glass_theme_toggle(labels={"light": "L"})


def test_glass_flatten_sends_message():
    s = FakeSession()
    sg.glass_flatten(s)
    sg.glass_flatten(s, on=False)
    assert s.messages == [
        ("shinyglass", {"flatten": True}),
        ("shinyglass", {"flatten": False}),
    ]
    with pytest.raises(ValueError):
        sg.glass_flatten(s, on="yes")


def test_css_tokens_catalog():
    cat = sg.glass_css_tokens()
    assert len(cat) >= 40
    assert {"token", "css_var", "category", "description"} <= set(cat[0])
    vars_ = [row["css_var"] for row in cat]
    assert "--glass-blur" in vars_
    assert all(v.startswith("--glass-") for v in vars_)


def test_token_pack_light_dark():
    light = sg.glass_token_pack("light")
    dark = sg.glass_token_pack("dark")
    assert light["--glass-body-color"] == "#1d1d1f"
    assert dark["--glass-body-color"] == "#f5f5f7"
    assert set(light) == set(dark)
    with pytest.raises(ValueError):
        sg.glass_token_pack("auto")


def test_add_tokens_injects_style():
    base = sg.glass_theme()
    th = sg.glass_add_tokens(base, {"blur": "28px"}, glass_radius="1rem", refract_a="red")
    deps = {d.name: d for d in th._html_dependencies()}
    head = str(deps["shinyglass-tokens"].head)
    assert "--glass-blur:28px;" in head
    assert "--glass-radius:1rem;" in head
    assert "--glass-refract-a:red;" in head
    # original theme untouched
    assert "shinyglass-tokens" not in {d.name for d in base._html_dependencies()}


def test_add_tokens_rejects_bad_input():
    th = sg.glass_theme()
    with pytest.raises(ValueError):
        sg.glass_add_tokens(th, {"made_up": "1px"})
    with pytest.raises(ValueError):
        sg.glass_add_tokens(th, {"blur": "</style>"})
    with pytest.raises(TypeError):
        sg.glass_add_tokens("not a theme", blur="1px")
    assert sg.glass_add_tokens(th) is th
