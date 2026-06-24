#' Create a Liquid Glass card
#'
#' A glassmorphic container for grouping UI elements. Also works inside
#' standard [shiny::fluidPage()] when `theme = glass_theme()` is set.
#'
#' @param ... UI elements to place inside the card.
#' @param class Additional CSS classes.
#'
#' @return A `div` tag with glass styling.
#'
#' @export
glass_card <- function(..., class = NULL) {
  shiny::tags$div(
    class = paste(c("glass-card", class), collapse = " "),
    ...
  )
}

#' Create a Liquid Glass button
#'
#' A custom Shiny input styled as a glass button.
#'
#' @param inputId The input identifier.
#' @param label Button label text.
#' @param class Additional CSS classes.
#'
#' @return A `button` tag that registers as a Shiny input.
#'
#' @export
glass_button <- function(inputId, label, class = NULL) {
  shiny::tags$button(
    id = inputId,
    type = "button",
    class = paste(c("glass-button", "shiny-glass-button", class), collapse = " "),
    label
  )
}