#!/usr/bin/env Rscript
# Visual coverage: rstudio/shiny-gallery user showcase apps with glass_theme().
#
# Usage:
#   Rscript inst/scripts/visual-test-shiny-gallery.R [output-dir] [gallery-dir]
#
# Env:
#   SHINYGLASS_SHINY_GALLERY  path to cloned shiny-gallery
#   SHINYGLASS_PRESET         light|dark (default light)
#   SHINYGLASS_GALLERY_APPS   comma-separated app ids (default: curated set)
#   SHINYGLASS_GALLERY_LIMIT  max apps to run (default: all selected)

args <- commandArgs(trailingOnly = TRUE)

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/"))
} else {
  normalizePath("inst/scripts", winslash = "/")
}
pkg_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/")

source(file.path(script_dir, "glass-test-utils.R"))

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || identical(x, "")) y else x

for (pkg in c("shiny", "chromote", "processx", "curl", "jsonlite")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(pkg, " is required. Install it before running this script.")
  }
}

if (!requireNamespace("shinyglass", quietly = TRUE)) {
  if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(pkg_root, quiet = TRUE)
  } else {
    stop("shinyglass must be installed or pkgload available.", call. = FALSE)
  }
} else if (requireNamespace("pkgload", quietly = TRUE)) {
  tryCatch(pkgload::load_all(pkg_root, quiet = TRUE), error = function(e) NULL)
}

# Curated set: pure R showcase apps that typically use fluidPage/navbarPage.
# Skip python (respiratory_disease_pyshiny), Rmd gallery, and app-slug template.
default_apps <- c(
  "hangman",
  "life-of-pi",
  "hotshot-dashboard",
  "cran-explorer",
  "covid19-dashboard",
  "freedom-press-index",
  "lake-profile-dashboard",
  "nyc-metro-vis",
  "nz-trade-dash",
  "one-source-indy",
  "genome-browser",
  "shiny-decisions",
  "covid19-timeline",
  "hangman-ru"
)

resolve_gallery_dir <- function(pkg_root, explicit = NULL) {
  candidates <- c(
    explicit %||% "",
    Sys.getenv("SHINYGLASS_SHINY_GALLERY", unset = ""),
    file.path(dirname(pkg_root), "shiny-gallery"),
    file.path(pkg_root, "inst", "external", "shiny-gallery"),
    "/tmp/shiny-gallery"
  )
  candidates <- candidates[nzchar(candidates)]
  for (p in candidates) {
    if (dir.exists(p) && length(list.dirs(p, recursive = FALSE)) > 0) {
      return(normalizePath(p, winslash = "/"))
    }
  }

  cache <- file.path(pkg_root, "inst", "external", "shiny-gallery")
  message("Cloning rstudio/shiny-gallery (depth=1)…")
  dir.create(dirname(cache), recursive = TRUE, showWarnings = FALSE)
  if (dir.exists(cache)) unlink(cache, recursive = TRUE)
  status <- system2(
    "git",
    c("clone", "--depth", "1", "https://github.com/rstudio/shiny-gallery.git", cache),
    stdout = TRUE,
    stderr = TRUE
  )
  if (!is.null(attr(status, "status")) && attr(status, "status") != 0L) {
    stop("git clone failed:\n", paste(status, collapse = "\n"), call. = FALSE)
  }
  normalizePath(cache, winslash = "/")
}

discover_gallery_apps <- function(gallery_dir) {
  dirs <- list.dirs(gallery_dir, recursive = FALSE, full.names = TRUE)
  basenames <- basename(dirs)
  # skip meta / non-app dirs
  skip <- grepl("^(z_|\\.|app-slug)", basenames) |
    basenames %in% c("respiratory_disease_pyshiny")
  dirs <- dirs[!skip]
  # must have app.R or ui.R
  keep <- vapply(dirs, function(d) {
    any(file.exists(file.path(d, c("app.R", "ui.R", "ui.r", "server.R"))))
  }, logical(1))
  sort(basename(dirs[keep]))
}

resolve_app_src <- function(gallery_dir, app_id) {
  root <- file.path(gallery_dir, app_id)
  if (!dir.exists(root)) return(NA_character_)
  candidates <- c(
    root,
    file.path(root, "app"),
    file.path(root, "src"),
    file.path(root, "src", "app")
  )
  for (c in candidates) {
    if (!dir.exists(c)) next
    ui <- primary_ui_file(c)
    if (!is.na(ui)) return(normalizePath(c, winslash = "/"))
  }
  normalizePath(root, winslash = "/")
}

