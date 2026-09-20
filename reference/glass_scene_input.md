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
