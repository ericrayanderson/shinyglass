#' Liquid Glass intensity slider (iOS 27-style)
#'
#' UI control matching iOS 27 **Settings -> Appearance -> Liquid Glass**: a
#' continuous slider from **Ultra Clear** (`0`) to **Tinted** (`1`) that
#' live-updates the glass material without a page reload.
#'
#' The client applies changes immediately via `window.shinyglass.setIntensity()`.
#' The value is also a normal Shiny input (`input[[inputId]]`) so the server can
#' react or persist it. Pair with [glass_theme()] `intensity=` for the starting
#' value, and optionally [observe_glass_intensity()] to push server-driven
#' updates through [update_glass_theme()].
#'
#' @param inputId The `input` slot that will be used to access the value.
#' @param label Display label for the control (or `NULL` for none).
#' @param value Initial intensity in \eqn{[0, 1]}. If `NULL`, uses the theme
#'   default from [glass_theme()] / the client current intensity.
#' @param min,max,step Range for the underlying range input. Defaults cover
#'   the full Ultra Clear -> Tinted spectrum.
#' @param min_label,max_label End-cap captions (iOS uses "Ultra Clear" /
#'   "Tinted").
#' @param preview Show three mini glass chips as a live material sample.
#' @param width CSS width (passed to [shiny::validateCssUnit()]).
#'
#' @return A Shiny UI tag hierarchy.
#'
#' @examples
#' if (interactive()) {
#'   library(shiny)
#'   library(shinyglass)
#'
#'   ui <- fluidPage(
#'     theme = glass_theme(intensity = 0.35),
#'     glass_theme_toggle(),
#'     glass_intensity_slider("glass_intensity"),
#'     plotOutput("p")
#'   )
#'
#'   server <- function(input, output, session) {
#'     observe_glass_theme_toggle(input, session)
#'     # optional: mirror slider -> server message (client already updates live)
#'     observe_glass_intensity(input, session, "glass_intensity")
#'     output$p <- renderPlot(plot(rnorm(100), rnorm(100), pch = 16, col = "#007AFF"))
#'   }
#'
#'   shinyApp(ui, server)
#' }
#'
#' @export
glass_intensity_slider <- function(
    inputId = "glass_intensity",
    label = "Liquid Glass",
    value = NULL,
    min = 0,
    max = 1,
    step = 0.01,
    min_label = "Ultra Clear",
    max_label = "Tinted",
    preview = TRUE,
    width = NULL) {
  stopifnot(is.character(inputId), length(inputId) == 1L, nzchar(inputId))
  if (!is.null(value)) {
    value <- .glass_normalize_intensity(value)
  } else {
    value <- 0.45
  }
  stopifnot(
    is.numeric(min), length(min) == 1L,
    is.numeric(max), length(max) == 1L,
    is.numeric(step), length(step) == 1L,
    min < max
  )

  style <- if (!is.null(width)) {
    sprintf("width:%s;", shiny::validateCssUnit(width))
  } else {
    NULL
  }

  chips <- if (isTRUE(preview)) {
    htmltools::tags$div(
      class = "glass-intensity-preview",
      htmltools::tags$div(class = "glass-intensity-chip", "Clear"),
      htmltools::tags$div(class = "glass-intensity-chip", "Default"),
      htmltools::tags$div(class = "glass-intensity-chip", "Tinted")
    )
  } else {
    NULL
  }

  htmltools::tags$div(
    class = "form-group shiny-input-container glass-intensity-slider",
    style = style,
    `data-glass-intensity-input` = inputId,
    if (!is.null(label)) {
      htmltools::tags$label(
        class = "control-label",
        id = paste0(inputId, "-label"),
        `for` = inputId,
        label
      )
    },
    htmltools::tags$div(
      class = "glass-intensity-row",
      htmltools::tags$span(
        class = "glass-intensity-end glass-intensity-end--min",
        min_label
      ),
      htmltools::tags$div(
        class = "glass-intensity-track",
        htmltools::tags$div(class = "glass-intensity-fill"),
        htmltools::tags$div(class = "glass-intensity-thumb", `aria-hidden` = "true"),
        htmltools::tags$input(
          type = "range",
          class = "glass-intensity-range form-range",
          id = inputId,
          min = min,
          max = max,
          step = step,
          value = value,
          `aria-valuemin` = min,
          `aria-valuemax` = max,
          `aria-valuenow` = value,
          `aria-labelledby` = if (!is.null(label)) paste0(inputId, "-label") else NULL
        )
      ),
      htmltools::tags$span(
        class = "glass-intensity-end glass-intensity-end--max",
        max_label
      )
    ),
    chips,
    htmltools::tags$span(
      class = "glass-intensity-hint",
      "Drag to match iOS 27 Liquid Glass - Ultra Clear through Tinted."
    )
  )
}

#' Keep session intensity in sync with [glass_intensity_slider()]
#'
#' The slider already updates glass live on the client. This observer optionally
#' echoes the value through [update_glass_theme()] so other clients / server
#' state stay aligned.
#'
#' @param input The server `input` object.
#' @param session A Shiny session object.
#' @param inputId Input id of the intensity slider.
#'
#' @return An [shiny::observeEvent()] observer (invisibly).
#'
#' @export
observe_glass_intensity <- function(input, session, inputId = "glass_intensity") {
  stopifnot(is.character(inputId), length(inputId) == 1L, nzchar(inputId))
  shiny::observeEvent(
    input[[inputId]],
    {
      val <- input[[inputId]]
      if (is.null(val) || length(val) != 1L || is.na(val)) {
        return()
      }
      update_glass_theme(session, intensity = as.numeric(val))
    },
    ignoreInit = TRUE,
    ignoreNULL = TRUE
  )
}
