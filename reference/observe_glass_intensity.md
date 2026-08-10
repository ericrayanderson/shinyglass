# Keep session intensity in sync with [`glass_intensity_slider()`](https://ericrayanderson.github.io/shinyglass/reference/glass_intensity_slider.md)

The slider already updates glass live on the client. This observer
optionally echoes the value through
[`update_glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/update_glass_theme.md)
so other clients / server state stay aligned.

## Usage

``` r
observe_glass_intensity(input, session, inputId = "glass_intensity")
```

## Arguments

- input:

  The server `input` object.

- session:

  A Shiny session object.

- inputId:

  Input id of the intensity slider.

## Value

An
[`shiny::observeEvent()`](https://rdrr.io/pkg/shiny/man/observeEvent.html)
observer (invisibly).
