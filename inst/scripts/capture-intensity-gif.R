#!/usr/bin/env Rscript
# Capture marketing GIFs of glass_intensity_slider() with an obvious material delta.
#
# Enhancements vs production default screenshots:
#   * rich multi-orb wallpaper so glass blur/opacity reads
#   * content-aware tint off (clean Ultra Clear → Tinted fill progression)
#   * amplified alpha endpoints for capture only (not production defaults)
#   * solid value boxes / helper cards hidden; tight crop on sidebar + content
#   * light + dark loops
#
# From package root:
#   Rscript inst/scripts/capture-intensity-gif.R
#
# Requires: chromote, processx, curl, gifski

suppressPackageStartupMessages({
  library(processx)
  library(chromote)
  library(curl)
  library(gifski)
})

`%||%` <- function(x, y) {
  if (is.null(x) || !length(x) || (is.character(x) && !nzchar(x[[1]]))) y else x
}

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(sub("^--file=", "", file_arg[[1]]))
} else {
  "inst/scripts"
}
pkg_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/")
fig_dir <- file.path(pkg_root, "man", "figures")
app_path <- file.path(pkg_root, "inst", "examples", "intensity-slider-demo.R")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(app_path)) {
  stop("Missing intensity demo: ", app_path)
}

# Sweep 0 → 1 → 0 (hold ends)
up <- seq(0, 1, by = 0.06)
down <- seq(0.94, 0.06, by = -0.06)
intensity_path <- c(rep(0, 4L), up, rep(1, 4L), down)

