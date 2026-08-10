#' Liquid Glass theme for 'shiny'
#'
#' Create a [bslib::bs_theme()] styled with a Liquid Glass look: translucent
#' surfaces, backdrop blur, soft depth, and system typography. Pass the result
#' to `theme =` on `fluidPage()`, `navbarPage()`, `bslib::page_sidebar()`, or
#' any other page function that accepts a bslib theme.
#'
#' Light and dark surface tokens are compiled into dual CSS custom-property
#' packs. Switching `preset` at runtime (via [update_glass_theme()] or
#' `preset = "auto"`) updates `document.documentElement.dataset.glassPreset`
#' without recompiling Sass or reloading the page. Accent color can also be
#' updated live with [update_glass_theme()] `primary=` (CSS variables).
#'
#' @param preset `"light"`, `"dark"`, or `"auto"`. `"auto"` follows
#'   `prefers-color-scheme` and updates when the OS theme changes.
#' @param primary Accent color for buttons, links, and focus rings.
#'   Defaults to system blue (`#007AFF`).
#' @param blur Backdrop blur radius in pixels. Default `32` matches the
#'   iOS 27 diffusion-first material.
#' @param saturation Backdrop saturation percentage.
#' @param radius Default border radius for glass surfaces (CSS length).
#'   Prefer larger concentric radii (default `1.5rem`).
#' @param material `"regular"` (adaptive, most UI) or `"clear"` (more
#'   transparent; best over media-rich content with bold labels).
#' @param intensity Liquid Glass intensity from `0` (Ultra Clear) to `1`
#'   (Tinted), matching iOS 27 Appearance -> Liquid Glass. Default `0.45`.
#'   Use [glass_intensity_slider()] for a live control.
#' @param tint Content-aware ambient tint from plots/images (JS).
#' @param specular Pointer-driven specular highlight on glass surfaces (JS).
#' @param nav_morph Compact navbar on scroll down; expand on scroll up (JS).
#' @param ... Additional arguments forwarded to [bslib::bs_theme()].
#'
#' @return A [bslib::bs_theme()] object suitable for 'shiny' page functions.
#'
#' @examples
#' theme <- glass_theme()
#' dark <- glass_theme(preset = "dark", primary = "#BF5AF2")
#' auto <- glass_theme(preset = "auto", tint = FALSE)
#' clear <- glass_theme(material = "clear")
#'
#' if (interactive()) {
#'   library(shiny)
#'
#'   ui <- fluidPage(
#'     theme = glass_theme(preset = "auto"),
#'     titlePanel("Liquid Glass"),
#'     glass_theme_toggle(),
#'     selectInput("color", "Color", c("Blue", "Purple", "Orange")),
#'     plotOutput("plot")
#'   )
#'
#'   server <- function(input, output, session) {
#'     # Client onclick already switches; keep session in sync:
#'     observe_glass_theme_toggle(input, session)
#'   }
#'
#'   shinyApp(ui, server)
#' }
#'
#' @export
glass_theme <- function(
    preset = c("light", "dark", "auto"),
    primary = "#007AFF",
    blur = 36,
    saturation = 200,
    radius = "1.5rem",
    material = c("regular", "clear"),
    intensity = 0.45,
    tint = TRUE,
    specular = TRUE,
    nav_morph = TRUE,
    ...) {
  preset <- match.arg(preset)
  material <- match.arg(material)
  intensity <- .glass_normalize_intensity(intensity)
  stopifnot(
    is.logical(tint), length(tint) == 1L, !is.na(tint),
    is.logical(specular), length(specular) == 1L, !is.na(specular),
    is.logical(nav_morph), length(nav_morph) == 1L, !is.na(nav_morph)
  )
  primary <- .glass_normalize_color(primary)

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
    "border-radius" = "1.1rem",
    "border-radius-lg" = radius,
    "border-radius-sm" = "0.85rem",
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
    # Bootstrap color-contrast() defaults to WCAG AA 4.5:1. White on system
    # blue #007AFF is ~4.02:1, so the gate picks black for buttons, text-bg-*,
    # active states, etc. 3:1 is WCAG UI-component minimum and lets white win
    # on brand blues/purples while pastels (info cyan, warning yellow) still
    # get dark ink. glass.scss glass-on() + solid .bg-* rules are the CSS
    # safety net for value boxes (which use .bg-primary without text color).
    "min-contrast-ratio" = 3,
    # Explicit active-on-accent ink (SVG checks/switches/pagination).
    "component-active-color" = "#ffffff",
    "form-check-input-checked-color" = "#ffffff",
    "form-check-input-indeterminate-color" = "#ffffff",
    "form-switch-checked-color" = "#ffffff",
    "pagination-active-color" = "#ffffff",
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
    nav_morph = nav_morph,
    primary = primary,
    material = material,
    intensity = intensity
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
#' Send a message to the browser to change the Liquid Glass preset, accent
#' color, or content-tint behavior without reloading the page. Requires a page
#' that used [glass_theme()] (so `shiny-glass.js` is loaded).
#'
#' `primary` updates CSS variables (`--bs-primary`, `--bs-primary-rgb`,
#' `--glass-primary`) so buttons, checks, and other accent surfaces follow the
#' new color. Sass-baked one-off colors may not all switch until a full reload.
#'
#' @param session A Shiny session object (usually the `session` argument of
#'   the server function).
#' @param preset Optional. `"light"`, `"dark"`, or `"auto"`.
#' @param tint Optional logical. Enable or disable content-aware ambient tint.
#' @param primary Optional accent color (hex like `"#AF52DE"` or `rgb()`).
#' @param intensity Optional numeric in \eqn{[0, 1]}: Ultra Clear (`0`) to
#'   Tinted (`1`).
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
#'     glass_theme_toggle(),
#'     selectInput("accent", "Accent", c("#007AFF", "#AF52DE", "#FF9500"))
#'   )
#'
#'   server <- function(input, output, session) {
#'     observe_glass_theme_toggle(input, session)
#'     observeEvent(input$accent, {
#'       update_glass_theme(session, primary = input$accent)
#'     }, ignoreInit = TRUE)
#'   }
#'
#'   shinyApp(ui, server)
#' }
#'
#' @export
update_glass_theme <- function(
    session,
    preset = NULL,
    tint = NULL,
    primary = NULL,
    intensity = NULL) {
  if (missing(session) || is.null(session)) {
    stop("`session` is required.", call. = FALSE)
  }
  if (!is.null(preset)) {
    preset <- match.arg(preset, c("light", "dark", "auto"))
  }
  if (!is.null(tint)) {
    stopifnot(is.logical(tint), length(tint) == 1L, !is.na(tint))
  }
  if (!is.null(primary)) {
    primary <- .glass_normalize_color(primary)
  }
  if (!is.null(intensity)) {
    intensity <- .glass_normalize_intensity(intensity)
  }
  if (is.null(preset) && is.null(tint) && is.null(primary) && is.null(intensity)) {
    return(invisible(session))
  }

  payload <- list()
  if (!is.null(preset)) payload$preset <- preset
  if (!is.null(tint)) payload$tint <- tint
  if (!is.null(primary)) payload$primary <- primary
  if (!is.null(intensity)) payload$intensity <- intensity

  # Prefer structured message; JS also accepts legacy glassPreset string.
  session$sendCustomMessage("shinyglass", payload)
  invisible(session)
}

#' Light / dark / auto theme toggle buttons
#'
#' Drop-in button group for switching the glass preset. Each button sets the
#' preset on the client immediately (`window.shinyglass.setPreset`) and also
#' has a 'shiny' input id so [observe_glass_theme_toggle()] can keep the server
#' in sync (important on hosts that rewrite custom messages).
#'
#' @param inputId Base id. Buttons are `{inputId}_light`, `{inputId}_dark`,
#'   and `{inputId}_auto`.
#' @param selected Initially highlighted mode (`"light"`, `"dark"`, or
#'   `"auto"`). Cosmetic only; the page theme still comes from [glass_theme()].
#' @param labels Named character vector for button labels. Names must be
#'   `light`, `dark`, and/or `auto`.
#' @param class Extra CSS classes for the wrapper.
#'
#' @return An [htmltools::tag()] button group.
#'
#' @seealso [observe_glass_theme_toggle()], [update_glass_theme()]
#'
#' @export
glass_theme_toggle <- function(
    inputId = "glass_toggle",
    selected = c("auto", "light", "dark"),
    labels = c(light = "Light", dark = "Dark", auto = "Auto (OS)"),
    class = "d-flex flex-wrap gap-2 glass-theme-toggle") {
  selected <- match.arg(selected)
  stopifnot(is.character(inputId), length(inputId) == 1L, nzchar(inputId))
  modes <- c("light", "dark", "auto")
  if (is.null(names(labels)) || !all(modes %in% names(labels))) {
    stop("`labels` must be a named vector with names light, dark, auto.", call. = FALSE)
  }

  btns <- lapply(modes, function(mode) {
    id <- paste0(inputId, "_", mode)
    btn_class <- "btn-sm"
    if (identical(mode, selected)) {
      btn_class <- paste(btn_class, "btn-primary")
    }
    shiny::actionButton(
      inputId = id,
      label = unname(labels[[mode]]),
      class = btn_class,
      onclick = sprintf(
        "window.shinyglass&&window.shinyglass.setPreset(%s)",
        jsonlite_quote(mode)
      )
    )
  })

  htmltools::div(
    class = class,
    role = "group",
    `aria-label` = "Glass theme preset",
    btns
  )
}

#' Observe [glass_theme_toggle()] buttons on the server
#'
#' Wires the three toggle inputs to [update_glass_theme()] so session state
#' stays aligned with the client (needed on some hosts that rewrite 'shiny'
#' messaging).
#'
#' @param input The server `input` object.
#' @param session The server `session` object.
#' @param inputId Same base id passed to [glass_theme_toggle()].
#'
#' @return `NULL`, invisibly. Called for side effects (registers observers).
#'
#' @export
observe_glass_theme_toggle <- function(input, session, inputId = "glass_toggle") {
  if (missing(input) || missing(session)) {
    stop("`input` and `session` are required.", call. = FALSE)
  }
  stopifnot(is.character(inputId), length(inputId) == 1L, nzchar(inputId))

  shiny::observeEvent(
    input[[paste0(inputId, "_light")]],
    update_glass_theme(session, preset = "light"),
    ignoreInit = TRUE
  )
  shiny::observeEvent(
    input[[paste0(inputId, "_dark")]],
    update_glass_theme(session, preset = "dark"),
    ignoreInit = TRUE
  )
  shiny::observeEvent(
    input[[paste0(inputId, "_auto")]],
    update_glass_theme(session, preset = "auto"),
    ignoreInit = TRUE
  )
  invisible(NULL)
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

.glass_normalize_intensity <- function(intensity) {
  stopifnot(is.numeric(intensity), length(intensity) == 1L, !is.na(intensity))
  if (intensity < 0 || intensity > 1) {
    stop("`intensity` must be between 0 (Ultra Clear) and 1 (Tinted).", call. = FALSE)
  }
  as.numeric(intensity)
}

.glass_normalize_color <- function(primary) {
  stopifnot(is.character(primary), length(primary) == 1L, !is.na(primary))
  primary <- trimws(primary)
  if (!nzchar(primary)) {
    stop("`primary` must be a non-empty color string.", call. = FALSE)
  }
  # Accept #RGB, #RRGGBB, or rgb()/rgba() - leave other CSS colors to the browser.
  if (grepl("^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$", primary) ||
    grepl("^rgba?\\(", primary, ignore.case = TRUE)) {
    return(primary)
  }
  # Named colors / other CSS - still pass through for flexibility
  primary
}

# Luminance-based ink for solid theme fills (matches glass-on() in SCSS).
# Light labels on saturated brand colors; dark on pastels.
.glass_on_color <- function(color, light = "#ffffff", dark = "#1d1d1f") {
  rgb <- .glass_hex_to_rgb(color)
  if (is.null(rgb)) {
    return(light)
  }
  y <- (0.2126 * rgb$r + 0.7152 * rgb$g + 0.0722 * rgb$b) / 255
  if (y >= 0.55) dark else light
}

.glass_tokens <- function(preset, blur, saturation, radius) {
  if (preset == "light") {
    list(
      body_bg = "#f2f2f7",
      body_color = "#1d1d1f",
      glass_bg = "rgba(255, 255, 255, 0.22)",
      glass_bg_hover = "rgba(255, 255, 255, 0.36)",
      glass_border = "rgba(255, 255, 255, 0.62)",
      glass_shadow = "rgba(0, 0, 0, 0.10)",
      glass_elevated_shadow = "rgba(0, 0, 0, 0.16)",
      glass_highlight = "rgba(255, 255, 255, 0.88)",
      glass_specular = "rgba(255, 255, 255, 0.55)",
      glass_menu_bg = "rgba(255, 255, 255, 0.86)",
      glass_menu_color = "#1d1d1f",
      page_bg = "linear-gradient(160deg, #eef1f8 0%, #f5f5f7 42%, #ebe8f4 78%, #e6eef8 100%)",
      orb_1 = "rgba(0, 122, 255, 0.18)",
      orb_2 = "rgba(175, 82, 222, 0.12)",
      orb_3 = "rgba(90, 200, 250, 0.14)"
    )
  } else {
    list(
      body_bg = "#000000",
      body_color = "#f5f5f7",
      glass_bg = "rgba(255, 255, 255, 0.14)",
      glass_bg_hover = "rgba(255, 255, 255, 0.22)",
      glass_border = "rgba(255, 255, 255, 0.26)",
      glass_shadow = "rgba(0, 0, 0, 0.48)",
      glass_elevated_shadow = "rgba(0, 0, 0, 0.62)",
      glass_highlight = "rgba(255, 255, 255, 0.22)",
      glass_specular = "rgba(255, 255, 255, 0.18)",
      glass_menu_bg = "rgba(44, 44, 46, 0.88)",
      glass_menu_color = "#f5f5f7",
      page_bg = "linear-gradient(160deg, #0a0a12 0%, #000000 45%, #100a16 80%, #060a14 100%)",
      orb_1 = "rgba(10, 132, 255, 0.28)",
      orb_2 = "rgba(191, 90, 242, 0.20)",
      orb_3 = "rgba(100, 210, 255, 0.16)"
    )
  }
}

.glass_preset_head_script <- function(
    preset,
    tint,
    specular,
    nav_morph,
    primary = "#007AFF",
    material = "regular",
    intensity = 0.45) {
  # Inline early so first paint uses the right pack. Keep this free of
  # external deps (runs before shiny-glass.js).
  rgb <- .glass_hex_to_rgb(primary)
  on_primary <- .glass_on_color(primary)
  rgb_css <- if (is.null(rgb)) {
    "null"
  } else {
    sprintf("{r:%d,g:%d,b:%d}", rgb$r, rgb$g, rgb$b)
  }
  material <- if (identical(material, "clear")) "clear" else "regular"
  intensity <- .glass_normalize_intensity(intensity)
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
      "root.dataset.glassMaterial=%s;",
      "root.dataset.glassIntensity=%s;",
      "root.style.setProperty('--glass-intensity',%s);",
      "root.dataset.glassTint=%s;",
      "root.dataset.glassSpecular=%s;",
      "root.dataset.glassNavMorph=%s;",
      "var prim=%s;",
      "var rgb=%s;",
      "var onPrim=%s;",
      "if(prim){root.dataset.glassPrimary=prim;",
      "root.style.setProperty('--bs-primary',prim);",
      "root.style.setProperty('--glass-primary',prim);",
      "root.style.setProperty('--glass-accent',prim);",
      "root.style.setProperty('--glass-on-primary',onPrim);",
      "if(rgb){root.style.setProperty('--bs-primary-rgb',rgb.r+', '+rgb.g+', '+rgb.b);}",
      "}",
      "})();</script>"
    ),
    jsonlite_quote(preset),
    jsonlite_quote(material),
    sprintf("%.4f", intensity),
    sprintf("%.4f", intensity),
    if (isTRUE(tint)) "\"true\"" else "\"false\"",
    if (isTRUE(specular)) "\"true\"" else "\"false\"",
    if (isTRUE(nav_morph)) "\"true\"" else "\"false\"",
    jsonlite_quote(primary),
    rgb_css,
    jsonlite_quote(on_primary)
  )
}

.glass_hex_to_rgb <- function(color) {
  color <- trimws(as.character(color))
  if (grepl("^#([0-9A-Fa-f]{3})$", color)) {
    h <- substring(color, 2)
    h <- paste0(
      substr(h, 1, 1), substr(h, 1, 1),
      substr(h, 2, 2), substr(h, 2, 2),
      substr(h, 3, 3), substr(h, 3, 3)
    )
    color <- paste0("#", h)
  }
  if (!grepl("^#([0-9A-Fa-f]{6})$", color)) {
    return(NULL)
  }
  list(
    r = strtoi(substr(color, 2, 3), 16L),
    g = strtoi(substr(color, 4, 5), 16L),
    b = strtoi(substr(color, 6, 7), 16L)
  )
}

# Avoid depending on jsonlite just to quote a short string.
jsonlite_quote <- function(x) {
  paste0('"', gsub("([\\\\\"])", "\\\\\\1", as.character(x)), '"')
}
