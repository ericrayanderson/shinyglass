# Keep session accent in sync with [`glass_accent_input()`](https://ericrayanderson.github.io/shinyglass/reference/glass_accent_input.md)

The wells already update glass live on the client. This observer echoes
the hex through
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
so plots and other sessions can follow.

## Usage

``` r
observe_glass_accent(input, session, inputId = "glass_accent")
```

## Arguments

- input:

  The server `input` object.

- session:

  A Shiny session object.

- inputId:

  Input id of the accent wells.

## Value

An
[`shiny::observeEvent()`](https://rdrr.io/pkg/shiny/man/observeEvent.html)
observer (invisibly).
