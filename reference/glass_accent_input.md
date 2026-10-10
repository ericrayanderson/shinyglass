# Accent color wells

Compact row of color wells. The client applies
`window.shinyglass.setPrimary()` immediately; the value is also a Shiny
input (`input[[inputId]]`) so the server can persist or restyle plots.
Pair with
[`observe_glass_accent()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_accent.md)
if you also want
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
to echo the change.

## Usage

``` r
glass_accent_input(
  inputId = "glass_accent",
  label = "Accent",
  selected = "blue",
  colors = glass_system_colors()
)
```

## Arguments

- inputId:

  The `input` slot that will be used to access the hex value.

- label:

  Display label (or `NULL` for none).

- selected:

  Initially selected well: a name in `colors` or a hex string.

- colors:

  Named character vector of hex colors. Defaults to
  [`glass_system_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_system_colors.md).

## Value

A Shiny UI tag hierarchy.

## See also

[`observe_glass_accent()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_accent.md),
[`glass_system_colors()`](https://ericrayanderson.github.io/shinyglass/reference/glass_system_colors.md),
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)

Other glass controls:
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
[`observe_glass_scene()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_scene.md),
[`observe_glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/observe_glass_theme_toggle.md)

## Examples

``` r
wells <- glass_accent_input()
wells
#> <div class="form-group shiny-input-container glass-accent-input" id="glass_accent" data-glass-accent-input="glass_accent" role="radiogroup">
#>   <label class="control-label" id="glass_accent-label">Accent</label>
#>   <div class="glass-accent-wells">
#>     <button type="button" class="glass-accent-well is-selected" style="--glass-well-color:#007AFF;background:#007AFF;" data-glass-primary="#007AFF" data-glass-accent-input="glass_accent" aria-label="blue" aria-checked="true" role="radio"></button>
#>     <button type="button" class="glass-accent-well " style="--glass-well-color:#AF52DE;background:#AF52DE;" data-glass-primary="#AF52DE" data-glass-accent-input="glass_accent" aria-label="purple" aria-checked="false" role="radio"></button>
#>     <button type="button" class="glass-accent-well " style="--glass-well-color:#FF2D55;background:#FF2D55;" data-glass-primary="#FF2D55" data-glass-accent-input="glass_accent" aria-label="pink" aria-checked="false" role="radio"></button>
#>     <button type="button" class="glass-accent-well " style="--glass-well-color:#FF9500;background:#FF9500;" data-glass-primary="#FF9500" data-glass-accent-input="glass_accent" aria-label="orange" aria-checked="false" role="radio"></button>
#>     <button type="button" class="glass-accent-well " style="--glass-well-color:#34C759;background:#34C759;" data-glass-primary="#34C759" data-glass-accent-input="glass_accent" aria-label="green" aria-checked="false" role="radio"></button>
#>     <button type="button" class="glass-accent-well " style="--glass-well-color:#64D2FF;background:#64D2FF;" data-glass-primary="#64D2FF" data-glass-accent-input="glass_accent" aria-label="teal" aria-checked="false" role="radio"></button>
#>   </div>
#> </div>
```
