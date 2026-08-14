# Resolved light or dark appearance

When the user picks **Auto**, `input$preset` stays `"auto"` so checks
like `identical(input$preset, "dark")` stay FALSE and plots keep light
ink on a dark page. The client publishes the *resolved* appearance as
`input$glass_resolved_preset` (`"light"` or `"dark"`).

## Usage

``` r
glass_resolved_preset(input, default = c("light", "dark"))
```

## Arguments

- input:

  The server `input` object.

- default:

  Fallback if the client has not reported yet (`"light"` or `"dark"`).

## Value

`"light"` or `"dark"`.
