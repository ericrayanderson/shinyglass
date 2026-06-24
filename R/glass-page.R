#' Create a Liquid Glass Shiny page
#'
#' Convenience wrapper around [bslib::page_fluid()] with [glass_theme()]
#' pre-applied. For existing apps, prefer passing `theme = glass_theme()` to
#' your existing page function instead.
#'
#' @param ... UI elements to place in the page body.
#' @param title Page title shown in the browser tab.
#' @param header Optional header content (e.g. a title string or tag). When a
#'   character string, it is rendered in a glass navigation bar.
#' @param theme A [bslib::bs_theme()] object. Defaults to [glass_theme()].
#' @param fillable Whether the page should fill the viewport height.
#'
#' @return A Shiny UI definition.
#'
#' @examples
#' \dontrun{
#' library(shiny)
#' library(shinyglass)
#'
#' ui <- glass_page(
#'   header = "My Dashboard",
#'   glass_card(
#'     h3("Hello"),
#'     p("Liquid glass styling applied automatically.")
#'   )
#' )
#' }
#'
#' @export
glass_page <- function(
    ...,
    title = "",
    header = NULL,
    theme = glass_theme(),
    fillable = FALSE) {
  body_content <- list(...)

  if (!is.null(header)) {
    header_ui <- if (is.character(header)) {
      shiny::tags$nav(
        class = "glass-nav",
        shiny::tags$div(class = "glass-title", header)
      )
    } else {
      shiny::tags$nav(class = "glass-nav", header)
    }
    body_content <- c(list(header_ui), body_content)
  }

  page_fn <- if (fillable) bslib::page_fillable else bslib::page_fluid

  page_fn(
    theme = theme,
    title = title,
    shiny::tags$head(
      shiny::includeScript(
        system.file("js", "shiny-glass.js", package = "shinyglass")
      )
    ),
    body_content
  )
}