prepare_gallery_app <- function(app_id, gallery_dir, pkg_root) {
  src <- resolve_app_src(gallery_dir, app_id)
  if (is.na(src) || !dir.exists(src)) {
    return(list(ok = FALSE, reason = "app dir missing", id = app_id))
  }

  prep <- prepare_patched_app_dir(src)
  if (!isTRUE(prep$ok)) {
    return(list(
      ok = FALSE,
      reason = prep$reason %||% "could not patch",
      id = app_id,
      label = app_id
    ))
  }

  # inject pkgload bootstrap so glass_theme resolves from source checkout
  app_file <- file.path(prep$dir, prep$ui_file)
  if (!file.exists(app_file)) {
    # prep$dir is staged basename; ui may be nested under it
    app_file <- file.path(prep$dir, prep$ui_file)
  }
  code <- paste(readLines(app_file, warn = FALSE), collapse = "\n")
  boot <- paste(
    c(
      "# --- shinyglass injection ---",
      sprintf("if (requireNamespace('pkgload', quietly = TRUE) && dir.exists(%s)) {", deparse(pkg_root)),
      sprintf("  try(pkgload::load_all(%s, quiet = TRUE), silent = TRUE)", deparse(pkg_root)),
      "}",
      "if (!requireNamespace('shinyglass', quietly = TRUE)) stop('shinyglass not available')",
      "library(shinyglass)",
      "glass_preset <- match.arg(Sys.getenv('SHINYGLASS_PRESET', 'light'), c('light', 'dark'))",
      "# theme already set to glass_theme() by prepare_patched_app_dir",
      "# --- end injection ---",
      ""
    ),
    collapse = "\n"
  )
  if (!grepl("shinyglass injection", code, fixed = TRUE)) {
    code <- gsub(
      "theme = glass_theme\\(\\)",
      "theme = glass_theme(preset = glass_preset)",
      code,
      perl = TRUE
    )
    code <- paste0(boot, code)
    writeLines(code, app_file)
  }

  # Known gallery compatibility fixups (future plan API, etc.)
  for (f in list.files(prep$dir, pattern = "\\.[Rr]$", recursive = TRUE, full.names = TRUE)) {
    txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
    new <- txt
    new <- gsub("\\bplan\\s*\\(\\s*multiprocess\\s*\\)", "plan(multisession)", new, perl = TRUE)
    if (!identical(new, txt)) writeLines(new, f)
  }

  # If the original app launches from a parent dir (e.g. covid19-timeline/app.R
  # sources ui/ui.R), run the parent package folder rather than nested ui/.
  run_dir <- prep$dir
  if (!file.exists(file.path(run_dir, "app.R")) &&
        !file.exists(file.path(run_dir, "app.r")) &&
        !file.exists(file.path(run_dir, "server.R"))) {
    # staged copy is always basename(src); if src was nested under gallery app,
    # also keep a note — usually src is the app root.
    run_dir <- prep$dir
  }

  list(
    ok = TRUE,
    id = app_id,
    label = app_id,
    dir = run_dir
  )
}

out_root <- if (length(args) >= 1) {
  normalizePath(args[[1]], winslash = "/", mustWork = FALSE)
} else {
  file.path(pkg_root, "visual-test-output", "shiny-gallery")
}
dir.create(out_root, recursive = TRUE, showWarnings = FALSE)

gallery_explicit <- if (length(args) >= 2) args[[2]] else NULL
gallery_dir <- resolve_gallery_dir(pkg_root, gallery_explicit)

available <- discover_gallery_apps(gallery_dir)
app_env <- Sys.getenv("SHINYGLASS_GALLERY_APPS", unset = "")
if (nzchar(app_env)) {
  targets <- trimws(strsplit(app_env, ",", fixed = TRUE)[[1]])
} else {
  targets <- intersect(default_apps, available)
  # also include any other discovered apps not in the skip list
  extras <- setdiff(available, default_apps)
  targets <- unique(c(targets, extras))
}
targets <- targets[nzchar(targets)]

limit <- suppressWarnings(as.integer(Sys.getenv("SHINYGLASS_GALLERY_LIMIT", unset = "")))
if (!is.na(limit) && limit > 0L) {
  targets <- head(targets, limit)
}

progress_log <- file.path(out_root, "progress.log")
plog <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " ", paste0(..., collapse = ""))
  cat(msg, "\n")
  cat(msg, "\n", file = progress_log, append = TRUE)
}

chromote_safe <- function(expr, label = "chromote", timeout = 20) {
  err <- NULL
  res <- tryCatch(expr, error = function(e) {
    err <<- conditionMessage(e)
    NULL
  })
  list(result = res, error = err)
}

close_chromote <- function(b) {
  if (is.null(b)) return(invisible(NULL))
  tryCatch(b$close(), error = function(e) NULL)
  invisible(NULL)
}

capture_screenshot <- function(session, path, width = 1440L, height = 960L) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  session$set_viewport_size(width = width, height = height)
  session$screenshot(path)
}

