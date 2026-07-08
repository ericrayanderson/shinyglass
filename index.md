# shinyglass

**Apple-inspired Liquid Glass themes for
[Shiny](https://shiny.posit.co/).**

One function —
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
— gives your app translucent surfaces, backdrop blur, soft depth, and
system typography. Built on [bslib](https://rstudio.github.io/bslib/).

[Documentation](https://ericrayanderson.github.io/shinyglass/) ·
[GitHub](https://github.com/ericrayanderson/shinyglass)

![Demo app, light](reference/figures/shinyglass-demo.png)![Demo app,
dark](reference/figures/shinyglass-demo-dark.png)

*Light and dark presets*

## Installation

``` r

# install.packages("shinyglass")  # once on CRAN
remotes::install_github("ericrayanderson/shinyglass")
```

## Usage

``` r

library(shiny)
library(shinyglass)

ui <- fluidPage(
  theme = glass_theme(),
  titlePanel("Liquid Glass"),
  selectInput("color", "Favorite color", c("Blue", "Purple", "Orange")),
  sliderInput("n", "Number of bars", 5, 30, 15),
  plotOutput("plot")
)

server <- function(input, output, session) {
  output$plot <- renderPlot({
    barplot(
      seq_len(input$n),
      col = "#007AFF",
      border = NA,
      main = paste("You chose", input$color)
    )
  })
}

shinyApp(ui, server)
```

Pass
[`glass_theme()`](https://ericrayanderson.github.io/shinyglass/reference/glass_theme.md)
to any page function that accepts a bslib theme
([`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html),
[`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html),
`page_sidebar()`, and so on). Standard Shiny inputs and layouts are
styled automatically.

## Options

``` r

glass_theme(
  preset     = "dark",   # "light" or "dark"
  primary    = "#007AFF",
  blur       = 28,
  saturation = 200,
  radius     = "1.25rem"
)
```

## Screenshots

![Dashboard, light](reference/figures/bslib-dashboard.png)![Dashboard,
dark](reference/figures/bslib-dashboard-dark.png)

![Data explorer, light](reference/figures/querychat-demo.png)![Data
explorer, dark](reference/figures/querychat-demo-dark.png)

![Sidebar layout,
light](reference/figures/apple-glass-reference.png)![Sidebar layout,
dark](reference/figures/apple-glass-reference-dark.png)

![GitHub dashboard,
light](reference/figures/dreamrs-gh-dashboard.png)![GitHub dashboard,
dark](reference/figures/dreamrs-gh-dashboard-dark.png)

![Olympic medals,
light](reference/figures/dreamrs-olympic-medals.png)![Olympic medals,
dark](reference/figures/dreamrs-olympic-medals-dark.png)

![Time series dashboard,
light](reference/figures/dreamrs-tdb-naissances.png)![Time series
dashboard, dark](reference/figures/dreamrs-tdb-naissances-dark.png)

![Map dashboard, light](reference/figures/dreamrs-ratp-traffic.png)![Map
dashboard, dark](reference/figures/dreamrs-ratp-traffic-dark.png)

![Sidebar](reference/figures/gallery/01-fluid-sidebar.png)![Tabs](reference/figures/gallery/02-tabsets.png)![DataTables](reference/figures/gallery/05-datatables.png)![Buttons](reference/figures/gallery/03-action-button.png)

## Examples

``` r

# Bundled demos
shiny::runApp(system.file("examples", "demo-app.R", package = "shinyglass"))
shiny::runApp(system.file("examples", "bslib-dashboard.R", package = "shinyglass"))
shiny::runApp(system.file("examples", "apple-glass-reference.R", package = "shinyglass"))
```

## License

GPL-3
