#!/usr/bin/env Rscript
# Capture UI-only gallery screenshots (no Shiny showcase code panels).
#
# Usage:
#   Rscript capture-gallery.R [shiny-examples-dir]
#
# Writes to man/figures/gallery/. Requires chromote, processx, curl, shinyglass.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
pkg_root <- if (length(file_arg)) {
  normalizePath(
    file.path(dirname(sub("^--file=", "", file_arg[1])), "..", ".."),
    winslash = "/"
  )
} else {
  normalizePath(getwd(), winslash = "/")
}

trailing <- commandArgs(trailingOnly = TRUE)
examples_dir <- if (length(trailing) >= 1) {
  normalizePath(trailing[[1]], winslash = "/", mustWork = TRUE)
} else {
  Sys.getenv(
    "SHINYGLASS_EXAMPLES_DIR",
    unset = file.path(dirname(pkg_root), "shiny-examples-glass-test")
  )
}

script_dir <- file.path(pkg_root, "inst", "scripts")
source(file.path(script_dir, "glass-test-utils.R"))

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || identical(x, "")) y else x

for (pkg in c("shinyglass", "chromote", "processx", "curl", "jsonlite")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(pkg, " is required.")
  }
}

gallery_dir <- file.path(pkg_root, "man", "figures", "gallery")
dir.create(gallery_dir, recursive = TRUE, showWarnings = FALSE)

wait_for_url <- function(url, timeout = 45) {
  deadline <- Sys.time() + timeout
  while (Sys.time() < deadline) {
    ok <- tryCatch(
      curl::curl_fetch_memory(url)$status_code == 200,
      error = function(e) FALSE
    )
    if (ok) return(TRUE)
    Sys.sleep(0.5)
  }
  FALSE
}

wait_for_shiny <- function(session, timeout = 40) {
  js <- sprintf("
    new Promise((resolve) => {
      const deadline = Date.now() + %d;
      const check = () => {
        const bound = document.querySelectorAll('.shiny-bound-output, .shiny-bound-input').length;
        const busy = document.querySelectorAll('.shiny-busy').length;
        if (bound > 0 && busy === 0) { resolve(true); return; }
        if (Date.now() > deadline) { resolve(false); return; }
        setTimeout(check, 300);
      };
      check();
    });
  ", timeout * 1000L)
  session$Runtime$evaluate(
    expression = js,
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = (timeout + 5) * 1000
  )
}

capture_url <- function(url, out_path, width = 1400L, height = 560L, click = NULL) {
  b <- chromote::ChromoteSession$new()
  on.exit(tryCatch(b$close(), error = function(e) NULL), add = TRUE)
  b$set_viewport_size(width = width, height = height)
  b$go_to(url)
  Sys.sleep(1.5)
  tryCatch(wait_for_shiny(b, timeout = 40), error = function(e) NULL)

  if (!is.null(click)) {
    js <- sprintf("
      (function() {
        const el = document.querySelector(%s);
        if (!el) return false;
        el.click();
        return true;
      })();
    ", jsonlite::toJSON(click, auto_unbox = TRUE))
    tryCatch(
      b$Runtime$evaluate(expression = js, returnByValue = TRUE, timeout = 5000),
      error = function(e) NULL
    )
    Sys.sleep(1)
  }

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  b$screenshot(out_path)
  invisible(out_path)
}

run_example <- function(app_dir, port) {
  prep <- prepare_patched_app_dir(app_dir)
  if (!prep$ok) {
    stop("Cannot patch app: ", prep$reason)
  }
  app_path <- normalizePath(prep$dir, winslash = "/")
  run_expr <- sprintf(
    "shiny::runApp('%s', host='127.0.0.1', port=%d, launch.browser=FALSE, display.mode='normal')",
    gsub("'", "\\\\'", app_path),
    port
  )
  processx::process$new(
    command = normalizePath(Sys.which("Rscript")),
    args = c("-e", run_expr),
    stdout = "|",
    stderr = "|"
  )
}

run_package_example <- function(example_rel, port) {
  app_path <- system.file("examples", example_rel, package = "shinyglass")
  if (!nzchar(app_path)) {
    stop("Example not found: ", example_rel)
  }
  app_path <- normalizePath(app_path, winslash = "/")
  run_expr <- sprintf(
    "shiny::runApp('%s', host='127.0.0.1', port=%d, launch.browser=FALSE, display.mode='normal')",
    gsub("'", "\\\\'", app_path),
    port
  )
  processx::process$new(
    command = normalizePath(Sys.which("Rscript")),
    args = c("-e", run_expr),
    stdout = "|",
    stderr = "|"
  )
}

shots <- list(
  list(
    dest = "01-fluid-sidebar.png",
    type = "example",
    path = file.path(examples_dir, "001-hello"),
    height = 520L
  ),
  list(
    dest = "02-tabsets.png",
    type = "example",
    path = file.path(examples_dir, "006-tabsets"),
    height = 560L,
    click = ".nav-tabs .nav-link:nth-child(2)"
  ),
  list(
    dest = "03-action-button.png",
    type = "example",
    path = file.path(examples_dir, "007-widgets"),
    height = 620L
  ),
  list(
    dest = "04-download.png",
    type = "example",
    path = file.path(examples_dir, "010-download"),
    height = 520L
  ),
  list(
    dest = "05-datatables.png",
    type = "example",
    path = file.path(examples_dir, "012-datatables"),
    height = 640L
  ),
  list(
    dest = "06-selectize.png",
    type = "example",
    path = file.path(examples_dir, "013-selectize"),
    height = 560L
  ),
  list(
    dest = "07-navbar.png",
    type = "example",
    path = file.path(examples_dir, "015-layout-navbar"),
    height = 520L
  ),
  list(
    dest = "08-page-sidebar.png",
    type = "package",
    path = "apple-glass-reference.R",
    height = 640L
  )
)

base_port <- 4200L
results <- character()

for (i in seq_along(shots)) {
  shot <- shots[[i]]
  dest <- file.path(gallery_dir, shot$dest)
  port <- base_port + i
  url <- sprintf("http://127.0.0.1:%d", port)

  message("[", i, "/", length(shots), "] ", shot$dest)

  proc <- tryCatch({
    if (shot$type == "package") {
      run_package_example(shot$path, port)
    } else {
      if (!dir.exists(shot$path)) {
        stop("not found: ", shot$path)
      }
      run_example(shot$path, port)
    }
  }, error = function(e) {
    warning("Skipping ", shot$dest, " — ", conditionMessage(e))
    NULL
  })

  if (is.null(proc)) next

  if (!wait_for_url(url)) {
    err <- if (proc$is_alive()) proc$read_all_error() else "process exited"
    if (proc$is_alive()) proc$kill()
    warning("Failed to start app for ", shot$dest, ": ", err)
    next
  }

  ok <- tryCatch({
    capture_url(url, dest, height = shot$height, click = shot$click %||% NULL)
    TRUE
  }, error = function(e) {
    warning("Capture failed for ", shot$dest, ": ", conditionMessage(e))
    FALSE
  }, finally = {
    if (proc$is_alive()) proc$kill()
  })

  if (ok) {
    results <- c(results, shot$dest)
    message("  -> ", dest)
  }
}

cat("\nCaptured ", length(results), " screenshots in ", gallery_dir, "\n", sep = "")
invisible(results)