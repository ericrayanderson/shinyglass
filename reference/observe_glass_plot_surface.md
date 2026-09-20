# Observe [`glass_plot_surface_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_surface_input.md) on the server

Observe
[`glass_plot_surface_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_surface_input.md)
on the server

## Usage

``` r
observe_glass_plot_surface(input, session, inputId = "plot_surface")
```

## Arguments

- input, session:

  Shiny `input` and `session` objects.

- inputId:

  Same id passed to
  [`glass_plot_surface_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_plot_surface_input.md).

## Value

An
[`shiny::observeEvent()`](https://rdrr.io/pkg/shiny/man/observeEvent.html)
observer (invisibly).
