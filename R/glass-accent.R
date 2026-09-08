#' iOS system accent colors
#'
#' Named hex colors matching iOS Settings wells: blue, purple, pink, orange,
#' green, and teal.
#'
#' @return A named character vector of `#RRGGBB` colors.
#' @export
glass_system_colors <- function() {
  c(
    blue = "#007AFF",
    purple = "#AF52DE",
    pink = "#FF2D55",
    orange = "#FF9500",
    green = "#34C759",
    teal = "#64D2FF"
  )
}

#' Accent color wells
#'
#' Compact row of color wells. The client applies `window.shinyglass.setPrimary()`
#' immediately; the value is also a Shiny input (`input[[inputId]]`) so the
#' server can persist or restyle plots. Pair with [observe_glass_accent()] if
#' you also want [update_glass_theme()] to echo the change.
#'
#' @param inputId The `input` slot that will be used to access the hex value.
#' @param label Display label (or `NULL` for none).
#' @param selected Initially selected well: a name in `colors` or a hex string.
#' @param colors Named character vector of hex colors. Defaults to
#'   [glass_system_colors()].
#'
#' @return A Shiny UI tag hierarchy.
#' @export
glass_accent_input <- function(
    inputId = "glass_accent",
    label = "Accent",
    selected = "blue",
    colors = glass_system_colors()) {
  stopifnot(is.character(inputId), length(inputId) == 1L, nzchar(inputId))
  stopifnot(is.character(colors), length(colors) >= 1L, !is.null(names(colors)))
  selected <- trimws(as.character(selected))
  hex <- unname(colors[tolower(names(colors)) == tolower(selected)])
  if (!length(hex)) {
    hex <- colors[tolower(colors) == tolower(selected)]
  }
  if (!length(hex)) {
    hex <- colors[[1]]
  } else {
    hex <- hex[[1]]
  }

  wells <- lapply(seq_along(colors), function(i) {
    col <- unname(colors[[i]])
    nm <- names(colors)[[i]]
    on <- identical(tolower(col), tolower(hex))
    htmltools::tags$button(
      type = "button",
      class = paste("glass-accent-well", if (on) "is-selected"),
      style = sprintf("--glass-well-color:%s;background:%s;", col, col),
      `data-glass-primary` = col,
      `data-glass-accent-input` = inputId,
      `aria-label` = nm,
      `aria-checked` = if (on) "true" else "false",
      role = "radio"
    )
  })

  htmltools::tags$div(
    class = "form-group shiny-input-container glass-accent-input",
    id = inputId,
    `data-glass-accent-input` = inputId,
    role = "radiogroup",
    `aria-label` = if (is.null(label)) "Accent color" else NULL,
    if (!is.null(label)) {
      htmltools::tags$label(
        class = "control-label",
        id = paste0(inputId, "-label"),
        label
      )
    },
    htmltools::tags$div(class = "glass-accent-wells", wells)
  )
}

#' Keep session accent in sync with [glass_accent_input()]
#'
#' The wells already update glass live on the client. This observer echoes the
#' hex through [update_glass_theme()] so plots and other sessions can follow.
#'
#' @param input The server `input` object.
#' @param session A Shiny session object.
#' @param inputId Input id of the accent wells.
#'
#' @return An [shiny::observeEvent()] observer (invisibly).
#' @export
observe_glass_accent <- function(input, session, inputId = "glass_accent") {
  if (missing(input) || missing(session)) {
    stop("`input` and `session` are required.", call. = FALSE)
  }
  stopifnot(is.character(inputId), length(inputId) == 1L, nzchar(inputId))
  shiny::observeEvent(
    input[[inputId]],
    {
      val <- input[[inputId]]
      if (is.null(val) || length(val) != 1L || is.na(val) || !nzchar(val)) {
        return()
      }
      update_glass_theme(session, primary = as.character(val))
    },
    ignoreInit = TRUE,
    ignoreNULL = TRUE
  )
}