STAGE_JS <- paste(
  c(
    "(function () {",
    "  var old = document.getElementById('shinyglass-gif-stage');",
    "  if (old) old.remove();",
    "  var style = document.createElement('style');",
    "  style.id = 'shinyglass-gif-stage';",
    "  style.textContent = [",
    "    'html, body { min-height: 100% !important; }',",
    "    'body {',",
    "    '  background-color: #1a1033 !important;',",
    "    '  background-image:',",
    "    '    radial-gradient(ellipse 90% 70% at 12% 18%, rgba(255,90,150,0.95) 0%, transparent 52%),',",
    "    '    radial-gradient(ellipse 80% 60% at 88% 12%, rgba(70,170,255,0.95) 0%, transparent 48%),',",
    "    '    radial-gradient(ellipse 70% 80% at 78% 88%, rgba(60,230,140,0.90) 0%, transparent 52%),',",
    "    '    radial-gradient(ellipse 55% 50% at 8% 85%, rgba(255,200,60,0.88) 0%, transparent 48%),',",
    "    '    radial-gradient(ellipse 50% 45% at 50% 50%, rgba(180,90,255,0.55) 0%, transparent 60%),',",
    "    '    linear-gradient(145deg, #2b0f4a 0%, #0d1b4a 42%, #0a3d3a 100%) !important;',",
    "    '  background-attachment: fixed !important;',",
    "    '  background-size: cover !important;',",
    "    '}',",
    "    '.bslib-value-box, .value-box, [class*=\"value-box\"] { display: none !important; }',",
    "    '.bslib-page-fill, .html-fill-container { padding: 0.55rem !important; gap: 0.55rem !important; }',",
    "    '.card, .well, .bslib-sidebar-layout > .sidebar, .form-control, .form-select, .btn {',",
    "    '  transition: background 0.08s linear, box-shadow 0.08s linear, border-color 0.08s linear, backdrop-filter 0.08s linear !important;',",
    "    '}'",
    "  ].join('\\n');",
    "  document.head.appendChild(style);",
    "",
    "  document.querySelectorAll('.card').forEach(function (card) {",
    "    if (card.querySelector('input.glass-intensity-range')) return;",
    "    if (card.querySelector('.shiny-plot-output')) return;",
    "    card.style.display = 'none';",
    "  });",
    "",
    "  if (window.shinyglass && window.shinyglass.setTint) window.shinyglass.setTint(false);",
    "  document.documentElement.classList.remove('glass-tint-active');",
    "  window.__shinyglassDisableTint = true;",
    "",
    "  window.__shinyglassGifSetIntensity = function (t) {",
    "    t = Number(t);",
    "    if (!isFinite(t)) t = 0.45;",
    "    if (t < 0) t = 0;",
    "    if (t > 1) t = 1;",
    "    // Move the thumb first (no events — input handlers would re-apply production fills).",
    "    var slider = document.querySelector('input.glass-intensity-range');",
    "    if (slider) {",
    "      slider.value = String(t);",
    "      slider.setAttribute('aria-valuenow', String(t));",
    "    }",
    "    document.querySelectorAll('.glass-intensity-slider').forEach(function (wrap) {",
    "      wrap.style.setProperty('--glass-intensity', String(t));",
    "      var minL = wrap.querySelector('.glass-intensity-end--min');",
    "      var maxL = wrap.querySelector('.glass-intensity-end--max');",
    "      if (minL) minL.classList.toggle('is-active', t < 0.35);",
    "      if (maxL) maxL.classList.toggle('is-active', t > 0.65);",
    "    });",
    "    // Production path for edge/highlight tokens, then overwrite fills with marketing alphas.",
    "    if (window.shinyglass && window.shinyglass.setIntensity) {",
    "      window.shinyglass.setIntensity(t);",
    "    }",
    "    var root = document.documentElement;",
    "    var dark = (root.dataset.glassPreset || 'light') === 'dark';",
    "    // Capture-only extremes so Ultra Clear vs Tinted is unmistakable on camera",
    "    var clearA = dark ? 0.04 : 0.03;",
    "    var tintA = dark ? 0.55 : 0.82;",
    "    var clearHover = dark ? 0.09 : 0.10;",
    "    var tintHover = dark ? 0.68 : 0.94;",
    "    var clearBorder = dark ? 0.16 : 0.28;",
    "    var tintBorder = dark ? 0.62 : 0.96;",
    "    var lerp = function (a, b, u) { return a + (b - a) * u; };",
    "    var a = lerp(clearA, tintA, t);",
    "    var ah = lerp(clearHover, tintHover, t);",
    "    var ab = lerp(clearBorder, tintBorder, t);",
    "    var blurScale = lerp(1.08, 1.42, t);",
    "    var fill = '255, 255, 255';",
    "    var rgba = function (alpha) {",
    "      return 'rgba(' + fill + ', ' + alpha.toFixed(4) + ')';",
    "    };",
    "    root.style.setProperty('--glass-bg', rgba(a));",
    "    root.style.setProperty('--glass-bg-hover', rgba(ah));",
    "    root.style.setProperty('--glass-bg-content', rgba(Math.min(1, a * (dark ? 1.15 : 1.1))));",
    "    root.style.setProperty('--glass-bg-content-hover', rgba(Math.min(1, ah * 1.05)));",
    "    root.style.setProperty('--glass-border', rgba(ab));",
    "    root.style.setProperty('--glass-rim', rgba(Math.min(1, ab * 1.08)));",
    "    root.style.setProperty('--glass-menu-bg', rgba(lerp(dark ? 0.40 : 0.50, dark ? 0.94 : 0.97, t)));",
    "    var baseBlur = parseFloat(getComputedStyle(root).getPropertyValue('--glass-blur-base'));",
    "    if (!isFinite(baseBlur) || baseBlur <= 0) baseBlur = 36;",
    "    root.style.setProperty('--glass-blur', (baseBlur * blurScale).toFixed(1) + 'px');",
    "    root.dataset.glassIntensity = String(t);",
    "    root.style.setProperty('--glass-intensity', String(t));",
    "    window.scrollTo(0, 0);",
    "    return getComputedStyle(root).getPropertyValue('--glass-bg').trim();",
    "  };",
    "  return typeof window.__shinyglassGifSetIntensity;",
    "})();"
  ),
  collapse = "\n"
)

parse_alpha <- function(rgba) {
  m <- regmatches(rgba, regexec(",\\s*([0-9.]+)\\s*\\)\\s*$", rgba %||% ""))[[1]]
  if (length(m) < 2) return(NA_real_)
  as.numeric(m[[2]])
}

