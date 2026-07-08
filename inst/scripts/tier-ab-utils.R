# Helpers for tier A/B visual coverage targets (SuperZIP, shinyWidgets, bs4Dash).

# Compile glass.scss alone (no Bootstrap reboot) so AdminLTE/bs4Dash layouts
# keep working while still receiving glass surface rules.
compile_glass_overlay_css <- function(preset = c("light", "dark"), primary = "#007AFF") {
  preset <- match.arg(preset)
  if (!requireNamespace("sass", quietly = TRUE)) {
    stop("sass is required to compile glass overlay CSS", call. = FALSE)
  }
  if (!requireNamespace("shinyglass", quietly = TRUE)) {
    stop("shinyglass must be loaded", call. = FALSE)
  }

  # Mirror tokens from shinyglass::: .glass_tokens without relying on :::
  tokens <- if (identical(preset, "light")) {
    list(
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
      orb_3 = "rgba(255, 149, 0, 0.16)",
      body_color = "#1d1d1f"
    )
  } else {
    list(
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
      orb_3 = "rgba(255, 159, 10, 0.22)",
      body_color = "#f5f5f7"
    )
  }

  defaults <- list(
    primary = primary,
    success = "#34C759",
    danger = "#FF3B30",
    warning = "#FF9500",
    info = "#5AC8FA",
    "body-color" = tokens$body_color,
    prefix = "bs-",
    "glass-bg" = tokens$glass_bg,
    "glass-bg-hover" = tokens$glass_bg_hover,
    "glass-border" = tokens$glass_border,
    "glass-shadow" = tokens$glass_shadow,
    "glass-elevated-shadow" = tokens$glass_elevated_shadow,
    "glass-blur" = "28px",
    "glass-saturate" = "200%",
    "glass-radius" = "1.25rem",
    "glass-highlight" = tokens$glass_highlight,
    "glass-specular" = tokens$glass_specular,
    "glass-menu-bg" = tokens$glass_menu_bg,
    "glass-menu-color" = tokens$glass_menu_color,
    "glass-page-bg" = tokens$page_bg,
    "glass-orb-1" = tokens$orb_1,
    "glass-orb-2" = tokens$orb_2,
    "glass-orb-3" = tokens$orb_3
  )

  scss <- system.file("scss", "glass.scss", package = "shinyglass")
  if (!nzchar(scss) || !file.exists(scss)) {
    stop("glass.scss not found in shinyglass package", call. = FALSE)
  }

  # Stub Bootstrap mixins used by glass.scss so we can compile without BS reboot
  bootstrap_stubs <- "
@mixin media-breakpoint-up($name) {
  @if $name == sm {
    @media (min-width: 576px) { @content; }
  } @else if $name == md {
    @media (min-width: 768px) { @content; }
  } @else if $name == lg {
    @media (min-width: 992px) { @content; }
  } @else if $name == xl {
    @media (min-width: 1200px) { @content; }
  } @else {
    @content;
  }
}
"

  sass::sass(list(defaults, bootstrap_stubs, sass::sass_file(scss)))
}

# htmlDependency with overlay CSS + shiny-glass.js (no Bootstrap 5 reboot).
glass_overlay_dependency <- function(preset = c("light", "dark"), primary = "#007AFF") {
  preset <- match.arg(preset)
  css <- compile_glass_overlay_css(preset = preset, primary = primary)
  tmp <- tempfile("shinyglass-overlay-")
  dir.create(tmp)
  writeLines(css, file.path(tmp, "glass-overlay.css"))

  js_src <- system.file("js", package = "shinyglass")
  if (nzchar(js_src) && file.exists(file.path(js_src, "shiny-glass.js"))) {
    file.copy(file.path(js_src, "shiny-glass.js"), file.path(tmp, "shiny-glass.js"))
  }

  htmltools::htmlDependency(
    name = "shinyglass-overlay",
    version = as.character(utils::packageVersion("shinyglass")),
    src = tmp,
    stylesheet = "glass-overlay.css",
    script = if (file.exists(file.path(tmp, "shiny-glass.js"))) "shiny-glass.js" else NULL,
    all_files = FALSE
  )
}

tier_ab_pkg_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg)) {
    return(normalizePath(
      file.path(dirname(sub("^--file=", "", file_arg[1])), "..", ".."),
      winslash = "/"
    ))
  }
  normalizePath(file.path(getwd(), "."), winslash = "/")
}