wait_for_app_ready <- function(session, timeout = 75) {
  js <- sprintf("
    new Promise((resolve) => {
      const deadline = Date.now() + %d;
      const retry = () => {
        if (Date.now() > deadline) { resolve(false); return; }
        setTimeout(check, 400);
      };
      const check = () => {
        const bound = document.querySelectorAll('.shiny-bound-output, .shiny-bound-input').length;
        const busy = document.querySelectorAll('.recalculating, .shiny-busy').length;
        const body = document.querySelector('body');
        if (!(bound > 0 && busy === 0 && body)) { retry(); return; }
        resolve(true);
      };
      check();
    });
  ", timeout * 1000L)
  session$Runtime$evaluate(
    expression = js,
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = (timeout + 10) * 1000
  )
}

test_one_app <- function(target, out_dir, port) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  log_path <- file.path(out_dir, "test-log.txt")
  log <- function(...) cat(paste0(..., "\n"), file = log_path, append = TRUE)

  if (!isTRUE(target$ok)) {
    log("SKIP: ", target$reason %||% "unknown")
    return(list(
      status = "skip",
      reason = target$reason %||% "unknown",
      shots = 0L,
      label = target$label %||% target$id
    ))
  }

  # resume if already captured
  if (file.exists(file.path(out_dir, "01-initial.png"))) {
    log("RESUME: 01-initial.png exists")
    n <- length(list.files(out_dir, pattern = "\\.png$"))
    return(list(
      status = "pass",
      reason = "resumed",
      shots = n,
      label = target$label
    ))
  }

  url <- sprintf("http://127.0.0.1:%d", port)
  app_path <- normalizePath(target$dir, winslash = "/")
  run_expr <- sprintf(
    paste(
      "if (requireNamespace('pkgload', quietly = TRUE)) {",
      "  try(pkgload::load_all(%s, quiet = TRUE), silent = TRUE)",
      "}",
      "shiny::runApp(%s, host='127.0.0.1', port=%d, launch.browser=FALSE)",
      sep = "; "
    ),
    deparse(pkg_root),
    deparse(app_path),
    port
  )

  proc <- processx::process$new(
    command = normalizePath(Sys.which("Rscript")),
    args = c("-e", run_expr),
    stdout = "|",
    stderr = "|",
    env = c(
      Sys.getenv(),
      SHINYGLASS_PRESET = Sys.getenv("SHINYGLASS_PRESET", "light"),
      SHINYGLASS_PKG_ROOT = pkg_root
    )
  )

  kill_app <- function() {
    if (proc$is_alive()) {
      tryCatch(proc$kill(tree = TRUE), error = function(e) proc$kill())
    }
  }
  on.exit(kill_app(), add = TRUE)

  if (!wait_for_url(url, timeout = 120)) {
    err <- paste(proc$read_all_error(), proc$read_all_output(), sep = "\n")
    log("FAIL: app did not start\n", err)
    return(list(
      status = "fail",
      reason = "app did not start",
      shots = 0L,
      label = target$label
    ))
  }

  shots <- 0L
  issues <- character()
  b <- NULL

  tryCatch({
    b <- chromote::ChromoteSession$new()
    on.exit(close_chromote(b), add = TRUE)

    nav <- chromote_safe(b$go_to(url), label = "navigate", timeout = 60)
    if (!is.null(nav$error)) stop(nav$error)

    ready <- chromote_safe(
      wait_for_app_ready(b, timeout = 80),
      label = "wait-ready",
      timeout = 90
    )
    if (!is.null(ready$error)) log("WARN wait: ", ready$error)
    Sys.sleep(1.5)

    capture_screenshot(b, file.path(out_dir, "01-initial.png"))
    shots <- shots + 1L
    log("screenshot: 01-initial.png")

    # click first visible nav / tab / button if present
    b$Runtime$evaluate("
      (function() {
        const cand = [...document.querySelectorAll(
          '.navbar-nav a, .nav-tabs a, .nav-pills a, .nav-link, .btn, a.action-button'
        )].filter(el => el.offsetParent !== null && (el.textContent || '').trim().length > 0);
        if (cand.length > 1) { cand[1].click(); return true; }
        if (cand.length === 1) { cand[0].click(); return true; }
        return false;
      })();
    ")
    Sys.sleep(1.4)
    tryCatch({
      capture_screenshot(b, file.path(out_dir, "02-interact.png"))
      shots <- shots + 1L
      log("screenshot: 02-interact.png")
    }, error = function(e) issues <<- c(issues, conditionMessage(e)))

    chromote_safe({
      b$Runtime$evaluate("window.scrollTo(0, Math.min(document.body.scrollHeight * 0.4, 600));")
    })
    Sys.sleep(0.5)
    tryCatch({
      capture_screenshot(b, file.path(out_dir, "03-scrolled.png"))
      shots <- shots + 1L
      log("screenshot: 03-scrolled.png")
    }, error = function(e) issues <<- c(issues, conditionMessage(e)))

  }, error = function(e) {
    issues <<- c(issues, conditionMessage(e))
    log("ERROR: ", conditionMessage(e))
    err <- paste(proc$read_all_error(), proc$read_all_output(), sep = "\n")
    if (nzchar(trimws(err))) log("PROC:\n", err)
  }, finally = {
    close_chromote(b)
    kill_app()
  })

  status <- if (length(issues) && shots > 0) {
    "partial"
  } else if (length(issues)) {
    "fail"
  } else {
    "pass"
  }

  list(
    status = status,
    reason = if (length(issues)) paste(issues, collapse = "; ") else NA_character_,
    shots = shots,
    label = target$label
  )
}

# --- run --------------------------------------------------------------------
plog("Gallery: ", gallery_dir)
plog("Output:  ", out_root)
plog("Available: ", paste(available, collapse = ", "))
plog("Apps:    ", paste(targets, collapse = ", "))

prepared <- lapply(targets, function(id) {
  plog("  setup: ", id)
  prepare_gallery_app(id, gallery_dir, pkg_root)
})

results <- data.frame(
  app = targets,
  label = vapply(prepared, function(x) x$label %||% x$id %||% "", character(1)),
  status = character(length(targets)),
  reason = character(length(targets)),
  shots = integer(length(targets)),
  stringsAsFactors = FALSE
)

base_port <- 4500L
for (i in seq_along(targets)) {
  app <- targets[[i]]
  plog("[", i, "/", length(targets), "] ", app)
  res <- tryCatch(
    test_one_app(prepared[[i]], file.path(out_root, app), port = base_port + i),
    error = function(e) list(
      status = "fail",
      reason = conditionMessage(e),
      shots = 0L,
      label = prepared[[i]]$label %||% app
    )
  )
  results$status[i] <- res$status
  results$reason[i] <- res$reason %||% ""
  results$shots[i] <- res$shots
  results$label[i] <- res$label %||% results$label[i]
  plog("  -> ", res$status, if (nzchar(res$reason %||% "")) paste0(" (", res$reason, ")") else "")
}

report_path <- file.path(out_root, "REPORT.md")
lines <- c(
  "# shinyglass visual test — shiny-gallery",
  "",
  paste0("- Package: `", pkg_root, "`"),
  paste0("- Gallery: `", gallery_dir, "`"),
  paste0("- Date: ", Sys.time()),
  paste0("- Apps tested: ", nrow(results)),
  paste0("- Screenshots taken: ", sum(results$shots)),
  paste0("- Preset: ", Sys.getenv("SHINYGLASS_PRESET", "light")),
  "",
  "## Approach",
  "",
  "Apps are staged with `theme = glass_theme()` injected into the first",
  "supported page function (`fluidPage`, `navbarPage`, `page_*`, …).",
  "",
  "## Summary",
  "",
  "| Status | Count |",
  "|--------|-------|",
  paste0("| pass | ", sum(results$status == "pass"), " |"),
  paste0("| partial | ", sum(results$status == "partial"), " |"),
  paste0("| fail | ", sum(results$status == "fail"), " |"),
  paste0("| skip | ", sum(results$status == "skip"), " |"),
  "",
  "## Apps",
  "",
  "| App | Status | Shots | Notes |",
  "|-----|--------|-------|-------|"
)

for (i in seq_len(nrow(results))) {
  lines <- c(lines, sprintf(
    "| %s | %s | %d | %s |",
    results$app[i],
    results$status[i],
    results$shots[i],
    gsub("\\|", "/", paste(results$label[i], results$reason[i], sep = " — "))
  ))
}

lines <- c(
  lines,
  "",
  "## Review checklist",
  "",
  "1. **Page background** — gradient/orbs visible, not solid white",
  "2. **Navbar / sidebar** — floating glass chrome, readable text",
  "3. **Cards / wells / panels** — glass surfaces, not opaque white boxes",
  "4. **Inputs / tables / plots** — contrast OK; menus not transparent",
  "5. **Interactions** — tabs/buttons still usable after glass",
  "",
  "**Watch for:** custom CSS fighting glass, maps under navbar, solid",
  "AdminLTE/dashboard skins, missing theme injection (skip reasons)."
)

writeLines(lines, report_path)
write.csv(results, file.path(out_root, "results.csv"), row.names = FALSE)

plog("Done. Report: ", normalizePath(report_path))
print(results[, c("app", "status", "shots", "reason")])
invisible(results)
