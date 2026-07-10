#!/usr/bin/env Rscript
# Recapture shinyglass-demo.png (+ dark) for README / promo review.

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
desk <- path.expand("~/Desktop")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

capture_demo <- function(preset = c("light", "dark"), out_path, port) {
  preset <- match.arg(preset)
  app_src <- file.path(pkg_root, "inst", "examples", "demo-app.R")
  lines <- readLines(app_src, warn = FALSE)

  if (identical(preset, "dark")) {
    lines <- sub("glass_theme\\(\\)", "glass_theme(preset = \"dark\")", lines)
  }

  boot <- c(
    sprintf("pkgload::load_all(%s, quiet = TRUE)", deparse(pkg_root)),
    ""
  )
  tmp <- tempfile("demo-", fileext = ".R")
  writeLines(c(boot, lines), tmp)

  url <- sprintf("http://127.0.0.1:%d", port)
  proc <- processx::process$new(
    Sys.which("Rscript"),
    c(
      "-e",
      sprintf(
        "shiny::runApp(%s, host='127.0.0.1', port=%d, launch.browser=FALSE)",
        deparse(tmp),
        port
      )
    ),
    stdout = "|",
    stderr = "|",
    env = c(Sys.getenv(), SHINYGLASS_PRESET = preset)
  )
  on.exit({
    if (proc$is_alive()) {
      try(proc$kill(tree = TRUE), silent = TRUE)
    }
    unlink(tmp)
  }, add = TRUE)

  ready <- FALSE
  for (i in seq_len(80)) {
    if (!proc$is_alive()) {
      stop("App died for ", preset, ":\n", proc$read_all_error())
    }
    ok <- tryCatch(
      curl::curl_fetch_memory(url)$status_code == 200L,
      error = function(e) FALSE
    )
    if (ok) {
      ready <- TRUE
      break
    }
    Sys.sleep(0.35)
  }
  if (!ready) {
    stop("Timed out starting ", preset, " demo")
  }

  b <- ChromoteSession$new()
  on.exit(try(b$close(), silent = TRUE), add = TRUE)
  b$go_to(url)
  b$set_viewport_size(width = 1200L, height = 720L)

  ready_ui <- b$Runtime$evaluate(
    expression = paste(
      "new Promise((resolve) => {",
      "  const deadline = Date.now() + 45000;",
      "  const check = () => {",
      "    const img = document.querySelector('#dist_plot img, .shiny-plot-output img');",
      "    const plotOk = img && img.complete && img.naturalWidth > 0;",
      "    const chip = document.querySelector('.irs-single');",
      "    const chipOk = chip && chip.offsetParent !== null && chip.textContent.trim().length > 0;",
      "    const bound = document.querySelectorAll('.shiny-bound-input').length > 0;",
      "    if (bound && plotOk && chipOk) { resolve(true); return; }",
      "    if (Date.now() > deadline) { resolve(false); return; }",
      "    setTimeout(check, 250);",
      "  };",
      "  check();",
      "});"
    ),
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = 50000
  )
  if (!isTRUE(ready_ui$result$value)) {
    warning("UI readiness wait returned false for ", preset, "; capturing anyway")
  }
  Sys.sleep(0.9)

  chip_txt <- b$Runtime$evaluate(
    expression = "document.querySelector('.irs-single')?.textContent || ''",
    returnByValue = TRUE
  )$result$value
  chip_color <- b$Runtime$evaluate(
    expression = paste(
      "(function() {",
      "  const el = document.querySelector('.irs-single');",
      "  if (!el) return null;",
      "  const s = getComputedStyle(el);",
      "  return { color: s.color, bg: s.backgroundColor, text: el.textContent.trim() };",
      "})()"
    ),
    returnByValue = TRUE
  )$result$value

  b$screenshot(out_path)
  message(
    "Saved ", out_path,
    " | chip=", chip_txt,
    " color=", chip_color$color %||% "?",
    " bg=", chip_color$bg %||% "?"
  )
  invisible(list(path = out_path, chip = chip_color))
}

`%||%` <- function(x, y) if (is.null(x) || !length(x) || identical(x, "")) y else x

light <- capture_demo("light", file.path(fig_dir, "shinyglass-demo.png"), 3851L)
dark <- capture_demo("dark", file.path(fig_dir, "shinyglass-demo-dark.png"), 3852L)

file.copy(light$path, file.path(desk, "shinyglass-demo.png"), overwrite = TRUE)
file.copy(dark$path, file.path(desk, "shinyglass-demo-dark.png"), overwrite = TRUE)

message("Also copied to Desktop")
print(list(light = light$chip, dark = dark$chip))
