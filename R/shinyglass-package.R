#' Liquid Glass Design Themes for 'shiny' Applications
#'
#' Drop-in Liquid Glass themes for [shiny](https://shiny.posit.co/). Call
#' [glass_theme()] and pass the result to `theme =` on `fluidPage()`,
#' `navbarPage()`, or any [bslib](https://rstudio.github.io/bslib/)-aware page
#' function to get translucent surfaces, backdrop blur, and system typography.
#'
#' @section Getting started:
#' ```r
#' library(shiny)
#' library(shinyglass)
#'
#' ui <- glass_page(
#'   title = "Liquid Glass",
#'   persist = TRUE,
#'   sliderInput("n", "Bars", 5, 30, 15),
#'   plotOutput("plot")
#' )
#'
#' server <- function(input, output, session) {
#'   observe_glass(input, session)
#'   output$plot <- renderPlot(
#'     barplot(seq_len(input$n), col = "#007AFF", border = NA),
#'     bg = "transparent"
#'   )
#' }
#' ```
#'
#' Light and dark presets are available via `glass_theme(preset = "dark")`,
#' or `preset = "auto"` to follow the OS. Switch at runtime with
#' [update_glass_theme()] or [glass_theme_toggle()]. Material density is
#' controlled with [glass_intensity_slider()] (Ultra Clear to Tinted, matching
#' iOS 27 Settings -> Appearance -> Liquid Glass) or
#' `glass_theme(intensity = )`. Accent color, blur, saturation, corner radius,
#' and JS behaviors (`tint`, `specular`, `nav_morph`) are configurable.
#'
#' For [teal](https://insightsengineering.github.io/teal/) apps, set
#' `options(teal.bs_theme = glass_theme())` before calling `teal::init()`.
#'
#' @seealso [glass_page()], [glass_theme()], [theme_glass()],
#'   [glass_intensity_slider()], [update_glass_theme()]
#'
#' @keywords internal
"_PACKAGE"
