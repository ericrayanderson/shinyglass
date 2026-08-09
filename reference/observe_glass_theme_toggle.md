# Observe [`glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_toggle.md) buttons on the server

Wires the three toggle inputs to
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
so session state stays aligned with the client (needed on some hosts
that rewrite Shiny messaging).

## Usage

``` r
observe_glass_theme_toggle(input, session, inputId = "glass_toggle")
```

## Arguments

- input:

  The server `input` object.

- session:

  The server `session` object.

- inputId:

  Same base id passed to
  [`glass_theme_toggle()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme_toggle.md).

## Value

`NULL`, invisibly. Called for side effects (registers observers).