# Locate or shallow-clone rstudio/shiny-examples for SuperZIP.
resolve_superzip_dir <- function(pkg_root = tier_ab_pkg_root()) {
  candidates <- c(
    Sys.getenv("SHINYGLASS_SUPERZIP_DIR", unset = ""),
    {
      ex <- Sys.getenv("SHINYGLASS_EXAMPLES_DIR", unset = "")
      if (nzchar(ex)) file.path(ex, "063-superzip-example") else ""
    },
    file.path(dirname(pkg_root), "shiny-examples-glass-test", "063-superzip-example"),
    file.path(dirname(pkg_root), "shiny-examples", "063-superzip-example"),
    file.path(pkg_root, "inst", "external", "shiny-examples", "063-superzip-example")
  )
  candidates <- candidates[nzchar(candidates)]
  for (p in candidates) {
    if (dir.exists(p) && file.exists(file.path(p, "ui.R"))) {
      return(normalizePath(p, winslash = "/"))
    }
  }

  cache <- file.path(pkg_root, "inst", "external", "shiny-examples")
  target <- file.path(cache, "063-superzip-example")
  if (dir.exists(target) && file.exists(file.path(target, "ui.R"))) {
    return(normalizePath(target, winslash = "/"))
  }

  message("Cloning rstudio/shiny-examples (depth=1) for SuperZIP…")
  dir.create(cache, recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile("shiny-examples-")
  status <- system2(
    "git",
    c(
      "clone", "--depth", "1", "--filter=blob:none", "--sparse",
      "https://github.com/rstudio/shiny-examples.git",
      tmp
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  if (!is.null(attr(status, "status")) && attr(status, "status") != 0L) {
    stop("git clone failed:\n", paste(status, collapse = "\n"), call. = FALSE)
  }
  system2(
    "git",
    c("-C", tmp, "sparse-checkout", "set", "063-superzip-example"),
    stdout = TRUE,
    stderr = TRUE
  )
  dir.create(cache, recursive = TRUE, showWarnings = FALSE)
  if (dir.exists(target)) unlink(target, recursive = TRUE)
  file.rename(file.path(tmp, "063-superzip-example"), target)
  unlink(tmp, recursive = TRUE)
  if (!file.exists(file.path(target, "ui.R"))) {
    stop("SuperZIP checkout incomplete at ", target, call. = FALSE)
  }
  normalizePath(target, winslash = "/")
}

resolve_shinywidgets_gallery_dir <- function() {
  path <- system.file("examples", "shinyWidgets", package = "shinyWidgets")
  if (!nzchar(path) || !dir.exists(path)) {
    stop(
      "shinyWidgets gallery not found. Install shinyWidgets:\n",
      "  install.packages(\"shinyWidgets\")",
      call. = FALSE
    )
  }
  normalizePath(path, winslash = "/")
}

resolve_bs4dash_demo_path <- function(pkg_root = tier_ab_pkg_root()) {
  path <- file.path(pkg_root, "inst", "examples", "bs4dash-glass-demo.R")
  if (!file.exists(path)) {
    # When installed as a package
    alt <- system.file("examples", "bs4dash-glass-demo.R", package = "shinyglass")
    if (nzchar(alt) && file.exists(alt)) return(normalizePath(alt, winslash = "/"))
    stop("bs4dash-glass-demo.R not found", call. = FALSE)
  }
  normalizePath(path, winslash = "/")
}

# Stage a runnable app dir for each tier-AB target.
prepare_tier_ab_app <- function(id, pkg_root = tier_ab_pkg_root()) {
  id <- match.arg(id, c("superzip", "shinywidgets-gallery", "bs4dash-demo"))

  if (identical(id, "superzip")) {
    src <- resolve_superzip_dir(pkg_root)
    prep <- prepare_patched_app_dir(src)
    if (!isTRUE(prep$ok)) {
      return(list(ok = FALSE, reason = prep$reason, id = id, tier = "A"))
    }
    return(list(
      ok = TRUE, id = id, tier = "A",
      dir = prep$dir, label = "SuperZIP (leaflet + DT + absolutePanel)",
      launch = "dir"
    ))
  }

  if (identical(id, "shinywidgets-gallery")) {
    if (!requireNamespace("shinyWidgets", quietly = TRUE)) {
      return(list(ok = FALSE, reason = "shinyWidgets not installed", id = id, tier = "A"))
    }
    src <- resolve_shinywidgets_gallery_dir()
    prep <- prepare_patched_app_dir(src)
    if (!isTRUE(prep$ok)) {
      return(list(ok = FALSE, reason = prep$reason, id = id, tier = "A"))
    }
    return(list(
      ok = TRUE, id = id, tier = "A",
      dir = prep$dir, label = "shinyWidgets gallery (dense custom inputs)",
      launch = "dir"
    ))
  }

  # bs4Dash: copy demo as app.R; SHINYGLASS_PKG_ROOT points at package sources
  if (!requireNamespace("bs4Dash", quietly = TRUE)) {
    return(list(ok = FALSE, reason = "bs4Dash not installed", id = id, tier = "B"))
  }
  demo <- resolve_bs4dash_demo_path(pkg_root)
  tmp <- tempfile("glass-bs4dash-")
  dir.create(tmp, recursive = TRUE)
  file.copy(demo, file.path(tmp, "app.R"), overwrite = TRUE)
  list(
    ok = TRUE, id = id, tier = "B",
    dir = tmp, label = "bs4Dash minimal dashboard (AdminLTE3)",
    launch = "dir",
    env = c(SHINYGLASS_PKG_ROOT = pkg_root)
  )
}
