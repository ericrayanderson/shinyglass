"""Python ``glass_theme()`` — mirrors the R API via shiny.ui.Theme."""

from __future__ import annotations

from typing import Literal

from htmltools import HTMLDependency
from shiny.ui import Theme

from ._assets import js_dir, scss_path
from ._version import __version__

Preset = Literal["light", "dark"]

_FONT_STACK = (
    "-apple-system, BlinkMacSystemFont, "
    '"SF Pro Display", "SF Pro Text", "Segoe UI", '
    "Roboto, Helvetica, Arial, sans-serif"
)

# Bootstrap mixins used by glass.scss (same stubs as R overlay path).
_BOOTSTRAP_STUBS = """
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


def _tokens(preset: Preset) -> dict[str, str]:
    if preset == "light":
        return {
            "body_bg": "#f5f5f7",
            "body_color": "#1d1d1f",
            "glass_bg": "rgba(255, 255, 255, 0.28)",
            "glass_bg_hover": "rgba(255, 255, 255, 0.42)",
            "glass_border": "rgba(255, 255, 255, 0.55)",
            "glass_shadow": "rgba(0, 0, 0, 0.12)",
            "glass_elevated_shadow": "rgba(0, 0, 0, 0.18)",
            "glass_highlight": "rgba(255, 255, 255, 0.75)",
            "glass_specular": "rgba(255, 255, 255, 0.45)",
            "glass_menu_bg": "#ffffff",
            "glass_menu_color": "#1d1d1f",
            "page_bg": (
                "linear-gradient(145deg, #eef0f8 0%, #f5f5f7 35%, "
                "#e8e4f0 70%, #dfe8f5 100%)"
            ),
            "orb_1": "rgba(0, 122, 255, 0.28)",
            "orb_2": "rgba(175, 82, 222, 0.22)",
            "orb_3": "rgba(255, 149, 0, 0.16)",
        }
    return {
        "body_bg": "#000000",
        "body_color": "#f5f5f7",
        "glass_bg": "rgba(255, 255, 255, 0.08)",
        "glass_bg_hover": "rgba(255, 255, 255, 0.14)",
        "glass_border": "rgba(255, 255, 255, 0.22)",
        "glass_shadow": "rgba(0, 0, 0, 0.42)",
        "glass_elevated_shadow": "rgba(0, 0, 0, 0.58)",
        "glass_highlight": "rgba(255, 255, 255, 0.16)",
        "glass_specular": "rgba(255, 255, 255, 0.12)",
        "glass_menu_bg": "#1c1c1e",
        "glass_menu_color": "#f5f5f7",
        "page_bg": (
            "linear-gradient(145deg, #0c0c14 0%, #000000 40%, "
            "#140a1a 75%, #0a1020 100%)"
        ),
        "orb_1": "rgba(10, 132, 255, 0.36)",
        "orb_2": "rgba(191, 90, 242, 0.30)",
        "orb_3": "rgba(255, 159, 10, 0.22)",
    }


class GlassTheme(Theme):
    """``ui.Theme`` subclass that also ships shiny-glass.js + preset marker."""

    def __init__(self, preset: Preset, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._glass_preset = preset

    def _html_dependencies(self) -> list[HTMLDependency]:
        deps = list(super()._html_dependencies())
        js_src = str(js_dir())
        deps.append(
            HTMLDependency(
                name="shinyglass-preset",
                version=__version__,
                head=(
                    f"<script>"
                    f'document.documentElement.dataset.glassPreset="{self._glass_preset}";'
                    f"</script>"
                ),
            )
        )
        deps.append(
            HTMLDependency(
                name="shinyglass",
                version=__version__,
                source={"subdir": js_src},
                script={"src": "shiny-glass.js"},
                all_files=False,
            )
        )
        return deps


def glass_theme(
    preset: Preset = "light",
    primary: str = "#007AFF",
    blur: float | int = 28,
    saturation: float | int = 200,
    radius: str = "1.25rem",
    *,
    base: str | None = None,
) -> GlassTheme:
    """Liquid Glass theme for Shiny for Python.

    Mirrors the R ``shinyglass::glass_theme()`` API. Pass the result to
    ``theme=`` on any ``shiny.ui.page_*`` function (or Express
    ``ui.page_opts(theme=...)``).

    Parameters
    ----------
    preset
        ``"light"`` or ``"dark"``.
    primary
        Accent color for buttons, links, and focus rings.
    blur
        Backdrop blur radius in pixels.
    saturation
        Backdrop saturation percentage.
    radius
        Default border radius for glass surfaces (CSS length).
    base
        Shiny ``Theme`` preset base. Defaults to ``"bootstrap"`` (light) or
        ``"darkly"`` (dark).
    """
    if preset not in ("light", "dark"):
        raise ValueError('preset must be "light" or "dark"')

    tokens = _tokens(preset)
    base_preset = base or ("darkly" if preset == "dark" else "bootstrap")
    scss = scss_path()
    if not scss.is_file():
        raise FileNotFoundError(scss)

    glass_rules = scss.read_text(encoding="utf-8")

    theme = GlassTheme(
        preset,
        base_preset,
        name=f"shinyglass-{preset}",
        include_paths=[str(scss.parent)],
    )

    # Bootstrap / Shiny Sass variables (underscore form → kebab-case).
    theme = theme.add_defaults(
        primary=primary,
        success="#34C759",
        danger="#FF3B30",
        warning="#FF9500",
        info="#5AC8FA",
        body_bg=tokens["body_bg"],
        body_color=tokens["body_color"],
        font_family_sans_serif=_FONT_STACK,
        border_radius="1rem",
        border_radius_lg=radius,
        border_radius_sm="0.75rem",
        card_border_width="1px",
        card_border_color=tokens["glass_border"],
        input_border_color=tokens["glass_border"],
        navbar_padding_y="0.75rem",
        btn_font_weight=600,
        btn_font_size="0.9375rem",
        btn_line_height=1.2,
        btn_padding_y=".55rem",
        btn_padding_x="1.2rem",
        btn_border_width="1px",
        # Glass design tokens
        glass_bg=tokens["glass_bg"],
        glass_bg_hover=tokens["glass_bg_hover"],
        glass_border=tokens["glass_border"],
        glass_shadow=tokens["glass_shadow"],
        glass_elevated_shadow=tokens["glass_elevated_shadow"],
        glass_blur=f"{blur}px",
        glass_saturate=f"{saturation}%",
        glass_radius=radius,
        glass_highlight=tokens["glass_highlight"],
        glass_specular=tokens["glass_specular"],
        glass_menu_bg=tokens["glass_menu_bg"],
        glass_menu_color=tokens["glass_menu_color"],
        glass_page_bg=tokens["page_bg"],
        glass_orb_1=tokens["orb_1"],
        glass_orb_2=tokens["orb_2"],
        glass_orb_3=tokens["orb_3"],
    )

    # Stubs first, then full glass.scss (same rules as R bs_add_rules).
    theme = theme.add_rules(_BOOTSTRAP_STUBS, glass_rules)
    return theme
