#' Named wallpaper scenes
#'
#' Curated page backgrounds for [glass_theme()] `scene=`. Each name ships
#' light and dark gradient/orb packs. Pair with `wallpaper=` for a user photo;
#' the photo is blurred and washed so body ink stays above the contrast floor
#' documented in [glass_css_tokens()].
#'
#' @return A named character vector: names are scene ids, values are labels.
#' @export
#' @examples
#' names(glass_scenes())
#' glass_theme(scene = "aurora")
glass_scenes <- function() {
  c(
    default = "Default orbs",
    tahoe = "Lake Tahoe mist",
    dusk = "Warm dusk",
    mesh = "Soft RGB mesh",
    aurora = "Aurora veil",
    harbor = "Harbor morning",
    grove = "Orchard grove"
  )
}

.glass_scene_names <- function() {
  names(glass_scenes())
}

.glass_normalize_scene <- function(scene) {
  if (is.null(scene) || (is.character(scene) && !nzchar(scene))) {
    return("default")
  }
  scene <- match.arg(scene, .glass_scene_names())
  scene
}

#' Scene picker for wallpaper packs
#'
#' Drop-in [shiny::selectInput()] that applies `window.shinyglass.setScene()`
#' immediately. Pair with [observe_glass_scene()] so the server stays in sync.
#'
#' @param inputId The `input` slot that will be used to access the value.
#' @param label Display label (or `NULL` for none).
#' @param selected Initially selected scene id.
#' @param choices Named character vector. Defaults to [glass_scenes()].
#' @param width The width of the input (e.g. `"100%"`).
#'
#' @return A [shiny::selectInput()] tag marked for client bindings.
#' @seealso [glass_scenes()], [observe_glass_scene()], [update_glass_theme()]
#' @export
glass_scene_input <- function(
    inputId = "glass_scene",
    label = "Wallpaper scene",
    selected = "default",
    choices = glass_scenes(),
    width = NULL) {
  stopifnot(is.character(inputId), length(inputId) == 1L, nzchar(inputId))
  ids <- unname(if (!is.null(names(choices))) names(choices) else choices)
  if (!all(ids %in% .glass_scene_names())) {
    stop(
      "`choices` names must be a subset of glass_scenes(): ",
      paste(.glass_scene_names(), collapse = ", "),
      call. = FALSE
    )
  }
  selected <- match.arg(selected, ids)
  # selectInput wants names=labels, values=ids
  if (!is.null(names(choices))) {
    sel_choices <- stats::setNames(names(choices), unname(choices))
  } else {
    sel_choices <- choices
  }

  sel <- shiny::selectInput(
    inputId = inputId,
    label = label,
    choices = sel_choices,
    selected = selected,
    width = width
  )
  .glass_mark_select(sel, inputId, "glass-scene-input", "data-glass-scene-input")
}

#' Observe [glass_scene_input()] on the server
#'
#' @param input,session Shiny `input` and `session` objects.
#' @param inputId Same id passed to [glass_scene_input()].
#' @return An [shiny::observeEvent()] observer (invisibly).
#' @export
observe_glass_scene <- function(input, session, inputId = "glass_scene") {
  if (missing(input) || missing(session)) {
    stop("`input` and `session` are required.", call. = FALSE)
  }
  stopifnot(is.character(inputId), length(inputId) == 1L, nzchar(inputId))
  shiny::observeEvent(
    input[[inputId]],
    {
      val <- input[[inputId]]
      if (is.null(val) || !nzchar(val) || !val %in% .glass_scene_names()) {
        return()
      }
      update_glass_theme(session, scene = val)
    },
    ignoreInit = TRUE,
    ignoreNULL = TRUE
  )
}

