"""Liquid Glass CSS tokens and scenes. Mirrors R ``R/glass-tokens.R``."""

from __future__ import annotations

import copy
import re
from typing import Any, Literal, Mapping

from .theme import GlassTheme, _tokens

_TOKEN_ROWS: tuple[tuple[str, str, str, str], ...] = (
    ('blur', '--glass-blur', 'material', 'Backdrop blur radius (CSS length).'),
    ('saturate', '--glass-saturate', 'material', 'Backdrop saturation.'),
    ('radius', '--glass-radius', 'material', 'Corner radius for glass surfaces.'),
    ('intensity', '--glass-intensity', 'material', 'Ultra Clear (0) to Tinted (1). Default 0.5.'),
    ('refract-a', '--glass-refract-a', 'material', 'Coloured leading-edge refraction cue. Alpha scales with intensity.'),
    ('refract-b', '--glass-refract-b', 'material', 'Coloured trailing-edge refraction cue. Alpha scales with intensity.'),
    ('refract-brightness', '--glass-refract-brightness', 'material', 'Backdrop brightness boost. Scales with intensity.'),
    ('refract-contrast', '--glass-refract-contrast', 'material', 'Backdrop contrast boost. Scales with intensity.'),
    ('bg', '--glass-bg', 'surface', 'Primary glass fill.'),
    ('bg-hover', '--glass-bg-hover', 'surface', 'Hover / active glass fill.'),
    ('bg-content', '--glass-bg-content', 'surface', 'Content-card fill (less chrome).'),
    ('border', '--glass-border', 'surface', 'Rim / hairline border.'),
    ('border-outer', '--glass-border-outer', 'surface', 'Outer lip / side stroke.'),
    ('shadow', '--glass-shadow', 'surface', 'Drop shadow color.'),
    ('elevated-shadow', '--glass-elevated-shadow', 'surface', 'Floating chrome shadow.'),
    ('highlight', '--glass-highlight', 'surface', 'Top-edge highlight.'),
    ('specular', '--glass-specular', 'surface', 'Specular sheen.'),
    ('lip', '--glass-lip', 'surface', 'Bottom-edge lip.'),
    ('stroke-side', '--glass-stroke-side', 'surface', 'Side-edge stroke.'),
    ('body-bg', '--glass-body-bg', 'ink', 'Page / panel paper color.'),
    ('body-color', '--glass-body-color', 'ink', 'Primary body ink.'),
    ('menu-bg', '--glass-menu-bg', 'ink', 'Opaque overlay / menu fill.'),
    ('menu-color', '--glass-menu-color', 'ink', 'Overlay / menu ink.'),
    ('page-bg', '--glass-page-bg', 'scene', 'Wallpaper gradient.'),
    ('orb-1', '--glass-orb-1', 'scene', 'Ambient orb 1.'),
    ('orb-2', '--glass-orb-2', 'scene', 'Ambient orb 2.'),
    ('orb-3', '--glass-orb-3', 'scene', 'Ambient orb 3.'),
    ('wallpaper', '--glass-wallpaper', 'scene', 'Optional photo url(...).'),
    ('wallpaper-wash', '--glass-wallpaper-wash', 'scene', 'Dim overlay on user photos.'),
    ('plot-panel', '--glass-plot-panel', 'content', 'Opaque plot/table panel fill.'),
    ('primary', '--glass-primary', 'accent', 'Accent / brand color.'),
    ('accent', '--glass-accent', 'accent', 'Alias of --glass-primary.'),
    ('on-primary', '--glass-on-primary', 'accent', 'Ink on solid accent fills.'),
    ('ior', '--glass-ior', 'material', 'Index of refraction for the squircle lens. Default 1.5.'),
    ('refraction-scale', '--glass-refraction-scale', 'material', 'Peak backdrop displacement in CSS pixels.'),
    ('dispersion', '--glass-dispersion', 'material', 'Rim chromatic spread. Dropped on low-tier devices.'),
    ('diffusion', '--glass-diffusion', 'material', 'Extra uniform blur multiplier for busy content.'),
    ('specular-top', '--glass-specular-top', 'surface', 'Static top specular highlight.'),
    ('specular-bottom', '--glass-specular-bottom', 'surface', 'Static bottom specular highlight.'),
    ('edge', '--glass-edge', 'surface', 'Darkened outer edge ring.'),
    ('press-scale', '--glass-press-scale', 'motion', 'Pressed control scale.'),
    ('scroll-edge-fade', '--glass-scroll-edge-fade', 'motion', 'Toolbar edge fade length.'),
    ('minimize-scale', '--glass-minimize-scale', 'motion', 'Shrunk tab bar scale.'),
    ('icon-clear', '--glass-icon-clear', 'ink', 'Monochrome clear-glass icon ink.'),
)

_SCENES: dict[str, str] = {
    "default": "Default orbs",
    "tahoe": "Lake Tahoe mist",
    "dusk": "Warm dusk",
    "mesh": "Soft RGB mesh",
    "aurora": "Aurora veil",
    "harbor": "Harbor morning",
    "grove": "Orchard grove",
}


def glass_scenes() -> dict[str, str]:
    """Named wallpaper scenes for ``glass_theme(scene=)``.

    Returns a dict of scene id to label, in the same order as R.
    """
    return dict(_SCENES)


def glass_css_tokens() -> list[dict[str, str]]:
    """Catalog of public ``--glass-*`` CSS custom properties.

    Each entry has ``token``, ``css_var``, ``category`` and ``description``
    keys (the same columns as the R data frame). Override any of them with
    :func:`glass_add_tokens` or ``update_glass_theme(tokens=...)``.
    """
    return [
        {"token": t, "css_var": v, "category": c, "description": d}
        for t, v, c, d in _TOKEN_ROWS
    ]


