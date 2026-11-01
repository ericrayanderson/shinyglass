"""Glass controls: accent wells, preset and scene inputs, theme toggle,
flatten, and their server observers. Mirrors the R helpers of the same names.
"""

from __future__ import annotations

from typing import Any, Mapping

from htmltools import Tag, TagList, tags
from shiny import reactive, ui

from .theme import update_glass_theme
from .tokens import glass_scenes

_MODES = ("light", "dark", "auto")


def _check_id(id: str) -> None:
    if not isinstance(id, str) or not id.strip():
        raise ValueError("id must be a non-empty string")


def _mark_select(tag: Tag, cls: str, attr: str, id: str) -> Tag:
    """Add a class and data attribute to the first <select> inside ``tag``."""

    def walk(node: Any) -> bool:
        if isinstance(node, Tag):
            if node.name == "select":
                node.add_class(cls)
                node.attrs[attr] = id
                return True
            return any(walk(ch) for ch in node.children)
        if isinstance(node, TagList):
            return any(walk(ch) for ch in node)
        return False

    if not walk(tag):
        tag.attrs[attr] = id
        tag.add_class(f"{cls}-wrap")
    return tag


def glass_system_colors() -> dict[str, str]:
    """iOS system accent colors (blue, purple, pink, orange, green, teal)."""
    return {
        "blue": "#007AFF",
        "purple": "#AF52DE",
        "pink": "#FF2D55",
        "orange": "#FF9500",
        "green": "#34C759",
        "teal": "#64D2FF",
    }


def glass_accent_input(
    id: str = "glass_accent",
    label: str | None = "Accent",
    selected: str = "blue",
    colors: Mapping[str, str] | None = None,
) -> Tag:
    """Row of accent color wells.

    The shared JavaScript applies the color right away and reports the hex as
    ``input[id]``. Pair with :func:`observe_glass_accent` to echo it through
    ``update_glass_theme()``.
    """
    _check_id(id)
    colors = dict(colors) if colors is not None else glass_system_colors()
    if not colors:
        raise ValueError(
            'colors must be a non-empty dict of name to hex, for example '
            '{"blue": "#007AFF"}'
        )
    sel = str(selected).strip().lower()
    hexes = {k.lower(): v for k, v in colors.items()}
    hex_ = hexes.get(sel)
    if hex_ is None:
        hex_ = next((v for v in colors.values() if v.lower() == sel), None)
    if hex_ is None:
        hex_ = next(iter(colors.values()))

    wells = []
    for name, col in colors.items():
        on = col.lower() == hex_.lower()
        wells.append(
            tags.button(
                type="button",
                class_="glass-accent-well" + (" is-selected" if on else ""),
                style=f"--glass-well-color:{col};background:{col};",
                role="radio",
                **{
                    "data-glass-primary": col,
                    "data-glass-accent-input": id,
                    "aria-label": name,
                    "aria-checked": "true" if on else "false",
                },
            )
        )
    attrs: dict[str, str] = {"data-glass-accent-input": id}
    if label is None:
        attrs["aria-label"] = "Accent color"
    return tags.div(
        tags.label(label, class_="control-label", id=f"{id}-label")
        if label is not None
        else None,
        tags.div(*wells, class_="glass-accent-wells"),
        class_="form-group shiny-input-container glass-accent-input",
        id=id,
        role="radiogroup",
        **attrs,
    )


def glass_preset_input(
    id: str = "glass_preset",
    label: str | None = "Theme preset",
    selected: str = "auto",
    choices: Mapping[str, str] | None = None,
    width: str | None = None,
) -> Tag:
    """Light / Dark / Auto select. The page changes as soon as it is picked.

    ``choices`` maps values (``"light"``, ``"dark"``, ``"auto"``) to labels,
    following Shiny for Python's ``input_select`` convention.
    """
    _check_id(id)
    choices = dict(choices) if choices is not None else {
        "light": "Light",
        "dark": "Dark",
        "auto": "Auto (OS)",
    }
    if not set(choices) <= set(_MODES):
        raise ValueError('choices keys must be "light", "dark", and/or "auto"')
    if selected not in choices:
        raise ValueError("selected must be one of the keys in choices")
    sel = ui.input_select(id, label, choices=choices, selected=selected, width=width)
    return _mark_select(sel, "glass-preset-input", "data-glass-preset-input", id)