#' Stable Liquid Glass CSS tokens
#'
#' Catalog of public `--glass-*` custom properties. Override them with
#' [glass_add_tokens()] or [glass_theme()] `tokens=` without forking
#' `inst/scss/glass.scss`. Light/dark packs already ship as dual
#' `[data-glass-preset]` rules; prefer these variables over Sass `$glass-*`.
#'
#' Contrast floor (wallpaper / scenes): body ink is `#1d1d1f` (light) or
#' `#f5f5f7` (dark). User wallpapers are blurred and washed
#' (`--glass-wallpaper-wash`) so text sits on glass or a dimmed photo, not
#' raw imagery. Overlay menus use `--glass-menu-bg` (~86% light / ~88% dark).
#' Target 4.5:1 for body text and 3:1 for large UI chrome.
#'
#' @return A data frame with `token`, `css_var`, `category`, and
#'   `description`.
#' @export
#' @examples
#' head(glass_css_tokens())
#' glass_css_tokens()$css_var
glass_css_tokens <- function() {
  rows <- list(
    c("blur", "--glass-blur", "material", "Backdrop blur radius (CSS length)."),
    c("saturate", "--glass-saturate", "material", "Backdrop saturation."),
    c("radius", "--glass-radius", "material", "Corner radius for glass surfaces."),
    c("intensity", "--glass-intensity", "material", "Ultra Clear (0) to Tinted (1)."),
    c("bg", "--glass-bg", "surface", "Primary glass fill."),
    c("bg-hover", "--glass-bg-hover", "surface", "Hover / active glass fill."),
    c("bg-content", "--glass-bg-content", "surface", "Content-card fill (less chrome)."),
    c("border", "--glass-border", "surface", "Rim / hairline border."),
    c("border-outer", "--glass-border-outer", "surface", "Outer lip / side stroke."),
    c("shadow", "--glass-shadow", "surface", "Drop shadow color."),
    c("elevated-shadow", "--glass-elevated-shadow", "surface", "Floating chrome shadow."),
    c("highlight", "--glass-highlight", "surface", "Top-edge highlight."),
    c("specular", "--glass-specular", "surface", "Specular sheen."),
    c("lip", "--glass-lip", "surface", "Bottom-edge lip."),
    c("stroke-side", "--glass-stroke-side", "surface", "Side-edge stroke."),
    c("body-bg", "--glass-body-bg", "ink", "Page / panel paper color."),
    c("body-color", "--glass-body-color", "ink", "Primary body ink."),
    c("menu-bg", "--glass-menu-bg", "ink", "Opaque overlay / menu fill."),
    c("menu-color", "--glass-menu-color", "ink", "Overlay / menu ink."),
    c("page-bg", "--glass-page-bg", "scene", "Wallpaper gradient."),
    c("orb-1", "--glass-orb-1", "scene", "Ambient orb 1."),
    c("orb-2", "--glass-orb-2", "scene", "Ambient orb 2."),
    c("orb-3", "--glass-orb-3", "scene", "Ambient orb 3."),
    c("wallpaper", "--glass-wallpaper", "scene", "Optional photo url(...)."),
    c("wallpaper-wash", "--glass-wallpaper-wash", "scene", "Dim overlay on user photos."),
    c("plot-panel", "--glass-plot-panel", "content", "Opaque plot/table panel fill."),
    c("primary", "--glass-primary", "accent", "Accent / brand color."),
    c("accent", "--glass-accent", "accent", "Alias of --glass-primary."),
    c("on-primary", "--glass-on-primary", "accent", "Ink on solid accent fills.")
  )
  as.data.frame(
    do.call(rbind, lapply(rows, function(r) {
      data.frame(
        token = r[[1]],
        css_var = r[[2]],
        category = r[[3]],
        description = r[[4]],
        stringsAsFactors = FALSE
      )
    })),
    stringsAsFactors = FALSE
  )
}

#' Default CSS variable pack for a preset
#'
#' Values that [glass_theme()] compiles into `[data-glass-preset]`. Use as a
#' starting point for [glass_add_tokens()] overrides.
#'
#' @param preset `"light"` or `"dark"`.
#' @return A named list of CSS custom properties (names include `--`).
#' @export
#' @examples
#' names(glass_token_pack("light"))
#' glass_token_pack("dark")[["--glass-body-color"]]
glass_token_pack <- function(preset = c("light", "dark")) {
  preset <- match.arg(preset)
  tok <- .glass_tokens(preset, blur = 36, saturation = 200, radius = "1.5rem")
  list(
    `--glass-bg` = tok$glass_bg,
    `--glass-bg-hover` = tok$glass_bg_hover,
    `--glass-border` = tok$glass_border,
    `--glass-shadow` = tok$glass_shadow,
    `--glass-elevated-shadow` = tok$glass_elevated_shadow,
    `--glass-highlight` = tok$glass_highlight,
    `--glass-specular` = tok$glass_specular,
    `--glass-menu-bg` = tok$glass_menu_bg,
    `--glass-menu-color` = tok$glass_menu_color,
    `--glass-page-bg` = tok$page_bg,
    `--glass-orb-1` = tok$orb_1,
    `--glass-orb-2` = tok$orb_2,
    `--glass-orb-3` = tok$orb_3,
    `--glass-body-bg` = tok$body_bg,
    `--glass-body-color` = tok$body_color,
    `--glass-blur` = "36px",
    `--glass-saturate` = "200%",
    `--glass-radius` = "1.5rem",
    `--glass-intensity` = "0.45",
    `--glass-wallpaper-wash` = if (identical(preset, "dark")) {
      "rgba(0, 0, 0, 0.55)"
    } else {
      "rgba(245, 245, 247, 0.48)"
    },
    `--glass-plot-panel` = if (identical(preset, "dark")) {
      "rgba(28, 28, 30, 0.94)"
    } else {
      "rgba(245, 245, 247, 0.94)"
    }
  )
}

