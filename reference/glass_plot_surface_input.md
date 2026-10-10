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

Other glass controls:
[`glass_accent_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_accent_input.md),
[`glass_intensity_slider()`](https://ericrayanderson.github.io/shinyglass/reference/glass_intensity_slider.md),
[`glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_preset_input.md),
[`glass_resolved_preset()`](https://ericrayanderson.github.io/shinyglass/reference/glass_resolved_preset.md),
[`glass_scene_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scene_input.md),
[`glass_system_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_system_colors.md),
[`glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_toggle.md),
[`observe_glass()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass.md),
[`observe_glass_accent()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_accent.md),
[`observe_glass_intensity()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_intensity.md),
[`observe_glass_plot_surface()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_plot_surface.md),
[`observe_glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_preset_input.md),
[`observe_glass_scene()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_scene.md),
[`observe_glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_theme_toggle.md)

## Examples

``` r
glass_plot_surface_input(selected = "opaque")
#> <div class="form-group shiny-input-container">
#>   <label class="control-label" id="plot_surface-label" for="plot_surface">Plot / table surface</label>
#>   <div>
#>     <select id="plot_surface" class="shiny-input-select glass-plot-surface-input" data-glass-plot-surface-input="plot_surface"><option value="clear">Clear (show wallpaper)</option>
#> <option value="opaque" selected>Opaque (readable)</option></select>
#>     <script type="application/json" data-for="plot_surface" data-nonempty="">{"plugins":["selectize-plugin-a11y"]}</script>
#>   </div>
#> </div>
```
