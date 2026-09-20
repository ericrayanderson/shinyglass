# Observe [`glass_scene_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scene_input.md) on the server

Observe
[`glass_scene_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scene_input.md)
on the server

## Usage

``` r
observe_glass_scene(input, session, inputId = "glass_scene")
```

## Arguments

- input, session:

  Shiny `input` and `session` objects.

- inputId:

  Same id passed to
  [`glass_scene_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_scene_input.md).

## Value

An
[`shiny::observeEvent()`](https://rdrr.io/pkg/shiny/man/observeEvent.html)
observer (invisibly).