#' Override glass CSS tokens on a theme
#'
#' Injects `:root { --glass-*: ... }` without forking SCSS. Accepts public
#' token names from [glass_css_tokens()] (`"blur"`), CSS names
#' (`"--glass-blur"`), or `glass-blur`. Unknown names that already start
#' with `--` are passed through; others must be in the catalog.
#'
#' @param theme A [glass_theme()] / [bslib::bs_theme()] object.
#' @param tokens Named list or character vector of CSS values.
#' @param ... Additional `name = value` overrides.
#'
#' @return The theme, with an extra HTML dependency.
#' @export
#' @examples
#' th <- glass_theme()
#' th <- glass_add_tokens(th, list(blur = "28px", radius = "1.25rem"))
glass_add_tokens <- function(theme, tokens = list(), ...) {
  extra <- list(...)
  if (length(extra)) {
    tokens <- c(as.list(tokens), extra)
  }
  css <- .glass_tokens_to_css(tokens)
  if (!nzchar(css)) {
    return(theme)
  }
  pkg_version <- as.character(utils::packageVersion("shinyglass"))
  dep <- htmltools::htmlDependency(
    name = "shinyglass-tokens",
    version = pkg_version,
    src = system.file("js", package = "shinyglass"),
    head = paste0("<style data-shinyglass-tokens=\"true\">", css, "</style>"),
    all_files = FALSE
  )
  bslib::bs_bundle(theme, sass::sass_layer(html = dep))
}

.glass_resolve_token_name <- function(name) {
  name <- trimws(as.character(name[[1]]))
  if (!nzchar(name)) {
    stop("Token names must be non-empty.", call. = FALSE)
  }
  if (startsWith(name, "--")) {
    return(name)
  }
  if (startsWith(name, "glass-")) {
    return(paste0("--", name))
  }
  catalog <- glass_css_tokens()
  hit <- catalog$css_var[catalog$token == name]
  if (length(hit) == 1L) {
    return(hit)
  }
  # Allow --glass-foo via "glass_foo" / "foo-bar"
  guessed <- paste0("--glass-", gsub("_", "-", name))
  if (guessed %in% catalog$css_var) {
    return(guessed)
  }
  stop(
    "Unknown glass token '", name, "'. See glass_css_tokens().",
    call. = FALSE
  )
}

.glass_normalize_token_list <- function(tokens) {
  if (is.null(tokens) || length(tokens) == 0L) {
    return(list())
  }
  if (is.character(tokens) && !is.null(names(tokens))) {
    tokens <- as.list(tokens)
  }
  if (!is.list(tokens) || is.null(names(tokens)) || any(!nzchar(names(tokens)))) {
    stop("`tokens` must be a named list of CSS values.", call. = FALSE)
  }
  out <- list()
  for (nm in names(tokens)) {
    key <- .glass_resolve_token_name(nm)
    val <- tokens[[nm]]
    if (is.null(val) || (is.character(val) && !nzchar(val))) {
      next
    }
    val <- as.character(val[[1]])
    if (grepl("[<>]", val)) {
      stop("Token values must not contain markup.", call. = FALSE)
    }
    out[[key]] <- val
  }
  out
}

.glass_tokens_to_css <- function(tokens) {
  tokens <- .glass_normalize_token_list(tokens)
  if (!length(tokens)) {
    return("")
  }
  decls <- vapply(
    names(tokens),
    function(nm) sprintf("%s:%s;", nm, tokens[[nm]]),
    character(1)
  )
  paste0(":root{", paste(decls, collapse = ""), "}")
}

.glass_mark_select <- function(sel, inputId, extra_class, data_attr) {
  if (requireNamespace("htmltools", quietly = TRUE) &&
      exists("tagQuery", where = asNamespace("htmltools"), inherits = FALSE)) {
    tq <- htmltools::tagQuery(sel)$find("select")$addClass(extra_class)
    sel <- switch(
      data_attr,
      "data-glass-scene-input" = tq$addAttrs(`data-glass-scene-input` = inputId)$allTags(),
      "data-glass-plot-surface-input" = tq$addAttrs(`data-glass-plot-surface-input` = inputId)$allTags(),
      tq$addAttrs(`data-glass-input` = inputId)$allTags()
    )
  } else if (is.list(sel) && !is.null(sel$attribs)) {
    sel$attribs[[data_attr]] <- inputId
    sel$attribs$class <- paste(sel$attribs$class %||% "", paste0(extra_class, "-wrap"))
  }
  sel
}
