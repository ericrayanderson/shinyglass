"""Python ``glass_theme()`` — mirrors the R API via shiny.ui.Theme."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Literal, Mapping

from htmltools import HTMLDependency, Tag, tags
from shiny.ui import Theme

from ._assets import (
    has_vendored_static,
    js_dir,
    precompiled_theme_css,
    scss_path,
)
from ._version import __version__

Preset = Literal["light", "dark", "auto"]
PlotSurface = Literal["clear", "opaque"]
Material = Literal["regular", "clear"]
Scene = Literal["default", "tahoe", "dusk", "mesh", "aurora", "harbor", "grove"]

_DEFAULT_PRIMARY = "#007AFF"
_DEFAULT_BLUR = 36
_DEFAULT_SATURATION = 200
_DEFAULT_RADIUS = "1.5rem"
_DEFAULT_INTENSITY = 0.45

GLASS_SCENES: tuple[str, ...] = (
    "default",
    "tahoe",
    "dusk",
    "mesh",
    "aurora",
    "harbor",
    "grove",
)

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
    # Match R .glass_tokens() so compiled CSS stays in the same dialect.
    if preset == "light":
        return {
            "body_bg": "#f2f2f7",
            "body_color": "#1d1d1f",
            "glass_bg": "rgba(255, 255, 255, 0.22)",
            "glass_bg_hover": "rgba(255, 255, 255, 0.36)",
            "glass_border": "rgba(255, 255, 255, 0.62)",
            "glass_shadow": "rgba(0, 0, 0, 0.10)",
            "glass_elevated_shadow": "rgba(0, 0, 0, 0.16)",
            "glass_highlight": "rgba(255, 255, 255, 0.88)",
            "glass_specular": "rgba(255, 255, 255, 0.55)",
            "glass_menu_bg": "rgba(255, 255, 255, 0.86)",
            "glass_menu_color": "#1d1d1f",
            "page_bg": (
                "linear-gradient(160deg, #eef1f8 0%, #f5f5f7 42%, "
                "#ebe8f4 78%, #e6eef8 100%)"
            ),
            "orb_1": "rgba(0, 122, 255, 0.18)",
            "orb_2": "rgba(175, 82, 222, 0.12)",
            "orb_3": "rgba(90, 200, 250, 0.14)",
        }
    return {
        "body_bg": "#000000",
        "body_color": "#f5f5f7",
        "glass_bg": "rgba(255, 255, 255, 0.14)",
        "glass_bg_hover": "rgba(255, 255, 255, 0.22)",
        "glass_border": "rgba(255, 255, 255, 0.26)",
        "glass_shadow": "rgba(0, 0, 0, 0.48)",
        "glass_elevated_shadow": "rgba(0, 0, 0, 0.62)",
        "glass_highlight": "rgba(255, 255, 255, 0.22)",
        "glass_specular": "rgba(255, 255, 255, 0.18)",
        "glass_menu_bg": "rgba(44, 44, 46, 0.88)",
        "glass_menu_color": "#f5f5f7",
        "page_bg": (
            "linear-gradient(160deg, #0a0a12 0%, #000000 45%, "
            "#100a16 80%, #060a14 100%)"
        ),
        "orb_1": "rgba(10, 132, 255, 0.28)",
        "orb_2": "rgba(191, 90, 242, 0.20)",
        "orb_3": "rgba(100, 210, 255, 0.16)",
    }


def _is_default_knobs(
    primary: str,
    blur: float | int,
    saturation: float | int,
    radius: str,
) -> bool:
    return (
        primary == _DEFAULT_PRIMARY
        and float(blur) == float(_DEFAULT_BLUR)
        and float(saturation) == float(_DEFAULT_SATURATION)
        and radius == _DEFAULT_RADIUS
    )


def _libsass_available() -> bool:
    try:
        import sass  # noqa: F401

        return True
    except ImportError:
        return False


def _js_bool(v: bool) -> str:
    return "true" if v else "false"


def _preset_head(
    *,
    preset: str,
    intensity: float,
    plot_surface: str,
    material: str,
    scene: str,
    flatten: bool,
    persist: bool,
    tint: bool,
    specular: bool,
    nav_morph: bool,
    ambient_motion: bool,
    primary: str,
    wallpaper: str | None,
) -> str:
    wall = "null" if not wallpaper else repr(wallpaper)
    scenes = ",".join(f"{s}:1" for s in GLASS_SCENES)
    return (
        "<script>(function(){"
        f"var p={preset!r};"
        f"var intensity={float(intensity):.4f};"
        f"var prim={primary!r};"
        f"var material={material!r};"
        f"var plotSurface={plot_surface!r};"
        f"var scene={scene!r};"
        f"var persist={_js_bool(persist)};"
        f"var wallpaper={wall};"
        f"var flatten={_js_bool(flatten)};"
        f"var scenes={{{scenes}}};"
        "var root=document.documentElement;"
        "if(persist){try{"
        "var key='shinyglass:'+((location.pathname||'/').replace(/\\/$/, '')||'/');"
        "var raw=localStorage.getItem(key);"
        "if(raw){var st=JSON.parse(raw);"
        "if(st.preset==='light'||st.preset==='dark'||st.preset==='auto')p=st.preset;"
        "if(typeof st.intensity==='number')intensity=st.intensity;"
        "if(typeof st.primary==='string'&&st.primary)prim=st.primary;"
        "if(st.material==='clear'||st.material==='regular')material=st.material;"
        "if(st.plotSurface==='clear'||st.plotSurface==='opaque')plotSurface=st.plotSurface;"
        "if(st.scene&&scenes[st.scene])scene=st.scene;"
        "root.dataset.glassPersistRestored='true';}"
        "}catch(e){}}"
        "try{var q=new URLSearchParams(location.search||'');"
        "var qf=q.get('glass_flatten');"
        "if(qf==='1'||qf==='true'||qf==='on')flatten=true;}catch(e){}"
        "root.dataset.glassPersist=persist?'true':'false';"
        "root.dataset.glassMode=p;"
        "function resolve(mode){"
        "if(mode==='auto'){try{"
        "return window.matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';"
        "}catch(e){return 'light';}}"
        "return mode==='dark'?'dark':'light';}"
        "root.dataset.glassPreset=resolve(p);"
        "root.dataset.glassMaterial=material;"
        "root.dataset.glassPlotSurface=plotSurface;"
        "root.dataset.glassScene=scene;"
        "root.dataset.glassFlatten=flatten?'true':'false';"
        "root.dataset.glassIntensity=String(intensity);"
        "root.style.setProperty('--glass-intensity',String(intensity));"
        f"root.dataset.glassTint='{_js_bool(tint)}';"
        f"root.dataset.glassSpecular='{_js_bool(specular)}';"
        f"root.dataset.glassNavMorph='{_js_bool(nav_morph)}';"
        f"root.dataset.glassAmbientMotion='{_js_bool(ambient_motion)}';"
        "if(prim){root.dataset.glassPrimary=prim;"
        "root.style.setProperty('--bs-primary',prim);"
        "root.style.setProperty('--glass-primary',prim);"
        "root.style.setProperty('--glass-accent',prim);}"
        "if(wallpaper){root.dataset.glassWallpaper='true';"
        "root.style.setProperty('--glass-wallpaper','url(\"'+wallpaper+'\")');}"
        "})();</script>"
    )


class GlassTheme(Theme):
    """``ui.Theme`` subclass that also ships shiny-glass.js + preset marker.

    When ``precompiled_css`` is set, Bootstrap+glass CSS is loaded from that
    file (no runtime libsass). Otherwise Sass is compiled like the R package.
    """

    def __init__(
        self,
        preset: Preset,
        *args,
        precompiled_css: Path | None = None,
        plot_surface: str = "clear",
        intensity: float = _DEFAULT_INTENSITY,
        material: str = "regular",
        scene: str = "default",
        flatten: bool = False,
        persist: bool = False,
        tint: bool = True,
        specular: bool = True,
        nav_morph: bool = True,
        ambient_motion: bool = True,
        primary: str = _DEFAULT_PRIMARY,
        wallpaper: str | None = None,
        **kwargs,
    ):
        super().__init__(*args, **kwargs)
        self._glass_preset = preset
        self._precompiled_css = precompiled_css
        self._plot_surface = "opaque" if plot_surface == "opaque" else "clear"
        self._intensity = float(intensity)
        self._material = "clear" if material == "clear" else "regular"
        self._scene = scene if scene in GLASS_SCENES else "default"
        self._flatten = bool(flatten)
        self._persist = bool(persist)
        self._tint = bool(tint)
        self._specular = bool(specular)
        self._nav_morph = bool(nav_morph)
        self._ambient_motion = bool(ambient_motion)
        self._primary = primary
        self._wallpaper = wallpaper

    def _html_dependencies(self) -> list[HTMLDependency]:
        if self._precompiled_css is not None:
            css_path = Path(self._precompiled_css)
            deps: list[HTMLDependency] = [
                HTMLDependency(
                    name=f"shinyglass-theme-{self._glass_preset}",
                    version=__version__,
                    source={"subdir": str(css_path.parent)},
                    stylesheet={"href": css_path.name},
                    all_files=False,
                )
            ]
        else:
            deps = list(super()._html_dependencies())

        js_src = str(js_dir())
        deps.append(
            HTMLDependency(
                name="shinyglass-preset",
                version=__version__,
                head=_preset_head(
                    preset=self._glass_preset,
                    intensity=self._intensity,
                    plot_surface=self._plot_surface,
                    material=self._material,
                    scene=self._scene,
                    flatten=self._flatten,
                    persist=self._persist,
                    tint=self._tint,
                    specular=self._specular,
                    nav_morph=self._nav_morph,
                    ambient_motion=self._ambient_motion,
                    primary=self._primary,
                    wallpaper=self._wallpaper,
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

    def to_css(self, compile_args=None) -> str:
        if self._precompiled_css is not None:
            return Path(self._precompiled_css).read_text(encoding="utf-8")
        return super().to_css(compile_args=compile_args)


def glass_theme(
    preset: Preset = "light",
    primary: str = _DEFAULT_PRIMARY,
    blur: float | int = _DEFAULT_BLUR,
    saturation: float | int = _DEFAULT_SATURATION,
    radius: str = _DEFAULT_RADIUS,
    intensity: float = _DEFAULT_INTENSITY,
    plot_surface: str = "clear",
    material: str = "regular",
    scene: str = "default",
    wallpaper: str | None = None,
    flatten: bool = False,
    persist: bool = False,
    tint: bool = True,
    specular: bool = True,
    nav_morph: bool = True,
    ambient_motion: bool = True,
    *,
    base: str | None = None,
    _allow_compile: bool = False,
) -> GlassTheme:
    """Liquid Glass theme for Shiny for Python.

    Mirrors the R ``shinyglass::glass_theme()`` API. Pass the result to
    ``theme=`` on any ``shiny.ui.page_*`` function (or Express
    ``ui.page_opts(theme=...)``).

    Intensity, ``plot_surface``, scene, flatten, persist, and JS knobs are
    applied in the early head script and shared ``shiny-glass.js`` — they do
    **not** require libsass. Custom ``primary`` / ``blur`` / ``radius`` still
    need the optional ``shinyglass[theme]`` extra (or a monorepo checkout).

    Parameters
    ----------
    preset
        ``"light"``, ``"dark"``, or ``"auto"``.
    primary
        Accent color for buttons, links, and focus rings.
    blur
        Backdrop blur radius in pixels.
    saturation
        Backdrop saturation percentage.
    radius
        Default border radius for glass surfaces (CSS length).
    intensity
        Ultra Clear (``0``) to Tinted (``1``). Default ``0.45``.
    plot_surface
        ``"clear"`` (default, wallpaper show-through) or ``"opaque"``
        (denser plot / table panels).
    material
        ``"regular"`` or ``"clear"``.
    scene
        Named wallpaper pack: ``default``, ``tahoe``, ``dusk``, ``mesh``,
        ``aurora``, ``harbor``, ``grove``.
    wallpaper
        Optional https / data-URI / site-relative photo. Blurred and washed.
    flatten
        Start in print / screenshot flatten mode (no backdrop blur).
    persist
        Remember preset, intensity, accent, material, plot surface, and scene.
    tint, specular, nav_morph, ambient_motion
        JS behavior knobs (same defaults as R).
    base
        Shiny ``Theme`` preset base. Defaults to ``"bootstrap"`` (light) or
        ``"darkly"`` (dark). Ignored when loading precompiled CSS.
    """
    if preset not in ("light", "dark", "auto"):
        raise ValueError('preset must be "light", "dark", or "auto"')
    if plot_surface not in ("clear", "opaque"):
        raise ValueError('plot_surface must be "clear" or "opaque"')
    if material not in ("regular", "clear"):
        raise ValueError('material must be "regular" or "clear"')
    if scene not in GLASS_SCENES:
        raise ValueError(f"scene must be one of {GLASS_SCENES}")
    if not 0.0 <= float(intensity) <= 1.0:
        raise ValueError("intensity must be between 0 and 1")

    # JS-only knobs (intensity, scene, flatten, persist, plot_surface) keep
    # the precompiled CSS path — they do not need a Sass recompile.
    use_precompiled = (
        not _allow_compile
        and _is_default_knobs(primary, blur, saturation, radius)
        and has_vendored_static()
        and base is None
    )

    theme_kwargs = dict(
        plot_surface=plot_surface,
        intensity=float(intensity),
        material=material,
        scene=scene,
        flatten=flatten,
        persist=persist,
        tint=tint,
        specular=specular,
        nav_morph=nav_morph,
        ambient_motion=ambient_motion,
        primary=primary,
        wallpaper=wallpaper,
    )

    if use_precompiled:
        css_preset = "light" if preset == "auto" else preset
        css_path = precompiled_theme_css(css_preset)
        return GlassTheme(
            preset,
            "bootstrap",
            name=f"shinyglass-{preset}",
            precompiled_css=css_path,
            **theme_kwargs,
        )

    if not _libsass_available():
        raise ImportError(
            "Custom shinyglass themes (or missing precompiled CSS) require "
            'libsass. Install with: pip install "shinyglass[theme]" '
            "or pip install libsass"
        )

    tokens = _tokens("dark" if preset == "dark" else "light")
    base_preset = base or ("darkly" if preset == "dark" else "bootstrap")
    scss = scss_path()
    glass_rules = scss.read_text(encoding="utf-8")

    theme = GlassTheme(
        preset,
        base_preset,
        name=f"shinyglass-{preset}",
        include_paths=[str(scss.parent)],
        precompiled_css=None,
        **theme_kwargs,
    )

    theme = theme.add_defaults(
        primary=primary,
        success="#34C759",
        danger="#FF3B30",
        warning="#FF9500",
        info="#5AC8FA",
        body_bg=tokens["body_bg"],
        body_color=tokens["body_color"],
        font_family_sans_serif=_FONT_STACK,
        border_radius="1.1rem",
        border_radius_lg=radius,
        border_radius_sm="0.85rem",
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
        min_contrast_ratio=3,
        component_active_color="#ffffff",
        form_check_input_checked_color="#ffffff",
        form_check_input_indeterminate_color="#ffffff",
        form_switch_checked_color="#ffffff",
        pagination_active_color="#ffffff",
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

    theme = theme.add_rules(_BOOTSTRAP_STUBS, glass_rules)
    return theme


def update_glass_theme(
    session: Any,
    *,
    preset: str | None = None,
    intensity: float | None = None,
    plot_surface: str | None = None,
    scene: str | None = None,
    flatten: bool | None = None,
    primary: str | None = None,
    material: str | None = None,
    ambient_motion: bool | None = None,
    tint: bool | None = None,
    tokens: Mapping[str, str] | None = None,
) -> None:
    """Send a ``shinyglass`` custom message (same payload as R)."""
    payload: dict[str, Any] = {}
    if preset is not None:
        if preset not in ("light", "dark", "auto"):
            raise ValueError('preset must be "light", "dark", or "auto"')
        payload["preset"] = preset
    if intensity is not None:
        if not 0.0 <= float(intensity) <= 1.0:
            raise ValueError("intensity must be between 0 and 1")
        payload["intensity"] = float(intensity)
    if plot_surface is not None:
        if plot_surface not in ("clear", "opaque"):
            raise ValueError('plot_surface must be "clear" or "opaque"')
        payload["plot_surface"] = plot_surface
    if scene is not None:
        if scene not in GLASS_SCENES:
            raise ValueError(f"scene must be one of {GLASS_SCENES}")
        payload["scene"] = scene
    if flatten is not None:
        payload["flatten"] = bool(flatten)
    if primary is not None:
        payload["primary"] = primary
    if material is not None:
        if material not in ("regular", "clear"):
            raise ValueError('material must be "regular" or "clear"')
        payload["material"] = material
    if ambient_motion is not None:
        payload["ambient_motion"] = bool(ambient_motion)
    if tint is not None:
        payload["tint"] = bool(tint)
    if tokens:
        payload["tokens"] = dict(tokens)
    if not payload:
        return
    session.send_custom_message("shinyglass", payload)
    if preset is not None:
        session.send_custom_message("glassPreset", preset)


def glass_intensity_slider(
    id: str = "glass_intensity",
    *,
    label: str = "Liquid Glass",
    value: float = _DEFAULT_INTENSITY,
    min_label: str = "Ultra Clear",
    max_label: str = "Tinted",
) -> Tag:
    """iOS-style Ultra Clear → Tinted control (same markup as R).

    The shared JS binds ``[data-glass-intensity-input]`` so the slider
    updates glass live without a Python observer.
    """
    if not 0.0 <= float(value) <= 1.0:
        raise ValueError("value must be between 0 and 1")
    return tags.div(
        tags.label(label, cls="control-label", **{"for": id}),
        tags.div(
            tags.span(min_label, cls="glass-intensity-end glass-intensity-end--min"),
            tags.div(
                tags.div(cls="glass-intensity-fill"),
                tags.div(cls="glass-intensity-thumb", **{"aria-hidden": "true"}),
                tags.input(
                    type="range",
                    cls="glass-intensity-range form-range",
                    id=id,
                    min="0",
                    max="1",
                    step="0.01",
                    value=str(value),
                    **{"aria-valuemin": "0", "aria-valuemax": "1"},
                ),
                cls="glass-intensity-track",
            ),
            tags.span(max_label, cls="glass-intensity-end glass-intensity-end--max"),
            cls="glass-intensity-row",
        ),
        cls="form-group shiny-input-container glass-intensity-slider",
        **{
            "data-glass-intensity-input": id,
            "data-glass-initial-intensity": str(value),
        },
    )
