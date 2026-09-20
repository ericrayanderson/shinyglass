# Plot / table surface select

Drop-in
[`shiny::selectInput()`](https://rdrr.io/pkg/shiny/man/selectInput.html)
that applies `window.shinyglass.setPlotSurface()` immediately. Pair with
[`observe_glass_plot_surface()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_plot_surface.md)
so the server stays in sync.

## Usage

``` r
glass_plot_surface_input(
  inputId = "plot_surface",
  label = "Plot / table surface",
  selected = c("clear", "opaque"),
  width = NULL
)
```

## Arguments

- inputId:

  The `input` slot that will be used to access the value.

- label:

  Display label (or `NULL` for none).

- selected:

  `"clear"` or `"opaque"`.

- width:

  The width of the input (e.g. `"100%"`).

## Value

A
[`shiny::selectInput()`](https://rdrr.io/pkg/shiny/man/selectInput.html)
tag marked for client bindings.

## See also

[`observe_glass_plot_surface()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_plot_surface.md),
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
