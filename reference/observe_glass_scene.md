# Observe [`glass_scene_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scene_input.md) on the server

Echoes a scene id from
[`glass_scenes()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scenes.md)
through
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
after the client has already painted it.

## Usage

``` r
observe_glass_scene(input, session, inputId = "glass_scene")
```

## Arguments

- input, session:

  Shiny server `input` and `session` objects.

- inputId:

  Character. Same id passed to
  [`glass_scene_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scene_input.md).
  Default `"glass_scene"`.

## Value

An
[`shiny::observeEvent()`](https://rdrr.io/pkg/shiny/man/observeEvent.html)
observer (invisibly).

## See also

[`glass_scene_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scene_input.md),
[`glass_scenes()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scenes.md),
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
[`observe_glass_plot_surface()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_plot_surface.md),
[`observe_glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_preset_input.md),
[`observe_glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_theme_toggle.md)

## Examples

``` r
if (interactive()) {
  library(shiny)
  ui <- fluidPage(
    theme = glass_theme(),
    glass_scene_input()
  )
  server <- function(input, output, session) {
    observe_glass_scene(input, session)
  }
  shinyApp(ui, server)
}
```
