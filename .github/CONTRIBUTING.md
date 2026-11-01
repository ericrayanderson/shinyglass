# Contributing to shinyglass

## Keeping the R and Python packages in step

The repository holds the R package and the Shiny for Python package in
`python/`. They share the SCSS and JavaScript, and they aim to expose the same
functions with the same argument names.

Two checks run in CI (the Python workflow):

- **Vendored assets.** `python/scripts/vendor_assets.py` copies the shared
  SCSS and JavaScript into the Python package. CI re-runs it and fails if the
  committed copy is out of date.
- **API parity.** `tools/api_parity.py` compares the exports in `NAMESPACE`
  with `__all__` in `python/src/shinyglass/__init__.py`, then compares
  argument names for functions found on both sides. R's `inputId` matches
  Python's `id`, `class` matches `class_`, and `...` matches `*args` or
  `**kwargs`. Python arguments that start with an underscore are ignored.

Run the parity check locally from the repository root:

```sh
python tools/api_parity.py
```

### When you add or change an R export

1. Draft the Python version:

   ```sh
   python tools/draft_python_wrapper.py glass_plot_surface_input
   ```

   This prints a function stub with the R argument names and simple defaults.
   It is only a starting point. Read the R function, write the body by hand,
   add type hints and a docstring, and export it from `__init__.py`.
2. Add a test under `python/tests/`.
3. Run `python tools/api_parity.py` and `pytest` in `python/`.

If a function or argument should exist on only one side, add it to
`tools/api-parity-allow.toml` with a short reason. Examples are helpers for R
only packages such as ggplot2, gt, DT, or shinyreact. The check also fails
when an allow list entry is no longer needed, so remove entries once the
missing side is added.
