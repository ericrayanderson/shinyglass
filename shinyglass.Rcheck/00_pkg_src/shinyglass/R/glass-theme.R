#' Apple Liquid Glass theme for Shiny
#'
#' Returns a [bslib::bs_theme()] object styled with Apple's Liquid Glass
#' aesthetic. Pass it to `fluidPage()`, `navbarPage()`, or any bslib-aware
#' page function; that is all you need.
#'
#' @param preset `"light"` or `"dark"`. Controls the overall color scheme.
#' @param primary Primary accent color. Defaults to Apple system blue
#'   (`#007AFF`).
#' @param blur Backdrop blur radius in pixels.
#' @param saturation Backdrop saturation percentage.
#' @param radius Default border radius for glass surfaces.
#' @param ... Additional arguments forwarded to [bslib::bs_theme()].
#'
#' @return A [bslib::bs_theme()] object.
#'
#' @examples
#' \dontrun{
#' library(shiny)
#' library(shinyglass)
#'
#' ui <- fluidPage(
#'   theme = glass_theme(),
#'   titlePanel("Liquid Glass"),
#'   selectInput("color", "Color", c("Blue", "Purple", "Orange")),
#'   plotOutput("plot")
#' )
#' }
#'
#' @export
glass_theme <- function(
    preset = c("light", "dark"),
    primary = "#007AFF",
    blur = 28,
    saturation = 200,
    radius = "1.25rem",
    ...) {
  preset <- match.arg(preset)
  tokens <- .glass_tokens(preset, blur, saturation, radius)

  theme <- bslib::bs_theme(
    version = 5,
    preset = if (preset == "dark") "darkly" else "bootstrap",
    primary = primary,
    "body-bg" = tokens$body_bg,
    "body-color" = tokens$body_color,
    "font-family-sans-serif" = .glass_font_stack(),
    "border-radius" = "1rem",
    "border-radius-lg" = radius,
    "border-radius-sm" = "0.75rem",
    "card-border-width" = "1px",
    "card-border-color" = tokens$glass_border,
    "input-border-color" = tokens$glass_border,
    "navbar-padding-y" = "0.75rem",
    "btn-font-weight" = 600,
    "btn-font-size" = "0.9375rem",
    "btn-line-height" = 1.2,
    "btn-padding-y" = ".55rem",
    "btn-padding-x" = "1.2rem",
    "btn-border-width" = "1px",
    ...
  )

  theme <- bslib::bs_add_variables(
    theme,
    "glass-bg" = tokens$glass_bg,
    "glass-bg-hover" = tokens$glass_bg_hover,
    "glass-border" = tokens$glass_border,
    "glass-shadow" = tokens$glass_shadow,
    "glass-elevated-shadow" = tokens$glass_elevated_shadow,
    "glass-blur" = paste0(blur, "px"),
    "glass-saturate" = paste0(saturation, "%"),
    "glass-radius" = radius,
    "glass-highlight" = tokens$glass_highlight,
    "glass-specular" = tokens$glass_specular,
    "glass-menu-bg" = tokens$glass_menu_bg,
    "glass-menu-color" = tokens$glass_menu_color,
    "glass-page-bg" = tokens$page_bg,
    "glass-orb-1" = tokens$orb_1,
    "glass-orb-2" = tokens$orb_2,
    "glass-orb-3" = tokens$orb_3
  )

  glass_scss <- system.file("scss", "glass.scss", package = "shinyglass")
  theme <- bslib::bs_add_rules(theme, sass::sass_file(glass_scss))

  preset_tag <- htmltools::tagFunction(function() {
    htmltools::tags$script(
      htmltools::HTML(sprintf(
        "document.documentElement.dataset.glassPreset=%s;",
        shQuote(preset, type = "cmd")
      ))
    )
  })

  glass_js <- htmltools::htmlDependency(
    name = "shinyglass",
    version = utils::packageVersion("shinyglass"),
    src = system.file("js", package = "shinyglass"),
    script = "shiny-glass.js"
  )
  bslib::bs_bundle(
    theme,
    sass::sass_layer(html = preset_tag),
    sass::sass_layer(html = glass_js)
  )
}

.glass_font_stack <- function() {
  paste(
    "-apple-system",
    "BlinkMacSystemFont",
    '"SF Pro Display"',
    '"SF Pro Text"',
    '"Segoe UI"',
    "Roboto",
    "Helvetica",
    "Arial",
    "sans-serif",
    sep = ", "
  )
}

.glass_tokens <- function(preset, blur, saturation, radius) {
  if (preset == "light") {
    list(
      body_bg = "#f5f5f7",
      body_color = "#1d1d1f",
      glass_bg = "rgba(255, 255, 255, 0.28)",
      glass_bg_hover = "rgba(255, 255, 255, 0.42)",
      glass_border = "rgba(255, 255, 255, 0.55)",
      glass_shadow = "rgba(0, 0, 0, 0.12)",
      glass_elevated_shadow = "rgba(0, 0, 0, 0.18)",
      glass_highlight = "rgba(255, 255, 255, 0.75)",
      glass_specular = "rgba(255, 255, 255, 0.45)",
      glass_menu_bg = "#ffffff",
      glass_menu_color = "#1d1d1f",
      page_bg = "linear-gradient(145deg, #eef0f8 0%, #f5f5f7 35%, #e8e4f0 70%, #dfe8f5 100%)",
      orb_1 = "rgba(0, 122, 255, 0.28)",
      orb_2 = "rgba(175, 82, 222, 0.22)",
      orb_3 = "rgba(255, 149, 0, 0.16)"
    )
  } else {
    list(
      body_bg = "#000000",
      body_color = "#f5f5f7",
      glass_bg = "rgba(255, 255, 255, 0.08)",
      glass_bg_hover = "rgba(255, 255, 255, 0.14)",
      glass_border = "rgba(255, 255, 255, 0.22)",
      glass_shadow = "rgba(0, 0, 0, 0.42)",
      glass_elevated_shadow = "rgba(0, 0, 0, 0.58)",
      glass_highlight = "rgba(255, 255, 255, 0.16)",
      glass_specular = "rgba(255, 255, 255, 0.12)",
      glass_menu_bg = "#1c1c1e",
      glass_menu_color = "#f5f5f7",
      page_bg = "linear-gradient(145deg, #0c0c14 0%, #000000 40%, #140a1a 75%, #0a1020 100%)",
      orb_1 = "rgba(10, 132, 255, 0.36)",
      orb_2 = "rgba(191, 90, 242, 0.30)",
      orb_3 = "rgba(255, 159, 10, 0.22)"
    )
  }
}