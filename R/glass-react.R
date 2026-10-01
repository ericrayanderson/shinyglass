#' HTML dependency for the shinyreact components
#'
#' [shinyreact::page_react()] serves `www/ui.js` as an ES module and exposes
#' one React on `window.shinyreact`. [glass_react_dependency()] is the matching
#' module, `inst/js/shinyglass-react.js`. It registers `useGlassTheme`,
#' `GlassPage`, `GlassMain`, `GlassSidebar`, `GlassSurface`, `GlassCard`,
#' `GlassStack`, `GlassButton`, `GlassTitle`, `GlassMuted`, and `GlassRange`
#' on `window.shinyglass` and as named exports.
#'
#' The module does not import React and does not bundle a second copy.
#' Components call `window.shinyreact.React` when they render. Styling is
#' class names (`.glass-page`, `.glass-sidebar`, `.glass-surface`,
#' `.glass-button-primary`, and so on). Colors, blur, and radius come from
#' the `--glass-*` custom properties already defined by [glass_theme()], so
#' the React pieces stay in sync with the R and Python themes.
#'
#' [glass_page_react()] bundles this dependency into the theme, which
#' [shiny::bootstrapPage()] emits before the app module. `www/ui.js` can read
#' `window.shinyglass` at top level. [glass_theme_dependencies()] appends the
#' same dependency for [shinyreact::page_react_html()]. A plain
#' [glass_theme()] does not load the module, so classic Shiny pages are
#' unchanged.
#'
#' An npm package is intentionally not the distribution. shinyreact's default
#' app has no build step, and htmltools serves this file at a versioned URL,
#' so a hardcoded `import` in `www/ui.js` would break on every package
#' version. The global matches how shinyreact itself is consumed.
#'
#' @return An [htmltools::htmlDependency()].
#'
#' @seealso [glass_page_react()], [glass_theme_dependencies()]
#'
#' @examples
#' dep <- glass_react_dependency()
#' dep$name
#'
#' @export
glass_react_dependency <- function() {
  src <- system.file("js", package = "shinyglass")
  js <- file.path(src, "shinyglass-react.js")
  if (!nzchar(src) || !file.exists(js)) {
    stop("shinyglass-react.js was not found in the package.", call. = FALSE)
  }
  htmltools::htmlDependency(
    name = "shinyglass-react",
    version = as.character(utils::packageVersion("shinyglass")),
    src = c(file = src),
    script = list(src = "shinyglass-react.js", type = "module"),
    all_files = FALSE
  )
}

#' Liquid Glass page for a shinyreact client
#'
#' [shinyreact::page_react()] emits no body HTML and, unless you pass a
#' `theme`, serves **no Bootstrap**. [glass_theme()] is a [bslib::bs_theme()],
#' so the supported call is `page_react(theme = glass_theme())`. Passing the
#' theme as an unnamed argument does not set that parameter: shinyreact then
#' suppresses the Bootstrap dependency, which is also where the compiled glass
#' CSS lives, and the page keeps the JS without the look.
#'
#' [glass_page_react()] is that call, plus [glass_react_dependency()]. The
#' React client still owns the DOM. Build it from `GlassPage`, `GlassSidebar`,
#' `GlassSurface` / `GlassCard`, and `GlassButton` on `window.shinyglass`.
#' `useGlassTheme()` tracks the live mode (`light` / `dark` / `auto`), the
#' resolved preset, scene, material, and intensity, and its setters call
#' `window.shinyglass.setPreset()` and the other existing mutators.
#' Wallpaper, type, and `--glass-*` tokens apply to the document. Those
#' component classes are what pick up Liquid Glass. Do not set panel or text
#' colors in the client's own CSS.
#'
#' Shadow roots do not see document class rules. `--glass-*` custom properties
#' inherit. Call `window.shinyglass.adoptShadow(shadowRoot)` from the
#' component that created the root to inject a `.glass-surface` rule.
#'
#' For [shinyreact::page_react_html()], pass
#' [glass_theme_dependencies()] as `extra_deps`. That helper does not need
#' shinyreact. It includes the React module.
#'
#' @param ... Passed to [shinyreact::page_react()] (`src_dir`, `title`,
#'   `lang`, and so on). Do not pass `theme` here.
#' @param theme A [glass_theme()] (or other [bslib::bs_theme()]). Defaults to
#'   [glass_theme()].
#'
#' @return UI suitable for `shinyApp(ui = ...)`.
#'
#' @seealso [glass_theme()], [glass_theme_dependencies()],
#'   [glass_react_dependency()]
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
  # Theme dependencies render before www/ui.js. The React module has to be
  # in that list, not in `...`, or the app module runs first.
  theme <- bslib::bs_bundle(
    theme,
    sass::sass_layer(html = glass_react_dependency())
  )
  shinyreact::page_react(..., theme = theme)
}

#' HTML dependencies for a glass theme
#'
#' Turns [glass_theme()] into the [htmltools::htmlDependency()] list that
#' [bslib::bs_theme_dependencies()] would attach on a Bootstrap page, and
#' appends [glass_react_dependency()]. Use this when the page has no `theme`
#' argument, in particular
#' `shinyreact::page_react_html(extra_deps = glass_theme_dependencies(...))`.
#'
#' [glass_page_react()] is the easier entry for [shinyreact::page_react()].
#'
#' @param theme A [glass_theme()] (or other [bslib::bs_theme()]). Defaults to
#'   [glass_theme()].
#'
#' @return A list of [htmltools::htmlDependency()] objects (Bootstrap 5, the
#'   compiled glass rules, the preset head script, `shiny-glass.js`, and
#'   `shinyglass-react.js`).
#'
#' @seealso [glass_page_react()], [glass_theme()], [glass_react_dependency()]
#'
#' @examples
#' deps <- glass_theme_dependencies(glass_theme(preset = "dark"))
#'
#' @export
glass_theme_dependencies <- function(theme = glass_theme()) {
  if (!inherits(theme, "bs_theme")) {
    stop("`theme` must be a glass_theme() or bslib::bs_theme() object.", call. = FALSE)
  }
  c(
    bslib::bs_theme_dependencies(theme),
    list(glass_react_dependency())
  )
}
