#' Liquid Glass page for a shinyreact client
#'
#' [shinyreact::page_react()] emits no body HTML and, unless you pass a
#' `theme`, serves **no Bootstrap**. [glass_theme()] is a [bslib::bs_theme()],
#' so the supported call is `page_react(theme = glass_theme())`. Passing the
#' theme as an unnamed argument does not set that parameter: shinyreact then
#' suppresses the Bootstrap dependency, which is also where the compiled glass
#' CSS lives, and the page keeps the JS without the look.
#'
#' [glass_page_react()] is that call. The React client still owns the DOM.
#' Wallpaper, type, and `--glass-*` tokens apply to the document. Bootstrap
#' classes (`.card`, `.btn`, `.form-control`, `.shiny-plot-output`) and the
#' opt-in `.glass-surface` panel pick up Liquid Glass. Hard-coded colors in
#' the client's own CSS do not track light/dark; prefer
#' `var(--glass-body-color)` and `.glass-surface`.
#'
#' Shadow roots do not see document class rules. `--glass-*` custom properties
#' inherit. Call `window.shinyglass.adoptShadow(shadowRoot)` from the
#' component that created the root to inject a `.glass-surface` rule.
#'
#' For [shinyreact::page_react_html()], pass
#' [glass_theme_dependencies()] as `extra_deps`. That helper does not need
#' shinyreact.
#'
#' @param ... Passed to [shinyreact::page_react()] (`src_dir`, `title`,
#'   `lang`, and so on). Do not pass `theme` here.
#' @param theme A [glass_theme()] (or other [bslib::bs_theme()]). Defaults to
#'   [glass_theme()].
#'
#' @return UI suitable for `shinyApp(ui = ...)`.
#'
#' @seealso [glass_theme()], [glass_theme_dependencies()]
#'
#' @examples
#' if (interactive() && requireNamespace("shinyreact", quietly = TRUE)) {
#'   # App directory must contain www/ui.js. See the shipped example:
#'   # system.file("examples/shinyreact-glass", package = "shinyglass")
#'   ui <- glass_page_react(theme = glass_theme(preset = "auto", scene = "tahoe"))
#' }
#'
#' @export
glass_page_react <- function(..., theme = NULL) {
  if (!requireNamespace("shinyreact", quietly = TRUE)) {
    stop(
      "Package \"shinyreact\" is required for glass_page_react(). ",
      "Install it with install.packages(\"shinyreact\").",
      call. = FALSE
    )
  }
  if (is.null(theme)) {
    theme <- glass_theme()
  } else if (!inherits(theme, "bs_theme")) {
    stop("`theme` must be a glass_theme() or bslib::bs_theme() object.", call. = FALSE)
  }
  shinyreact::page_react(..., theme = theme)
}

#' HTML dependencies for a glass theme
#'
#' Turns [glass_theme()] into the [htmltools::htmlDependency()] list that
#' [bslib::bs_theme_dependencies()] would attach on a Bootstrap page. Use this
#' when the page has no `theme` argument, in particular
#' `shinyreact::page_react_html(extra_deps = glass_theme_dependencies(...))`.
#'
#' [glass_page_react()] is the easier entry for [shinyreact::page_react()].
#'
#' @param theme A [glass_theme()] (or other [bslib::bs_theme()]). Defaults to
#'   [glass_theme()].
#'
#' @return A list of [htmltools::htmlDependency()] objects (Bootstrap 5, the
#'   compiled glass rules, the preset head script, and `shiny-glass.js`).
#'
#' @seealso [glass_page_react()], [glass_theme()]
#'
#' @examples
#' deps <- glass_theme_dependencies(glass_theme(preset = "dark"))
#'
#' @export
glass_theme_dependencies <- function(theme = glass_theme()) {
  if (!inherits(theme, "bs_theme")) {
    stop("`theme` must be a glass_theme() or bslib::bs_theme() object.", call. = FALSE)
  }
  bslib::bs_theme_dependencies(theme)
}
