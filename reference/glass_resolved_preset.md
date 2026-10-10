# Resolved light or dark appearance

When the user picks **Auto**, `input$preset` stays `"auto"` so checks
like `identical(input$preset, "dark")` stay FALSE and plots keep light
ink on a dark page. The client publishes the *resolved* appearance as
`input$glass_resolved_preset` (`"light"` or `"dark"`).

## Usage

``` r
glass_resolved_preset(input, default = c("light", "dark"))
```

## Arguments

- input:

  The server `input` object.

- default:

  Fallback if the client has not reported yet (`"light"` or `"dark"`).

## Value

`"light"` or `"dark"`.

## See also

[`glass_plot_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_colors.md),
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)

Other glass controls:
[`glass_accent_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_accent_input.md),
[`glass_intensity_slider()`](https://ericrayanderson.github.io/shinyglass/reference/glass_intensity_slider.md),
[`glass_plot_surface_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_surface_input.md),
[`glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_preset_input.md),
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
glass_resolved_preset(default = "dark")
#> [1] "dark"
```