def glass_token_pack(preset: Literal["light", "dark"] = "light") -> dict[str, str]:
    """Default CSS variable values for a preset (names include ``--``)."""
    if preset not in ("light", "dark"):
        raise ValueError('preset must be "light" or "dark"')
    tok = _tokens(preset)
    dark = preset == "dark"
    return {
        "--glass-bg": tok["glass_bg"],
        "--glass-bg-hover": tok["glass_bg_hover"],
        "--glass-border": tok["glass_border"],
        "--glass-shadow": tok["glass_shadow"],
        "--glass-elevated-shadow": tok["glass_elevated_shadow"],
        "--glass-highlight": tok["glass_highlight"],
        "--glass-specular": tok["glass_specular"],
        "--glass-menu-bg": tok["glass_menu_bg"],
        "--glass-menu-color": tok["glass_menu_color"],
        "--glass-page-bg": tok["page_bg"],
        "--glass-orb-1": tok["orb_1"],
        "--glass-orb-2": tok["orb_2"],
        "--glass-orb-3": tok["orb_3"],
        "--glass-body-bg": tok["body_bg"],
        "--glass-body-color": tok["body_color"],
        "--glass-blur": "calc(var(--glass-blur-base, 36px) * 1.11)",
        "--glass-saturate": "200%",
        "--glass-radius": "1.5rem",
        "--glass-intensity": "0.5",
        "--glass-refract-a": (
            "rgba(100, 200, 255, 0.15)" if dark else "rgba(120, 200, 255, 0.19)"
        ),
        "--glass-refract-b": (
            "rgba(220, 140, 255, 0.11)" if dark else "rgba(255, 140, 200, 0.12)"
        ),
        "--glass-refract-brightness": "1.04",
        "--glass-refract-contrast": "1.04",
        "--glass-ior": "1.5",
        "--glass-refraction-scale": "42",
        "--glass-dispersion": "0.06",
        "--glass-diffusion": "1.06",
        "--glass-specular-top": (
            "rgba(255, 255, 255, 0.20)" if dark else "rgba(255, 255, 255, 1)"
        ),
        "--glass-specular-bottom": (
            "rgba(255, 255, 255, 0.16)" if dark else "rgba(255, 255, 255, 0.78)"
        ),
        "--glass-sheen-end": "8px" if dark else "26%",
        "--glass-fill-sheen-end": "12px" if dark else "30%",
        "--glass-edge-span": "10px" if dark else "34%",
        "--glass-edge": "rgba(0, 0, 0, 0.88)" if dark else "rgba(0, 0, 0, 0.38)",
        "--glass-press-scale": "0.965",
        "--glass-scroll-edge-fade": "28px",
        "--glass-minimize-scale": "0.92",
        "--glass-icon-clear": "rgba(255, 255, 255, 0.92)" if dark else "#1d1d1f",
        "--glass-wallpaper-wash": (
            "rgba(0, 0, 0, 0.55)" if dark else "rgba(245, 245, 247, 0.48)"
        ),
        "--glass-plot-panel": (
            "rgba(28, 28, 30, 0.94)" if dark else "rgba(245, 245, 247, 0.94)"
        ),
    }


def _resolve_token_name(name: str) -> str:
    name = str(name).strip()
    if not name:
        raise ValueError(
            'Token names must be non-empty. Use a name from glass_css_tokens(), '
            'such as "blur" or "--glass-blur".'
        )
    if name.startswith("--"):
        return name
    if name.replace("_", "-").startswith("glass-"):
        return "--" + name.replace("_", "-")
    by_token = {t: v for t, v, _, _ in _TOKEN_ROWS}
    if name in by_token:
        return by_token[name]
    guessed = "--glass-" + name.replace("_", "-")
    if guessed in {v for _, v, _, _ in _TOKEN_ROWS}:
        return guessed
    raise ValueError(
        f"Unknown glass token {name!r}. Use a name from the token column of "
        'glass_css_tokens(), such as "blur".'
    )


def _normalize_tokens(tokens: Mapping[str, Any] | None) -> dict[str, str]:
    out: dict[str, str] = {}
    for nm, val in (tokens or {}).items():
        key = _resolve_token_name(nm)
        if val is None or (isinstance(val, str) and not val):
            continue
        val = str(val)
        if re.search(r"[<>]", val):
            raise ValueError(
                "Token values must not contain < or >. Pass a CSS length or "
                'color, for example {"blur": "28px"}.'
            )
        out[key] = val
    return out


def _tokens_to_css(tokens: Mapping[str, str]) -> str:
    if not tokens:
        return ""
    return ":root{" + "".join(f"{k}:{v};" for k, v in tokens.items()) + "}"


def glass_add_tokens(
    theme: GlassTheme,
    tokens: Mapping[str, Any] | None = None,
    **kwargs: Any,
) -> GlassTheme:
    """Override glass CSS tokens on a theme without forking the SCSS.

    Accepts names from the ``token`` column of :func:`glass_css_tokens`
    (``"blur"``), CSS names (``"--glass-blur"``) or ``"glass-blur"``. Keyword
    arguments use underscores, so ``refract_a="..."`` maps to
    ``--glass-refract-a``. Returns a new theme; the original is unchanged.
    """
    if not isinstance(theme, GlassTheme):
        raise TypeError(
            "glass_add_tokens() needs a theme from shinyglass.glass_theme()."
        )
    merged: dict[str, Any] = dict(tokens or {})
    merged.update(kwargs)
    new = _normalize_tokens(merged)
    if not new:
        return theme
    out = copy.copy(theme)
    out._glass_tokens = {**getattr(theme, "_glass_tokens", {}), **new}
    return out
