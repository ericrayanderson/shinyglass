# shinyglass

Glass themes for [Shiny](https://shiny.posit.co/), built on
[bslib](https://rstudio.github.io/bslib/). Add translucent surfaces,
live light/dark switching, and adjustable glass intensity to your app.

[Documentation](https://ericrayanderson.github.io/shinyglass/) ·
[Theming
guide](https://ericrayanderson.github.io/shinyglass/articles/theming.html)
· [Release notes](https://ericrayanderson.github.io/shinyglass/NEWS.md)

![Glass intensity changing from clear to
tinted](https://raw.githubusercontent.com/ericrayanderson/shinyglass/main/man/figures/intensity-slider.gif)

## Install

``` r

install.packages("shinyglass")
```

For the latest development features:

``` r

# install.packages("remotes")
remotes::install_github("ericrayanderson/shinyglass")
```

## Quick start

``` r

library(shiny)
library(shinyglass)

ui <- glass_page(
  title = "Hello, glass",
  persist = TRUE,
  scene = "tahoe",
  sliderInput("n", "Bars", 5, 30, 15),
  plotOutput("plot")
)

server <- function(input, output, session) {
  observe_glass(input, session)
  output$plot <- renderPlot({
    pal <- glass_plot_colors(input = input)
    barplot(seq_len(input$n), col = pal$fill, border = NA, col.axis = pal$ink)
  }, bg = "transparent")
}

shinyApp(ui, server)
```

[`glass_page()`](https://ericrayanderson.github.io/shinyglass/reference/glass_page.md)
includes Light / Dark / Auto, the intensity slider, and accent wells.
Set `persist = TRUE` (the default here) to remember those choices.

## Live demos

Apps may take a moment to wake up.

| Demo | Explore |
|----|----|
| [Basics](https://ericrayanderson.shinyapps.io/shinyglass-demo/) | Theme switching and core controls |
| [Dashboard](https://ericrayanderson.shinyapps.io/shinyglass-dashboard/) | Cards, plots, and tables |
| [Inputs](https://ericrayanderson.shinyapps.io/shinyglass-inputs/) | Shiny input controls |
| [Olympic medals](https://ericrayanderson.shinyapps.io/shinyglass-olympics/) | A complete dashboard |
| [plotly + gt](https://ericrayanderson.shinyapps.io/shinyglass-plotly-gt/) | Interactive charts and tables |

Built for Bootstrap 5 and bslib. See
[compatibility](https://ericrayanderson.github.io/shinyglass/articles/compatibility.html)
for supported widgets and older layouts.

More:
[examples](https://github.com/ericrayanderson/shinyglass/tree/main/inst/examples)
· [experimental Python
package](https://github.com/ericrayanderson/shinyglass/tree/main/python)
·
[testing](https://github.com/ericrayanderson/shinyglass/blob/main/inst/scripts/VISUAL-QA.md)
·
[deployment](https://github.com/ericrayanderson/shinyglass/blob/main/inst/scripts/SHINYAPPS-DEPLOY.md)
