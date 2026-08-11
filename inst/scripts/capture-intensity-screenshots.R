#!/usr/bin/env Rscript
# Capture README intensity-slider figures (balanced / clear / tinted × light/dark).
#
# From package root:
#   Rscript inst/scripts/capture-intensity-screenshots.R

suppressPackageStartupMessages({
  library(processx)
  library(chromote)
  library(curl)
})

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

wait_ready <- function(session, timeout = 45) {
  js <- sprintf(
    "new Promise((resolve) => {
      const deadline = Date.now() + %d;
      const check = () => {
        const img = document.querySelector('.shiny-plot-output img, #hero_plot img');
        const plotOk = img && img.complete && img.naturalWidth > 0;
        const slider = document.querySelector('input.glass-intensity-range');
        const vb = document.querySelector('#vb_look, .value-box, .bslib-value-box');
        const bound = document.querySelectorAll('.shiny-bound-input').length > 0;
        if (bound && plotOk && slider && vb) { resolve(true); return; }
        if (Date.now() > deadline) { resolve(false); return; }
        setTimeout(check, 250);
      };
      check();
    });",
    timeout * 1000L
  )
  session$Runtime$evaluate(
    expression = js,
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = (timeout + 5) * 1000
  )
}

set_intensity <- function(session, value) {
  session$Runtime$evaluate(
    expression = sprintf(
      "(function() {
        const t = %s;
        if (window.shinyglass && window.shinyglass.setIntensity) {
          window.shinyglass.setIntensity(t);
        }
        const slider = document.querySelector('input.glass-intensity-range');
        if (slider) {
          slider.value = String(t);
          slider.dispatchEvent(new Event('input', { bubbles: true }));
          slider.dispatchEvent(new Event('change', { bubbles: true }));
        }
        return {
          intensity: window.shinyglass ? window.shinyglass.getIntensity() : null,
          bg: getComputedStyle(document.documentElement).getPropertyValue('--glass-bg').trim()
        };
      })()",
      format(value, scientific = FALSE)
    ),
    returnByValue = TRUE
  )
}

start_app <- function(preset, port) {
  url <- sprintf("http://127.0.0.1:%d", port)
  launch_expr <- sprintf(
    paste(
      "if (requireNamespace('pkgload', quietly = TRUE)) {",
      "  pkgload::load_all(%s, quiet = TRUE)",
      "} else {",
      "  devtools::load_all(%s, quiet = TRUE)",
      "};",
      "shiny::runApp(%s, host='127.0.0.1', port=%d, launch.browser=FALSE)",
      sep = " "
    ),
    deparse(pkg_root),
    deparse(pkg_root),
    deparse(app_path),
    port
  )
  proc <- processx::process$new(
    Sys.which("Rscript"),
    c("-e", launch_expr),
    env = c(Sys.getenv(), SHINYGLASS_PRESET = preset),
    stdout = "|",
    stderr = "|"
  )
  ready <- FALSE
  for (i in seq_len(90)) {
    if (!proc$is_alive()) {
      stop("App exited early:\n", proc$read_all_error())
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
  if (!ready) {
    if (proc$is_alive()) proc$kill()
    stop("Timed out waiting for ", url)
  }
  list(proc = proc, url = url)
}

capture_shot <- function(preset, intensity, out_name, port) {
  out_path <- file.path(fig_dir, out_name)
  app <- start_app(preset, port)
  on.exit(
    {
      if (app$proc$is_alive()) {
        try(app$proc$kill(tree = TRUE), silent = TRUE)
      }
    },
    add = TRUE
  )

  b <- ChromoteSession$new()
  on.exit(try(b$close(), silent = TRUE), add = TRUE)
  b$set_viewport_size(width = 1400L, height = 900L)
  b$go_to(app$url)
  Sys.sleep(2)
  ready <- tryCatch(wait_ready(b, timeout = 50), error = function(e) NULL)
  if (!isTRUE(ready$result$value)) {
    warning("UI readiness wait returned false for ", out_name, "; capturing anyway")
  }
  Sys.sleep(0.8)

  # Let content-aware tint sample the plot, then set intensity (exercises tint path)
  Sys.sleep(0.6)
  info <- set_intensity(b, intensity)
  Sys.sleep(0.7)
  # Re-apply in case a late tint pass overwrote fills before the fix
  set_intensity(b, intensity)
  Sys.sleep(0.35)

  b$Runtime$evaluate(expression = "window.scrollTo(0, 0);")
  b$screenshot(filename = out_path)

  bg <- info$result$value$bg %||% "?"
  message(
    "Saved ", out_path,
    " | preset=", preset,
    " intensity=", intensity,
    " bg=", bg
  )
  invisible(out_path)
}

`%||%` <- function(x, y) {
  if (is.null(x) || !length(x) || (is.character(x) && !nzchar(x[[1]]))) y else x
}

# Balanced default (0.45), Ultra Clear (0.10), Tinted (0.90) — match prior README set
jobs <- list(
  list(preset = "light", intensity = 0.45, file = "intensity-slider.png", port = 3860L),
  list(preset = "dark", intensity = 0.45, file = "intensity-slider-dark.png", port = 3861L),
  list(preset = "light", intensity = 0.10, file = "intensity-slider-clear.png", port = 3862L),
  list(preset = "light", intensity = 0.90, file = "intensity-slider-tinted.png", port = 3863L),
  list(preset = "dark", intensity = 0.10, file = "intensity-slider-dark-clear.png", port = 3864L),
  list(preset = "dark", intensity = 0.90, file = "intensity-slider-dark-tinted.png", port = 3865L)
)

for (job in jobs) {
  capture_shot(job$preset, job$intensity, job$file, job$port)
}

message("Done. Intensity screenshots written to ", fig_dir)
