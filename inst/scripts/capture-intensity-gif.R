#!/usr/bin/env Rscript
# Capture a GIF of glass_intensity_slider() sweeping Ultra Clear → Tinted → Clear.
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
out_gif <- file.path(fig_dir, "intensity-slider.gif")
frame_dir <- tempfile("intensity-gif-")
dir.create(frame_dir, recursive = TRUE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# High port to avoid clashing with other local demo captures
port <- 13917L
url <- sprintf("http://127.0.0.1:%d", port)

if (!file.exists(app_path)) {
  stop("Missing intensity demo: ", app_path)
}

launch <- sprintf(
  paste(
    "pkgload::load_all(%s, quiet=TRUE);",
    "message('shinyglass intensity GIF capture starting');",
    "shiny::runApp(%s, host='127.0.0.1', port=%d, launch.browser=FALSE)"
  ),
  deparse(pkg_root),
  deparse(app_path),
  port
)

proc <- processx::process$new(
  Sys.which("Rscript"),
  c("-e", launch),
  env = c(Sys.getenv(), SHINYGLASS_PRESET = "light"),
  stdout = "|",
  stderr = "|"
)
on.exit(
  {
    if (proc$is_alive()) try(proc$kill(tree = TRUE), silent = TRUE)
    unlink(frame_dir, recursive = TRUE)
  },
  add = TRUE
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
if (!ready) stop("Timed out waiting for ", url)

b <- ChromoteSession$new()
on.exit(try(b$close(), silent = TRUE), add = TRUE)

# Wide enough to show sidebar + chart; height tight for GIF size
b$set_viewport_size(width = 1100L, height = 720L)
b$go_to(url)
Sys.sleep(2.5)

# Wait for intensity slider + plot (hard-fail if wrong app)
ready_ui <- b$Runtime$evaluate(
  expression = paste(
    "new Promise((resolve) => {",
    "  const deadline = Date.now() + 60000;",
    "  const check = () => {",
    "    const slider = document.querySelector('input.glass-intensity-range');",
    "    const label = document.body && document.body.innerText || '';",
    "    const isIntensityApp = /Liquid Glass intensity|Ultra Clear/i.test(label);",
    "    const img = document.querySelector('.shiny-plot-output img');",
    "    const plotOk = img && img.complete && img.naturalWidth > 0;",
    "    if (slider && isIntensityApp && plotOk) {",
    "      resolve({ ok: true, text: label.slice(0, 80) });",
    "      return;",
    "    }",
    "    if (Date.now() > deadline) {",
    "      resolve({",
    "        ok: false,",
    "        hasSlider: !!slider,",
    "        isIntensityApp: isIntensityApp,",
    "        plotOk: !!plotOk,",
    "        text: label.slice(0, 120)",
    "      });",
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
    "Intensity demo not ready for GIF capture: ",
    paste(names(info), info, sep = "=", collapse = ", ")
  )
}
message("App ready: ", info$text %||% "")
Sys.sleep(0.8)

# Let content-aware tint sample the plot once
b$Runtime$evaluate(expression = "
  if (window.shinyglass && window.shinyglass.setTint) {
    window.shinyglass.setTint(true);
  }
")
Sys.sleep(0.8)

set_intensity <- function(t) {
  b$Runtime$evaluate(
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
        window.scrollTo(0, 0);
        return t;
      })()",
      format(t, scientific = FALSE)
    ),
    returnByValue = TRUE
  )
}

# Sweep 0 → 1 → 0 for a seamless loop (hold ends briefly)
up <- seq(0, 1, by = 0.05)
down <- seq(0.95, 0.05, by = -0.05)
hold_start <- rep(0, 3)
hold_end <- rep(1, 3)
path <- c(hold_start, up, hold_end, down)

frame_paths <- character(length(path))
for (i in seq_along(path)) {
  t <- path[[i]]
  set_intensity(t)
  # Allow CSS transitions / glass recompute to settle a bit
  Sys.sleep(0.12)
  fp <- file.path(frame_dir, sprintf("frame-%03d.png", i))
  b$screenshot(filename = fp)
  frame_paths[[i]] = fp
  message(sprintf("frame %02d/%02d intensity=%.2f", i, length(path), t))
}

# ~12 fps: smooth enough, keeps file size down
gifski::gifski(
  png_files = frame_paths,
  gif_file = out_gif,
  width = 900L,
  height = 590L,
  delay = 1 / 12,
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
  warning(
    "GIF is larger than 8 MiB; consider fewer frames or smaller width.",
    call. = FALSE
  )
}
