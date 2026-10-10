# Observe [`glass_plot_surface_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_surface_input.md) on the server

Echoes `"clear"` or `"opaque"` through
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
after the client has already applied the surface.

## Usage

``` r
observe_glass_plot_surface(input, session, inputId = "plot_surface")
```

## Arguments

- input, session:

  Shiny server `input` and `session` objects.

- inputId:

  Character. Same id passed to
  [`glass_plot_surface_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_surface_input.md).
  Default `"plot_surface"`.

## Value

An
[`shiny::observeEvent()`](https://rdrr.io/pkg/shiny/man/observeEvent.html)
observer (invisibly).

## See also

[`glass_plot_surface_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_surface_input.md),
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)

Other glass controls:
[`glass_accent_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_accent_input.md),
[`glass_intensity_slider()`](https://ericrayanderson.github.io/shinyglass/reference/glass_intensity_slider.md),
[`glass_plot_surface_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_surface_input.md),
[`glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_preset_input.md),
[`glass_resolved_preset()`](https://ericrayanderson.github.io/shinyglass/reference/glass_resolved_preset.md),
[`glass_scene_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scene_input.md),
[`glass_system_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_system_colors.md),
[`glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_toggle.md),
[`observe_glass()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass.md),
[`observe_glass_accent()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_accent.md),
[`observe_glass_intensity()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_intensity.md),
[`observe_glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_preset_input.md),
[`observe_glass_scene()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_scene.md),
[`observe_glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_theme_toggle.md)

## Examples

``` r
if (interactive()) {
  library(shiny)
  ui <- glass_page(
    title = "Surface",
    controls = "toggle",
    glass_plot_surface_input()
  )
  server <- function(input, output, session) {
    observe_glass_plot_surface(input, session)
  }
  shinyApp(ui, server)
}
```
