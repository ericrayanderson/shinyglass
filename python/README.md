# shinyglass (Python)

Liquid Glass themes for **Shiny for Python**, sharing design assets with the R
package under [`inst/`](https://github.com/ericrayanderson/shinyglass/tree/main/inst).

## Install

### From PyPI

```bash
pip install shinyglass
```

### From a git checkout (developers)

```bash
cd python
pip install -e ".[dev,theme]"
python scripts/vendor_assets.py   # compile CSS/JS into src/shinyglass/static/
pytest
```

### From a built wheel

```bash
cd python
python scripts/vendor_assets.py
python -m build --wheel
pip install dist/shinyglass-*.whl
```

Default themes use **precompiled CSS**. **libsass is not required** at runtime.
For custom `primary` / `blur` / `radius`, install the optional extra:

```bash
pip install "shinyglass[theme]"   # pulls libsass
```

## Usage

```python
from shiny import App, ui
from shinyglass import glass_theme

app_ui = ui.page_sidebar(
    ui.sidebar("Filters", ui.input_text("q", "Query")),
    ui.card(ui.card_header("Hello"), "Glass content"),
    theme=glass_theme(preset="light"),  # or "dark"
)

app = App(app_ui, None)
```

### Parameters (same spirit as R)

| Argument | Default | |
| --- | --- | --- |
| `preset` | `"light"` | `"light"`, `"dark"`, or `"auto"` |
| `primary` | `"#007AFF"` | Accent (custom → needs `[theme]`) |
| `blur` | `36` | Backdrop blur px |
| `saturation` | `200` | Backdrop saturate % |
| `radius` | `"1.5rem"` | Corner radius |
| `intensity` | `0.5` | Ultra Clear (`0`) to Tinted (`1`); iOS 27 midpoint. The web cannot read the OS slider. |
| `plot_surface` | `"clear"` | `"opaque"` densifies plot / table hosts (~94% panel); chrome stays glass |
| `scene` | `"default"` | `tahoe` / `dusk` / `mesh` / `aurora` / `harbor` / `grove` |
| `flatten` | `False` | Print / screenshot mode (or `?glass_flatten=1`) |
| `persist` | `False` | Remember preset, intensity, scene, plot surface |
| `refraction` | `True` | Chromium squircle lens. Safari/Firefox keep blur and tint |
| `morph` | `True` | Spring the active pill. Menus scale out of the trigger |
| `press` | `True` | Springy press on buttons and nav links |
| `scroll_edge` | `True` | Toolbar backing while content scrolls underneath |
| `minimize_tabs` | `True` | Shrink tab bars on scroll down |
| `icon_style` | `"clear"` | Monochrome bar icons. `"color"` keeps author colors |
| `floating_sidebar` | `False` | Opt-in detached sidebar |
| `pointer_specular` | `True` | Highlight follows the mouse over glass surfaces |
| `nav_pill` | `True` | Desktop top bar shrinks to a pill while scrolling down |
| `style` | `"default"` | `"clear"` or `"tinted"` sets the starting intensity |
| `motion` | `True` | `False` turns off every motion effect |
| `font` | `"matched"` | Bundled Inter (SIL OFL 1.1, served locally) off Apple devices. `"system"` skips it |

### Controls and tokens

These helpers match the R functions of the same names. Inputs take `id`
instead of `inputId`, and choice dicts map values to labels like
`ui.input_select()`.

```python
from shiny import App, reactive, ui
import shinyglass as sg

theme = sg.glass_add_tokens(sg.glass_theme(preset="auto"), blur="28px")

app_ui = ui.page_sidebar(
    ui.sidebar(
        sg.glass_theme_toggle(),
        sg.glass_preset_input(),
        sg.glass_accent_input(),
        sg.glass_scene_input(),
        ui.input_action_button("flat", "Flatten for capture"),
    ),
    ui.card(ui.card_header("Hello"), "Glass content"),
    title="Controls demo",
    theme=theme,
)


def server(input, output, session):
    sg.observe_glass_theme_toggle(input, session)
    sg.observe_glass_preset_input(input, session)
    sg.observe_glass_accent(input, session)
    sg.observe_glass_scene(input, session)

    @reactive.effect
    @reactive.event(input.flat)
    def _():
        sg.glass_flatten(session, True)


app = App(app_ui, server)
```

| Helper | What it does |
| --- | --- |
| `glass_theme_toggle()` | Light / Dark / Auto button group |
| `glass_preset_input()` | Light / Dark / Auto select, applied as soon as it changes |
| `glass_accent_input()` | iOS accent color wells (`glass_system_colors()`) |
| `glass_scene_input()` | Wallpaper scene select (`glass_scenes()`) |
| `observe_glass_*()` | Echo those inputs through `update_glass_theme()` on the server |
| `glass_flatten(session, on)` | Turn blur off for print, PDF, and screenshots |
| `glass_css_tokens()` | Catalog of public `--glass-*` CSS variables |
| `glass_token_pack(preset)` | Default variable values for light or dark |
| `glass_add_tokens(theme, ...)` | Override variables on a theme without editing SCSS |
| `glass_plot_surface_input()` | Clear / Opaque select for chart and table panels |
| `glass_plot_colors(preset)` | Ink, grid, fill, and paper colors for plots |
| `glass_resolved_preset(input)` | `"light"` or `"dark"`, with Auto resolved to what the page shows |
| `observe_glass(input, session)` | Wire the toggle, intensity slider, and accent observers at once |

## Demo

```bash
cd python
shiny run examples/app_sidebar.py
```

## Layout (Option 2)

| Path | Role |
| --- | --- |
| `../inst/scss/glass.scss` | Shared source of truth |
| `../inst/js/shiny-glass.js` | Shared JS |
| `src/shinyglass/static/` | **Vendored** copy + precompiled `theme-*.css` (ships in wheel) |
| `scripts/vendor_assets.py` | Build step: copy + compile |
| `hatch_build.py` | Hatch hook re-vendors when monorepo `inst/` is present |

Asset resolution order at runtime:

1. Package `static/` (wheel / vendored)
2. Monorepo `inst/` via `SHINYGLASS_PKG_ROOT` or path walk (editable dev)

## Tests & CI

```bash
pytest
```

GitHub Actions (`.github/workflows/python.yml`):

1. Editable install + vendor + sync check + pytest  
2. Build wheel, install in a **clean venv** with no monorepo `inst/`, re-run tests  

## R / Python feature scope

R is the primary implementation. The Python package covers the same theme,
controls, and plot color helpers. A CI check (`tools/api_parity.py`) fails when
an R export has no Python counterpart, or when argument names differ, unless
the item is listed with a reason in `tools/api-parity-allow.toml`. That file
lists what stays R only, such as the ggplot2, gt, DT, and shinyreact helpers.

| Feature | R | Python |
| --- | --- | --- |
| Presets | Light / Dark / Auto | Light / Dark / Auto |
| Live preset / accent updates | Public server and UI helpers | `update_glass_theme()` + shared JS |
| Intensity / material controls | Public API and slider | `intensity=` + `glass_intensity_slider()` |
| `plot_surface` / scenes / flatten | Public API | Same knobs on `glass_theme()` |
| Scroll-edge chrome densify | Shared JS / CSS | Shared vendored JS / CSS |
| Default blur / radius | 36 px / `1.5rem` | 36 px / `1.5rem` |
| Default CSS delivery | bslib Sass compilation | Precompiled wheel assets |
| Custom theme knobs | bslib / sass | Optional `[theme]` extra |
| Theme toggle, preset / accent / scene inputs | Public UI + observers | Same helpers and `observe_glass_*()` |
| Flatten for capture | `glass_flatten()` | `glass_flatten()` |
| CSS token catalog / overrides | `glass_css_tokens()`, `glass_token_pack()`, `glass_add_tokens()` | Same names |
| Plot surface input, plot colors, resolved preset | `glass_plot_surface_input()`, `glass_plot_colors()`, `glass_resolved_preset()` | Same names |
| One-call server wiring | `observe_glass()` | `observe_glass()` |
| Progress bars and range sliders | Shared CSS / JS | Shared vendored CSS / JS |

When editing shared JavaScript, update its vendored copy too. When editing SCSS,
run `python scripts/vendor_assets.py` from this directory to rebuild wheel CSS.
The Python CI jobs verify editable and isolated wheel installations.

The editable job also re-runs `vendor_assets.py` and fails if the vendored
`glass.scss`, JavaScript, or `glass-rules-*.css` files differ from what is
committed. If that check fails, run `python python/scripts/vendor_assets.py`
from the repo root and commit the updated files under
`src/shinyglass/static/`. The `theme-*.css` bundles are not compared because
they include Bootstrap from whichever shiny version is installed.

## Not yet

- Published PyPI release (package version tracks R **0.5.0**; not on PyPI)
- Full R demo gallery parity
- `glass_page()`, `glass_plot_surface_input()`, `glass_resolved_preset()`,
  `observe_glass()` and the intensity / plot surface observers
- Plot and table helpers (`theme_glass()`, `plotly_glass()`, `gt_theme_glass()`,
  `dt_options_glass()`, `glass_plot_colors()`)
- React components