def glass_scene_input(
    id: str = "glass_scene",
    label: str | None = "Wallpaper scene",
    selected: str = "default",
    choices: Mapping[str, str] | None = None,
    width: str | None = None,
) -> Tag:
    """Wallpaper scene select. The scene changes as soon as it is picked."""
    _check_id(id)
    all_scenes = glass_scenes()
    choices = dict(choices) if choices is not None else all_scenes
    bad = set(choices) - set(all_scenes)
    if bad:
        raise ValueError(
            f"choices keys must be scene ids from glass_scenes(): {', '.join(all_scenes)}"
        )
    if selected not in choices:
        raise ValueError("selected must be one of the keys in choices")
    sel = ui.input_select(id, label, choices=choices, selected=selected, width=width)
    return _mark_select(sel, "glass-scene-input", "data-glass-scene-input", id)


def glass_theme_toggle(
    id: str = "glass_toggle",
    selected: str = "auto",
    labels: Mapping[str, str] | None = None,
    class_: str = "glass-theme-toggle",
) -> Tag:
    """Light / Dark / Auto button group.

    Creates three action buttons with ids ``{id}_light``, ``{id}_dark`` and
    ``{id}_auto``. Pair with :func:`observe_glass_theme_toggle`.
    """
    _check_id(id)
    if selected not in _MODES:
        raise ValueError('selected must be "light", "dark", or "auto"')
    labels = dict(labels) if labels is not None else {
        "light": "Light",
        "dark": "Dark",
        "auto": "Auto (OS)",
    }
    if not set(_MODES) <= set(labels):
        raise ValueError('labels must have keys "light", "dark", and "auto"')
    btns = []
    for mode in _MODES:
        active = mode == selected
        btns.append(
            ui.input_action_button(
                f"{id}_{mode}",
                labels[mode],
                class_="btn-sm btn-primary" if active else "btn-sm btn-secondary",
                **{
                    "data-glass-preset-mode": mode,
                    "aria-pressed": "true" if active else "false",
                },
            )
        )
    return tags.div(*btns, class_=class_, role="group", **{"aria-label": "Glass theme preset"})


def glass_flatten(session: Any, on: bool = True) -> None:
    """Turn off blur and translucency for print, PDF and screenshots.

    ``on=False`` restores live glass. Same as
    ``update_glass_theme(session, flatten=on)``.
    """
    if session is None:
        raise ValueError("glass_flatten() needs the server session")
    if not isinstance(on, bool):
        raise ValueError("on must be True (flatten) or False (live glass)")
    update_glass_theme(session, flatten=on)


def observe_glass_accent(input: Any, session: Any, id: str = "glass_accent") -> Any:
    """Echo :func:`glass_accent_input` changes through ``update_glass_theme()``."""
    _check_id(id)

    @reactive.effect
    @reactive.event(input[id], ignore_init=True)
    def _() -> None:
        val = input[id]()
        if isinstance(val, str) and val:
            update_glass_theme(session, primary=val)

    return _


def observe_glass_preset_input(
    input: Any, session: Any, id: str = "glass_preset"
) -> Any:
    """Echo :func:`glass_preset_input` changes through ``update_glass_theme()``."""
    _check_id(id)

    @reactive.effect
    @reactive.event(input[id], ignore_init=True)
    def _() -> None:
        val = input[id]()
        if val in _MODES:
            update_glass_theme(session, preset=val)

    return _


def observe_glass_scene(input: Any, session: Any, id: str = "glass_scene") -> Any:
    """Echo :func:`glass_scene_input` changes through ``update_glass_theme()``."""
    _check_id(id)

    @reactive.effect
    @reactive.event(input[id], ignore_init=True)
    def _() -> None:
        val = input[id]()
        if val in glass_scenes():
            update_glass_theme(session, scene=val)

    return _


def observe_glass_theme_toggle(
    input: Any, session: Any, id: str = "glass_toggle"
) -> None:
    """Wire the :func:`glass_theme_toggle` buttons to ``update_glass_theme()``."""
    _check_id(id)
    for mode in _MODES:

        def make(m: str) -> None:
            @reactive.effect
            @reactive.event(input[f"{id}_{m}"], ignore_init=True)
            def _() -> None:
                update_glass_theme(session, preset=m)

        make(mode)
