#' Flatten glass for print, PDF, and screenshots
#'
#' Neutralizes backdrop blur and translucent fills so chromote, `pagedown`,
#' print-to-PDF, static HTML, and shareable shots stay readable. The live
#' page can enter or leave flatten without a reload.
#'
#' Ways to enter flatten:
#' * [glass_theme()] `flatten = TRUE` (first paint)
#' * [glass_flatten()] / [update_glass_theme()] `flatten = TRUE` (live)
#' * `window.shinyglass.setFlatten(true)` (or `.enterFlatten()` / `.exitFlatten()`)
#' * Query string `?glass_flatten=1` (handy for chromote / visual QA)
#' * `@media print` (automatic for browser print / PDF)
#'
#' @param session A Shiny session object.
#' @param on `TRUE` to flatten, `FALSE` to restore live glass.
#'
#' @return `session`, invisibly.
#' @seealso [update_glass_theme()], [glass_theme()]
#' @export
#' @examples
#' if (interactive()) {
#'   library(shiny)
#'   library(shinyglass)
#'
#'   ui <- fluidPage(
#'     theme = glass_theme(),
#'     actionButton("flat", "Flatten for capture"),
#'     actionButton("live", "Live glass")
#'   )
#'   server <- function(input, output, session) {
#'     observeEvent(input$flat, glass_flatten(session, TRUE))
#'     observeEvent(input$live, glass_flatten(session, FALSE))
#'   }
#'   shinyApp(ui, server)
#' }
glass_flatten <- function(session, on = TRUE) {
  if (missing(session) || is.null(session)) {
    stop("`session` is required.", call. = FALSE)
  }
  stopifnot(is.logical(on), length(on) == 1L, !is.na(on))
  update_glass_theme(session, flatten = on)
}
