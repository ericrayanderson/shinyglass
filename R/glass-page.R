#' One-call glass page
#'
#' Wraps [shiny::fluidPage()] with [glass_theme()] and, by default, the Light /
#' Dark / Auto toggle, intensity slider, and accent wells. Pair with
#' [observe_glass()] in the server function.
#'
#' @param ... UI elements passed to [shiny::fluidPage()].
#' @param title Optional page title ([shiny::titlePanel()]).
#' @param preset,intensity,persist,scene,wallpaper,plot_surface,flatten,refraction,morph,press,scroll_edge,minimize_tabs,icon_style,floating_sidebar
#'   Forwarded to [glass_theme()]. `preset` is `"light"`, `"dark"`, or
#'   `"auto"` (default `"auto"`). `intensity` is numeric from `0` (Ultra
#'   Clear) to `1` (Tinted), default `0.5`. Persistence defaults to `TRUE`
#'   here. `floating_sidebar` stays off unless you opt in.
#' @param controls `TRUE` for the default control row (toggle, intensity,
#'   accent), `FALSE` for none, or a character vector subset of
#'   `"toggle"`, `"intensity"`, `"accent"`.
#' @param theme Optional pre-built [glass_theme()] object. When `NULL`, one is
#'   created from the arguments above.
#'
#' @return A Shiny UI tag list suitable as `shinyApp(ui = ...)`.
#' @seealso [glass_theme()], [observe_glass()], [glass_intensity_slider()]
#' @family glass themes
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
    intensity = 0.5,
    persist = TRUE,
    scene = "tahoe",
    wallpaper = NULL,
    plot_surface = "clear",
    flatten = FALSE,
    refraction = TRUE,
    morph = TRUE,
    press = TRUE,
    scroll_edge = TRUE,
    minimize_tabs = TRUE,
    icon_style = c("clear", "color", "all"),
    floating_sidebar = FALSE,
    controls = TRUE,
    theme = NULL) {
  icon_style <- match.arg(icon_style)
  if (is.null(theme)) {
    theme <- glass_theme(
      preset = preset,
      intensity = intensity,
      persist = persist,
      scene = scene,
      wallpaper = wallpaper,
      plot_surface = plot_surface,
      flatten = flatten,
      refraction = refraction,
      morph = morph,
      press = press,
      scroll_edge = scroll_edge,
      minimize_tabs = minimize_tabs,
      icon_style = icon_style,
      floating_sidebar = floating_sidebar
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
#' @param input,session Shiny server `input` and `session` objects.
#' @param toggle_id,intensity_id,accent_id Character input ids matching the UI
#'   controls. Defaults `"glass_toggle"`, `"glass_intensity"`, `"glass_accent"`.
#'
#' @return `NULL`, invisibly.
#' @seealso [glass_page()], [observe_glass_theme_toggle()],
#'   [observe_glass_intensity()], [observe_glass_accent()]
#' @family glass controls
#' @examples
#' if (interactive()) {
#'   library(shiny)
#'   ui <- glass_page(title = "Hello, glass", plotOutput("plot"))
#'   server <- function(input, output, session) {
#'     observe_glass(input, session)
#'     output$plot <- renderPlot(plot(1:10), bg = "transparent")
#'   }
#'   shinyApp(ui, server)
#' }
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
