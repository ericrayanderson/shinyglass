#!/usr/bin/env Rscript
# Capture dark-preset screenshots for README / pkgdown.

suppressPackageStartupMessages({
  library(processx)
  library(chromote)
  library(curl)
})

capture_app <- function(app_path, out_path, port = 3847L, width = 1400L, height = 1100L,
                        env = character()) {
  url <- sprintf("http://127.0.0.1:%d", port)
  proc <- processx::process$new(
    command = normalizePath(Sys.which("Rscript")),
    args = c(
      "-e",
      sprintf(
        "shiny::runApp('%s', host='127.0.0.1', port=%d, launch.browser=FALSE)",
        gsub("'", "\\\\'", normalizePath(app_path, winslash = "/")),
        port
      )
    ),
    env = c(Sys.getenv(), env),
    stdout = "|",
    stderr = "|"
  )
  on.exit(if (proc$is_alive()) proc$kill(), add = TRUE)

  ready <- FALSE
  for (i in seq_len(60)) {
    if (!proc$is_alive()) {
      stop("App exited early:\n", proc$read_all_error())
    }
    resp <- tryCatch(curl::curl_fetch_memory(url), error = function(e) NULL)
    if (!is.null(resp) && resp$status_code == 200) {
      ready <- TRUE
      break
    }
    Sys.sleep(0.5)
  }
  if (!ready) {
    stop("Timed out waiting for ", url)
  }

  b <- chromote::ChromoteSession$new()
  on.exit(b$close(), add = TRUE)
  b$set_viewport_size(width = width, height = height)
  b$go_to(url)
  Sys.sleep(6)
  b$screenshot(filename = out_path)
  message("Saved ", out_path)
}

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(sub("^--file=", "", file_arg[1]))
} else {
  "."
}
pkg_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/")
fig_dir <- file.path(pkg_root, "man", "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

demo_lines <- readLines(file.path(pkg_root, "inst", "examples", "demo-app.R"))
demo_lines <- sub("glass_theme\\(\\)", "glass_theme(preset = \"dark\")", demo_lines)
tmp_demo <- tempfile(fileext = ".R")
writeLines(demo_lines, tmp_demo)
on.exit(unlink(tmp_demo), add = TRUE)

capture_app(tmp_demo, file.path(fig_dir, "shinyglass-demo-dark.png"), port = 3847L)
capture_app(
  file.path(pkg_root, "inst", "examples", "apple-glass-reference.R"),
  file.path(fig_dir, "apple-glass-reference-dark.png"),
  port = 3848L,
  env = c(SHINYGLASS_PRESET = "dark")
)