#' Apple Liquid Glass theme for Shiny
#'
#' Returns a [bslib::bs_theme()] object styled with Apple's Liquid Glass
#' aesthetic. Pass it to any bslib-aware page function or Shiny UI container.
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
#'   card(
#'     card_header("Welcome"),
#'     "Your app content here."
#'   )
#' )
#' }
#'
#' @export
glass_theme <- function(
    preset = c("light", "dark"),
    primary = "#007AFF",
    blur = 20,
    saturation = 180,
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
    ...
  )

  theme <- bslib::bs_add_variables(
    theme,
    "glass-bg" = tokens$glass_bg,
    "glass-bg-hover" = tokens$glass_bg_hover,
    "glass-border" = tokens$glass_border,
    "glass-shadow" = tokens$glass_shadow,
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
  bslib::bs_add_rules(theme, sass::sass_file(glass_scss))
}

#' Apply Liquid Glass theme globally
#'
#' Sets the Liquid Glass theme as the global Bootstrap theme for the current R
#' session. Useful when you want every Shiny app in the session to inherit the
#' glass styling without passing `theme` to each page function.
#'
#' @inheritParams glass_theme
#' @return Invisibly returns the theme object.
#'
#' @examples
#' \dontrun{
#' apply_glass_theme()
#' shiny::runApp("my-app")
#' }
#'
#' @export
apply_glass_theme <- function(
    preset = c("light", "dark"),
    primary = "#007AFF",
    blur = 20,
    saturation = 180,
    radius = "1.25rem",
    ...) {
  theme <- glass_theme(
    preset = preset,
    primary = primary,
    blur = blur,
    saturation = saturation,
    radius = radius,
    ...
  )
  bslib::bs_global_theme(theme)
  invisible(theme)
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
      glass_bg = "rgba(255, 255, 255, 0.45)",
      glass_bg_hover = "rgba(255, 255, 255, 0.6)",
      glass_border = "rgba(255, 255, 255, 0.65)",
      glass_shadow = "rgba(0, 0, 0, 0.08)",
      glass_highlight = "rgba(255, 255, 255, 0.7)",
      glass_specular = "rgba(255, 255, 255, 0.35)",
      glass_menu_bg = "#ffffff",
      glass_menu_color = "#1d1d1f",
      page_bg = "linear-gradient(160deg, #f5f5f7 0%, #e8e8ed 40%, #d2d2d7 100%)",
      orb_1 = "rgba(0, 122, 255, 0.12)",
      orb_2 = "rgba(175, 82, 222, 0.10)",
      orb_3 = "rgba(255, 149, 0, 0.08)"
    )
  } else {
    list(
      body_bg = "#000000",
      body_color = "#f5f5f7",
      glass_bg = "rgba(255, 255, 255, 0.08)",
      glass_bg_hover = "rgba(255, 255, 255, 0.14)",
      glass_border = "rgba(255, 255, 255, 0.15)",
      glass_shadow = "rgba(0, 0, 0, 0.3)",
      glass_highlight = "rgba(255, 255, 255, 0.12)",
      glass_specular = "rgba(255, 255, 255, 0.08)",
      glass_menu_bg = "#2c2c2e",
      glass_menu_color = "#f5f5f7",
      page_bg = "linear-gradient(160deg, #1c1c1e 0%, #000000 50%, #0a0a0c 100%)",
      orb_1 = "rgba(10, 132, 255, 0.18)",
      orb_2 = "rgba(191, 90, 242, 0.14)",
      orb_3 = "rgba(255, 159, 10, 0.10)"
    )
  }
}