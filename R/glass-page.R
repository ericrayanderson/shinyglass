#' One-call glass page
#'
#' Wraps [shiny::fluidPage()] with [glass_theme()] and, by default, the Light /
#' Dark / Auto toggle, intensity slider, and accent wells. Pair with
#' [observe_glass()] in the server function.
#'
#' @param ... UI elements passed to [shiny::fluidPage()].
#' @param title Optional page title ([shiny::titlePanel()]).
#' @param preset,intensity,persist,scene,wallpaper Forwarded to [glass_theme()].
#'   Persistence defaults to `TRUE` here.
#' @param controls `TRUE` for the default control row (toggle, intensity,
#'   accent), `FALSE` for none, or a character vector subset of
#'   `"toggle"`, `"intensity"`, `"accent"`.
#' @param theme Optional pre-built [glass_theme()] object. When `NULL`, one is
#'   created from the arguments above.
#'
#' @return A Shiny UI tag list suitable as `shinyApp(ui = ...)`.
#' @export
#'
#' @examples
#' if (interactive()) {
#'   library(shiny)
#'   library(shinyglass)
#'
#'   ui <- glass_page(
#'     title = "Hello, glass",
#'     plotOutput("plot")
#'   )
#'   server <- function(input, output, session) {
#'     observe_glass(input, session)
#'     output$plot <- renderPlot(plot(1:10), bg = "transparent")
#'   }
#'   shinyApp(ui, server)
#' }
glass_page <- function(
    ...,
    title = NULL,
    preset = "auto",
    intensity = 0.45,
    persist = TRUE,
    scene = "tahoe",
    wallpaper = NULL,
    controls = TRUE,
    theme = NULL) {
  if (is.null(theme)) {
    theme <- glass_theme(
      preset = preset,
      intensity = intensity,
      persist = persist,
      scene = scene,
      wallpaper = wallpaper
    )
  }

  which <- if (isTRUE(controls)) {
    c("toggle", "intensity", "accent")
  } else if (is.character(controls)) {
    controls
  } else {
    character()
  }

  ctrl <- NULL
  if (length(which)) {
    pieces <- list()
    if ("toggle" %in% which) {
      pieces <- c(pieces, list(glass_theme_toggle(selected = preset)))
    }
    if ("intensity" %in% which) {
      pieces <- c(pieces, list(glass_intensity_slider(value = intensity)))
    }
    if ("accent" %in% which) {
      pieces <- c(pieces, list(glass_accent_input()))
    }
    ctrl <- htmltools::div(class = "glass-page-controls", pieces)
  }

  shiny::fluidPage(
    theme = theme,
    if (!is.null(title)) shiny::titlePanel(title),
    ctrl,
    ...
  )
}

#' Observe every built-in glass control
#'
#' Registers [observe_glass_theme_toggle()], [observe_glass_intensity()], and
#' [observe_glass_accent()] with the default input ids used by [glass_page()].
#'
#' @param input,session Shiny `input` and `session` objects.
#' @param toggle_id,intensity_id,accent_id Input ids matching the UI controls.
#'
#' @return `NULL`, invisibly.
#' @export
observe_glass <- function(
    input,
    session,
    toggle_id = "glass_toggle",
    intensity_id = "glass_intensity",
    accent_id = "glass_accent") {
  observe_glass_theme_toggle(input, session, inputId = toggle_id)
  observe_glass_intensity(input, session, inputId = intensity_id)
  observe_glass_accent(input, session, inputId = accent_id)
  invisible(NULL)
}
