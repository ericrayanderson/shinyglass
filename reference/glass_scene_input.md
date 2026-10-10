# Scene picker for wallpaper packs

Drop-in
[`shiny::selectInput()`](https://rdrr.io/pkg/shiny/man/selectInput.html)
that applies `window.shinyglass.setScene()` immediately. Pair with
[`observe_glass_scene()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_scene.md)
so the server stays in sync.

## Usage

``` r
glass_scene_input(
  inputId = "glass_scene",
  label = "Wallpaper scene",
  selected = "default",
  choices = glass_scenes(),
  width = NULL
)
```

## Arguments

- inputId:

  The `input` slot that will be used to access the value.

- label:

  Display label (or `NULL` for none).

- selected:

  Initially selected scene id.

- choices:

  Named character vector. Defaults to
  [`glass_scenes()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scenes.md).

- width:

  The width of the input (e.g. `"100%"`).

## Value

A
[`shiny::selectInput()`](https://rdrr.io/pkg/shiny/man/selectInput.html)
tag marked for client bindings.

## See also

[`glass_scenes()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scenes.md),
[`observe_glass_scene()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_scene.md),
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)

Other glass controls:
[`glass_accent_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_accent_input.md),
[`glass_intensity_slider()`](https://ericrayanderson.github.io/shinyglass/reference/glass_intensity_slider.md),
[`glass_plot_surface_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_surface_input.md),
[`glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_preset_input.md),
[`glass_resolved_preset()`](https://ericrayanderson.github.io/shinyglass/reference/glass_resolved_preset.md),
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
glass_scene_input(selected = "harbor")
#> <div class="form-group shiny-input-container">
#>   <label class="control-label" id="glass_scene-label" for="glass_scene">Wallpaper scene</label>
#>   <div>
#>     <select id="glass_scene" class="shiny-input-select glass-scene-input" data-glass-scene-input="glass_scene"><option value="default">Default orbs</option>
#> <option value="tahoe">Lake Tahoe mist</option>
#> <option value="dusk">Warm dusk</option>
#> <option value="mesh">Soft RGB mesh</option>
#> <option value="aurora">Aurora veil</option>
#> <option value="harbor" selected>Harbor morning</option>
#> <option value="grove">Orchard grove</option></select>
#>     <script type="application/json" data-for="glass_scene" data-nonempty="">{"plugins":["selectize-plugin-a11y"]}</script>
#>   </div>
#> </div>
```
