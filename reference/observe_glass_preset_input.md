# Observe [`glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_preset_input.md) on the server

Wires a preset select to
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
so session state stays aligned with the client (the client already
applied the preset live).

## Usage

``` r
observe_glass_preset_input(input, session, inputId = "glass_preset")
```

## Arguments

- input:

  The server `input` object.

- session:

  The server `session` object.

- inputId:

  Same id passed to
  [`glass_preset_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_preset_input.md).

## Value

An
[`shiny::observeEvent()`](https://rdrr.io/pkg/shiny/man/observeEvent.html)
observer (invisibly).