capture_preset_gif <- function(preset, out_name, port) {
  out_gif <- file.path(fig_dir, out_name)
  frame_dir <- tempfile(paste0("intensity-gif-", preset, "-"))
  dir.create(frame_dir, recursive = TRUE)
  on.exit(unlink(frame_dir, recursive = TRUE), add = TRUE)

  url <- sprintf("http://127.0.0.1:%d", port)
  launch <- sprintf(
    paste(
      "pkgload::load_all(%s, quiet=TRUE);",
      "message('shinyglass intensity GIF capture (%s)');",
      "shiny::runApp(%s, host='127.0.0.1', port=%d, launch.browser=FALSE)"
    ),
    deparse(pkg_root),
    preset,
    deparse(app_path),
    port
  )

  proc <- processx::process$new(
    Sys.which("Rscript"),
    c("-e", launch),
    env = c(Sys.getenv(), SHINYGLASS_PRESET = preset),
    stdout = "|",
    stderr = "|"
  )
  on.exit(
    {
      if (proc$is_alive()) try(proc$kill(tree = TRUE), silent = TRUE)
    },
    add = TRUE
  )

  ready <- FALSE
  for (i in seq_len(90)) {
    if (!proc$is_alive()) {
      stop("App exited early (", preset, "):\n", proc$read_all_error())
    }
    ok <- tryCatch(
      curl::curl_fetch_memory(url)$status_code == 200L,
      error = function(e) FALSE
    )
    if (ok) {
      ready <- TRUE
      break
    }
    Sys.sleep(0.4)
  }
  if (!ready) stop("Timed out waiting for ", url)

  b <- ChromoteSession$new()
  on.exit(try(b$close(), silent = TRUE), add = TRUE)

  b$set_viewport_size(width = 980L, height = 560L)
  b$go_to(url)
  Sys.sleep(2.2)

  ready_ui <- b$Runtime$evaluate(
    expression = paste(
      "new Promise((resolve) => {",
      "  const deadline = Date.now() + 60000;",
      "  const check = () => {",
      "    const slider = document.querySelector('input.glass-intensity-range');",
      "    const label = (document.body && document.body.innerText) || '';",
      "    const isIntensityApp = /Liquid Glass intensity|Ultra Clear/i.test(label);",
      "    const img = document.querySelector('.shiny-plot-output img');",
      "    const plotOk = img && img.complete && img.naturalWidth > 0;",
      "    if (slider && isIntensityApp && plotOk) {",
      "      resolve({ ok: true, text: label.slice(0, 80) });",
      "      return;",
      "    }",
      "    if (Date.now() > deadline) {",
      "      resolve({ ok: false, hasSlider: !!slider, isIntensityApp: isIntensityApp,",
      "                plotOk: !!plotOk, text: label.slice(0, 120) });",
      "      return;",
      "    }",
      "    setTimeout(check, 250);",
      "  };",
      "  check();",
      "});"
    ),
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = 65000
  )
  info <- ready_ui$result$value
  if (!isTRUE(info$ok)) {
    stop(
      "Intensity demo not ready (", preset, "): ",
      paste(names(info), info, sep = "=", collapse = ", ")
    )
  }
  message("[", preset, "] App ready")

  staged <- b$Runtime$evaluate(expression = STAGE_JS, returnByValue = TRUE)
  if (!identical(staged$result$value, "function")) {
    stop("Failed to install GIF stage helper: ", staged$result$value %||% "NULL")
  }

  b$Runtime$evaluate(
    expression = sprintf(
      "if (window.shinyglass && window.shinyglass.setPreset) window.shinyglass.setPreset(%s);",
      deparse(preset)
    )
  )
  Sys.sleep(0.3)

  bg0 <- b$Runtime$evaluate(
    expression = "window.__shinyglassGifSetIntensity(0)",
    returnByValue = TRUE
  )$result$value
  bg1 <- b$Runtime$evaluate(
    expression = "window.__shinyglassGifSetIntensity(1)",
    returnByValue = TRUE
  )$result$value
  a0 <- parse_alpha(bg0)
  a1 <- parse_alpha(bg1)
  message("[", preset, "] capture alpha clear=", a0, " tinted=", a1, " delta=", a1 - a0)
  if (!is.finite(a0) || !is.finite(a1) || (a1 - a0) < 0.35) {
    stop("Amplified intensity delta too small for marketing GIF (", preset, ")")
  }

  frame_paths <- character(length(intensity_path))
  for (i in seq_along(intensity_path)) {
    t <- intensity_path[[i]]
    b$Runtime$evaluate(
      expression = sprintf(
        "window.__shinyglassGifSetIntensity(%s)",
        format(t, scientific = FALSE)
      )
    )
    Sys.sleep(0.10)
    fp <- file.path(frame_dir, sprintf("frame-%03d.png", i))
    b$screenshot(filename = fp)
    frame_paths[[i]] <- fp
    if (i == 1L || i == length(intensity_path) || abs(t - 0) < 1e-9 || abs(t - 1) < 1e-9) {
      message(sprintf("[%s] frame %02d/%02d intensity=%.2f", preset, i, length(intensity_path), t))
    }
  }

  gifski::gifski(
    png_files = frame_paths,
    gif_file = out_gif,
    width = 860L,
    height = 490L,
    delay = 1 / 11,
    loop = TRUE,
    progress = TRUE
  )

  sz <- file.info(out_gif)$size
  message(
    "Wrote ", out_gif,
    " (", round(sz / 1024^2, 2), " MiB, ",
    length(frame_paths), " frames)"
  )
  if (sz > 8 * 1024^2) {
    warning("GIF larger than 8 MiB: ", out_gif, call. = FALSE)
  }
  invisible(out_gif)
}

capture_preset_gif("light", "intensity-slider.gif", port = 13921L)
capture_preset_gif("dark", "intensity-slider-dark.gif", port = 13922L)

message("Done.")
