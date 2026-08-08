#' Liquid Glass theme for Shiny
#'
#' Create a [bslib::bs_theme()] styled with a Liquid Glass look: translucent
#' surfaces, backdrop blur, soft depth, and system typography. Pass the result
#' to `theme =` on `fluidPage()`, `navbarPage()`, `bslib::page_sidebar()`, or
#' any other page function that accepts a bslib theme.
#'
#' Light and dark surface tokens are compiled into dual CSS custom-property
#' packs. Switching `preset` at runtime (via [update_glass_theme()] or
#' `preset = "auto"`) updates `document.documentElement.dataset.glassPreset`
#' without recompiling Sass or reloading the page.
#'
#' @param preset `"light"`, `"dark"`, or `"auto"`. `"auto"` follows
#'   `prefers-color-scheme` and updates when the OS theme changes.
#' @param primary Accent color for buttons, links, and focus rings.
#'   Defaults to system blue (`#007AFF`).
#' @param blur Backdrop blur radius in pixels.
#' @param saturation Backdrop saturation percentage.
#' @param radius Default border radius for glass surfaces (CSS length).
#' @param tint Content-aware ambient tint from plots/images (JS).
#' @param specular Pointer-driven specular highlight on glass surfaces (JS).
#' @param nav_morph Compact navbar on scroll down; expand on scroll up (JS).
#' @param ... Additional arguments forwarded to [bslib::bs_theme()].
#'
#' @return A [bslib::bs_theme()] object suitable for Shiny page functions.
#'
#' @examples
#' theme <- glass_theme()
#' dark <- glass_theme(preset = "dark", primary = "#BF5AF2")
#' auto <- glass_theme(preset = "auto", tint = FALSE)
#'
#' if (interactive()) {
#'   library(shiny)
#'
#'   ui <- fluidPage(
#'     theme = glass_theme(preset = "auto"),
#'     titlePanel("Liquid Glass"),
#'     actionButton("toggle", "Toggle light / dark"),
#'     selectInput("color", "Color", c("Blue", "Purple", "Orange")),
#'     plotOutput("plot")
#'   )
#'
#'   server <- function(input, output, session) {
#'     mode <- reactiveVal("light")
#'     observeEvent(input$toggle, {
#'       mode(if (identical(mode(), "light")) "dark" else "light")
#'       update_glass_theme(session, preset = mode())
#'     })
#'   }
#'
#'   shinyApp(ui, server)
#' }
#'
#' @export
glass_theme <- function(
    preset = c("light", "dark", "auto"),
    primary = "#007AFF",
    blur = 28,
    saturation = 200,
    radius = "1.25rem",
    tint = TRUE,
    specular = TRUE,
    nav_morph = TRUE,
    ...) {
  preset <- match.arg(preset)
  stopifnot(
    is.logical(tint), length(tint) == 1L, !is.na(tint),
    is.logical(specular), length(specular) == 1L, !is.na(specular),
    is.logical(nav_morph), length(nav_morph) == 1L, !is.na(nav_morph)
  )

  # Sass still needs a single pack of $glass-* defaults at compile time.
  # Runtime light/dark comes from dual CSS variable packs in glass.scss.
  # Always use the Bootstrap base (not darkly) so switching preset does not
  # fight Bootswatch dark chrome.
  tokens <- .glass_tokens("light", blur, saturation, radius)

  theme <- bslib::bs_theme(
    version = 5,
    preset = "bootstrap",
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
    # Shared knobs still used by Sass ($glass-blur, etc.)
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

  pkg_version <- as.character(utils::packageVersion("shinyglass"))
  js_src <- system.file("js", package = "shinyglass")

  # Early head script: set data-glass-preset before first paint.
  # "auto" resolves prefers-color-scheme on the client.
  head_script <- .glass_preset_head_script(
    preset = preset,
    tint = tint,
    specular = specular,
    nav_morph = nav_morph
  )

  # htmlDependency (not tagFunction-returned tags) so htmltools does not
  # warn when dependencies are resolved via bs_theme_dependencies().
  preset_dep <- htmltools::htmlDependency(
    name = "shinyglass-preset",
    version = pkg_version,
    src = js_src,
    head = head_script,
    all_files = FALSE
  )

  glass_js <- htmltools::htmlDependency(
    name = "shinyglass",
    version = pkg_version,
    src = js_src,
    script = "shiny-glass.js",
    all_files = FALSE
  )
  bslib::bs_bundle(
    theme,
    sass::sass_layer(html = preset_dep),
    sass::sass_layer(html = glass_js)
  )
}

#' Update glass theme options in a running app
#'
#' Send a message to the browser to change the Liquid Glass preset or
#' content-tint behavior without reloading the page. Requires a page that
#' used [glass_theme()] (so `shiny-glass.js` is loaded).
#'
#' @param session A Shiny session object (usually the `session` argument of
#'   the server function).
#' @param preset Optional. `"light"`, `"dark"`, or `"auto"`.
#' @param tint Optional logical. Enable or disable content-aware ambient tint.
#'
#' @return `session`, invisibly.
#'
#' @examples
#' if (interactive()) {
#'   library(shiny)
#'   library(shinyglass)
#'
#'   ui <- fluidPage(
#'     theme = glass_theme(),
#'     actionButton("dark", "Dark"),
#'     actionButton("light", "Light")
#'   )
#'
#'   server <- function(input, output, session) {
#'     observeEvent(input$dark, update_glass_theme(session, preset = "dark"))
#'     observeEvent(input$light, update_glass_theme(session, preset = "light"))
#'   }
#'
#'   shinyApp(ui, server)
#' }
#'
#' @export
update_glass_theme <- function(session, preset = NULL, tint = NULL) {
  if (missing(session) || is.null(session)) {
    stop("`session` is required.", call. = FALSE)
  }
  if (!is.null(preset)) {
    preset <- match.arg(preset, c("light", "dark", "auto"))
  }
  if (!is.null(tint)) {
    stopifnot(is.logical(tint), length(tint) == 1L, !is.na(tint))
  }
  if (is.null(preset) && is.null(tint)) {
    return(invisible(session))
  }

  payload <- list()
  if (!is.null(preset)) payload$preset <- preset
  if (!is.null(tint)) payload$tint <- tint

  # Prefer structured message; JS also accepts legacy glassPreset string.
  session$sendCustomMessage("shinyglass", payload)
  invisible(session)
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

.glass_preset_head_script <- function(preset, tint, specular, nav_morph) {
  # Inline early so first paint uses the right pack. Keep this free of
  # external deps (runs before shiny-glass.js).
  sprintf(
    paste0(
      "<script>(function(){",
      "var p=%s;",
      "var root=document.documentElement;",
      "root.dataset.glassMode=p;",
      "function resolve(mode){",
      "if(mode==='auto'){",
      "try{",
      "return window.matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';",
      "}catch(e){return 'light';}",
      "}",
      "return mode==='dark'?'dark':'light';",
      "}",
      "root.dataset.glassPreset=resolve(p);",
      "root.dataset.glassTint=%s;",
      "root.dataset.glassSpecular=%s;",
      "root.dataset.glassNavMorph=%s;",
      "})();</script>"
    ),
    jsonlite_quote(preset),
    if (isTRUE(tint)) "\"true\"" else "\"false\"",
    if (isTRUE(specular)) "\"true\"" else "\"false\"",
    if (isTRUE(nav_morph)) "\"true\"" else "\"false\""
  )
}

# Avoid depending on jsonlite just to quote a short string.
jsonlite_quote <- function(x) {
  paste0('"', gsub("([\\\\\"])", "\\\\\\1", as.character(x)), '"')
}
