# shinyglass (Python)

Liquid Glass themes for **Shiny for Python**, sharing design assets with the R
package under [`inst/`](../inst/).

## Install

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

Default themes use **precompiled CSS** — **libsass is not required** at runtime.
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
| `preset` | `"light"` | `"light"` or `"dark"` |
| `primary` | `"#007AFF"` | Accent (custom → needs `[theme]`) |
| `blur` | `28` | Backdrop blur px |
| `saturation` | `200` | Backdrop saturate % |
| `radius` | `"1.25rem"` | Corner radius |

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

1. Editable install + vendor + pytest  
2. Build wheel, install in a **clean venv** with no monorepo `inst/`, re-run tests  

## Not yet

- Published PyPI release (version still `0.1.0.9000` dev)
- Full R demo gallery parity
