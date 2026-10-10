# Light / dark / auto theme toggle buttons

Drop-in button group for switching the glass preset. Each button sets
the preset on the client immediately (`window.shinyglass.setPreset`) and
also has a 'shiny' input id so
[`observe_glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_theme_toggle.md)
can keep the server in sync (important on hosts that rewrite custom
messages).

## Usage

``` r
glass_theme_toggle(
  inputId = "glass_toggle",
  selected = c("auto", "light", "dark"),
  labels = c(light = "Light", dark = "Dark", auto = "Auto (OS)"),
  class = "glass-theme-toggle"
)
```

## Arguments

- inputId:

  Base id. Buttons are `{inputId}_light`, `{inputId}_dark`, and
  `{inputId}_auto`.

- selected:

  Initially highlighted mode (`"light"`, `"dark"`, or `"auto"`).
  Cosmetic only; the page theme still comes from
  [`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md).

- labels:

  Named character vector for button labels. Names must be `light`,
  `dark`, and/or `auto`.

- class:

  Extra CSS classes for the wrapper.

## Value

An
[`htmltools::tag()`](https://rstudio.github.io/htmltools/reference/builder.html)
button group.

## See also

[`observe_glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_theme_toggle.md),
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md),
[`glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_preset_input.md)

Other glass controls:
[`glass_accent_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_accent_input.md),
[`glass_intensity_slider()`](https://ericrayanderson.github.io/shinyglass/reference/glass_intensity_slider.md),
[`glass_plot_surface_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_surface_input.md),
[`glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_preset_input.md),
[`glass_resolved_preset()`](https://ericrayanderson.github.io/shinyglass/reference/glass_resolved_preset.md),
[`glass_scene_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scene_input.md),
[`glass_system_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_system_colors.md),
[`observe_glass()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass.md),
[`observe_glass_accent()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_accent.md),
[`observe_glass_intensity()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_intensity.md),
[`observe_glass_plot_surface()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_plot_surface.md),
[`observe_glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_preset_input.md),
[`observe_glass_scene()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_scene.md),
[`observe_glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_theme_toggle.md)

## Examples

``` r
glass_theme_toggle(selected = "dark")
#> <div class="glass-theme-toggle" role="group" aria-label="Glass theme preset">
#>   <button aria-pressed="false" class="btn btn-default action-button btn-sm btn-secondary" data-glass-preset-mode="light" id="glass_toggle_light" type="button"><span class="action-label">Light</span></button>
#>   <button aria-pressed="true" class="btn btn-default action-button btn-sm btn-primary" data-glass-preset-mode="dark" id="glass_toggle_dark" type="button"><span class="action-label">Dark</span></button>
#>   <button aria-pressed="false" class="btn btn-default action-button btn-sm btn-secondary" data-glass-preset-mode="auto" id="glass_toggle_auto" type="button"><span class="action-label">Auto (OS)</span></button>
#> </div>
```
