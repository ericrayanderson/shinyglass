# shinyglass (Python spike)

Liquid Glass themes for **Shiny for Python**, reusing the same design assets as
the R package:

| Asset | Location (monorepo) |
| --- | --- |
| SCSS | [`../inst/scss/glass.scss`](../inst/scss/glass.scss) |
| JS | [`../inst/js/shiny-glass.js`](../inst/js/shiny-glass.js) |

This is **Option 2**: a `python/` tree beside the CRAN R package. It is ignored
by `R CMD build` (see root `.Rbuildignore`).

## Status

Experimental spike. API mirrors R’s `glass_theme()` but packaging for PyPI
(wheels that vendor CSS/JS) is not finished — for now, run from a git checkout
of [ericrayanderson/shinyglass](https://github.com/ericrayanderson/shinyglass).

## Install (editable, from monorepo)

```bash
cd python
pip install -e ".[dev]"
```

Requires the R package tree at the repo root (`inst/scss`, `inst/js`). Override
with:

```bash
export SHINYGLASS_PKG_ROOT=/path/to/shinyglass
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
| `primary` | `"#007AFF"` | Accent |
| `blur` | `28` | Backdrop blur (px) |
| `saturation` | `200` | Backdrop saturate (%) |
| `radius` | `"1.25rem"` | Corner radius |

## Demo

```bash
cd python
shiny run examples/app_sidebar.py
```

## Tests

```bash
cd python
pytest
```

## How it works

1. Resolve `inst/scss/glass.scss` + `inst/js/` from the monorepo root.
2. Build a `shiny.ui.Theme` (Bootstrap 5) with the same Sass tokens as R.
3. Inject `glass.scss` via `.add_rules()` (compiled with **libsass** at runtime).
4. Attach `shiny-glass.js` and `data-glass-preset` through a small `Theme`
   subclass (same idea as R’s `htmlDependency` bundle).

## Not in this spike

- PyPI wheel that vendors precompiled CSS (no monorepo checkout)
- Full demo gallery parity with R `inst/examples`
- Express-only helpers (Core `theme=` works; Express uses `ui.page_opts`)
