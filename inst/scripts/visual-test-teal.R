#!/usr/bin/env Rscript
# Visual coverage: insightsengineering/teal.gallery apps with glass_theme().
#
# Teal applies Bootstrap themes via options(teal.bs_theme = ...). We inject
# glass_theme() that way (see teal vignette "Bootstrap Themes in teal").
#
# Usage:
#   Rscript inst/scripts/visual-test-teal.R [output-dir] [gallery-dir]
#
# Env:
#   SHINYGLASS_TEAL_GALLERY   path to cloned teal.gallery (cloned if missing)
#   SHINYGLASS_PRESET         light|dark (default light)
#   SHINYGLASS_TEAL_APPS      comma-separated app ids (default: core teal-only set)

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

if (!requireNamespace("teal", quietly = TRUE)) {
  stop(
    "teal is required for these apps.\n",
    "  install.packages(\"teal\")",
    call. = FALSE
  )
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

# --- app catalog ------------------------------------------------------------
# deps: packages beyond base teal needed to start the app
teal_app_catalog <- list(
  `basic-teal` = list(
    label = "Basic teal (filters + example module)",
    deps = character(),
    interactions = c("module", "filter")
  ),
  `teal-as-shiny-module` = list(
    label = "Teal embedded as shiny modules (fluidPage)",
    deps = character(),
    interactions = c("module"),
    # uses fluidPage(theme=...) patch path rather than teal.bs_theme only
    page_theme = TRUE
  ),
  `custom-transform` = list(
    label = "Custom transform modules + teal_slices",
    deps = character(),
    interactions = c("module", "filter")
  ),
  `delayed-data` = list(
    label = "Delayed data loading (teal_data_module)",
    deps = character(),
    interactions = c("load-data", "module")
  ),
  exploratory = list(
    label = "Exploratory modules (teal.modules.general)",
    deps = c("teal.modules.general", "random.cdisc.data"),
    interactions = c("module", "filter")
  ),
  safety = list(
    label = "Safety analysis (teal.modules.clinical)",
    deps = c("teal.modules.general", "teal.modules.clinical", "random.cdisc.data"),
    interactions = c("module", "filter")
  ),
  efficacy = list(
    label = "Efficacy analysis (teal.modules.clinical)",
    deps = c("teal.modules.general", "teal.modules.clinical", "random.cdisc.data"),
    interactions = c("module", "filter")
  ),
  `patient-profile` = list(
    label = "Patient profile modules",
    deps = c("teal.modules.general", "teal.modules.clinical", "random.cdisc.data"),
    interactions = c("module", "filter")
  )
)

default_apps <- c(
  "basic-teal",
  "teal-as-shiny-module",
  "custom-transform",
  "delayed-data"
)

resolve_gallery_dir <- function(pkg_root, explicit = NULL) {
  candidates <- c(
    explicit %||% "",
    Sys.getenv("SHINYGLASS_TEAL_GALLERY", unset = ""),
    file.path(dirname(pkg_root), "teal.gallery"),
    file.path(pkg_root, "inst", "external", "teal.gallery"),
    "/tmp/teal.gallery"
  )
  candidates <- candidates[nzchar(candidates)]
  for (p in candidates) {
    if (dir.exists(p) && dir.exists(file.path(p, "basic-teal"))) {
      return(normalizePath(p, winslash = "/"))
    }
  }

  cache <- file.path(pkg_root, "inst", "external", "teal.gallery")
  message("Cloning insightsengineering/teal.gallery (depth=1)…")
  dir.create(dirname(cache), recursive = TRUE, showWarnings = FALSE)
  if (dir.exists(cache)) unlink(cache, recursive = TRUE)
  status <- system2(
    "git",
    c(
      "clone", "--depth", "1",
      "https://github.com/insightsengineering/teal.gallery.git",
      cache
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  if (!is.null(attr(status, "status")) && attr(status, "status") != 0L) {
    stop("git clone failed:\n", paste(status, collapse = "\n"), call. = FALSE)
  }
  if (!dir.exists(file.path(cache, "basic-teal"))) {
    stop("teal.gallery clone incomplete at ", cache, call. = FALSE)
  }
  normalizePath(cache, winslash = "/")
}

# Stage app with glass theme injected at top (teal.bs_theme) and optional
# fluidPage theme= patch for embedded teal-as-shiny-module style apps.
prepare_teal_glass_app <- function(app_id, gallery_dir, pkg_root) {
  meta <- teal_app_catalog[[app_id]]
  if (is.null(meta)) {
    return(list(ok = FALSE, reason = "unknown app id", id = app_id))
  }

  src <- file.path(gallery_dir, app_id)
  if (!dir.exists(src) || !file.exists(file.path(src, "app.R"))) {
    return(list(ok = FALSE, reason = "app dir missing", id = app_id, label = meta$label))
  }

  missing <- meta$deps[!vapply(meta$deps, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    return(list(
      ok = FALSE,
      reason = paste0("missing packages: ", paste(missing, collapse = ", ")),
      id = app_id,
      label = meta$label
    ))
  }

  tmp <- tempfile(paste0("glass-teal-", app_id, "-"))
  dir.create(tmp, recursive = TRUE)
  # copy only runnable files (skip renv / tests to avoid locking user library)
  for (f in c("app.R", "global.R", "ui.R", "server.R", "www", "R", "data")) {
    src_f <- file.path(src, f)
    if (file.exists(src_f) || dir.exists(src_f)) {
      if (dir.exists(src_f)) {
        file.copy(src_f, tmp, recursive = TRUE)
      } else {
        file.copy(src_f, file.path(tmp, f))
      }
    }
  }

  app_path <- file.path(tmp, "app.R")
  code <- paste(readLines(app_path, warn = FALSE), collapse = "\n")

  glass_boot <- paste(
    c(
      "# --- shinyglass injection (visual-test-teal.R) ---",
      sprintf("pkg_root <- %s", deparse(pkg_root)),
      "if (requireNamespace('pkgload', quietly = TRUE) && dir.exists(pkg_root)) {",
      "  try(pkgload::load_all(pkg_root, quiet = TRUE), silent = TRUE)",
      "}",
      "if (!requireNamespace('shinyglass', quietly = TRUE)) {",
      "  stop('shinyglass not available', call. = FALSE)",
      "}",
      "library(shinyglass)",
      sprintf(
        "glass_preset <- match.arg(Sys.getenv('SHINYGLASS_PRESET', 'light'), c('light', 'dark'))"
      ),
      "options(teal.bs_theme = glass_theme(preset = glass_preset))",
      "# --- end shinyglass injection ---",
      ""
    ),
    collapse = "\n"
  )

  if (!grepl("shinyglass injection", code, fixed = TRUE)) {
    code <- paste0(glass_boot, code)
  }

  # fluidPage host: also set theme= so outer chrome is glassed
  if (isTRUE(meta$page_theme)) {
    patched <- replace_page_theme(code)
    if (!is.na(patched)) code <- patched
  }

  writeLines(code, app_path)

  list(
    ok = TRUE,
    id = app_id,
    label = meta$label,
    dir = tmp,
    interactions = meta$interactions %||% character()
  )
}

out_root <- if (length(args) >= 1) {
  normalizePath(args[[1]], winslash = "/", mustWork = FALSE)
} else {
  file.path(pkg_root, "visual-test-output", "teal-gallery")
}
dir.create(out_root, recursive = TRUE, showWarnings = FALSE)

gallery_explicit <- if (length(args) >= 2) args[[2]] else NULL
gallery_dir <- resolve_gallery_dir(pkg_root, gallery_explicit)

app_env <- Sys.getenv("SHINYGLASS_TEAL_APPS", unset = "")
targets <- if (nzchar(app_env)) {
  trimws(strsplit(app_env, ",", fixed = TRUE)[[1]])
} else {
  default_apps
}
targets <- targets[nzchar(targets)]

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

wait_for_teal_ready <- function(session, timeout = 90) {
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
        const body = document.querySelector('.teal-body, .teal-modules-wrapper, #teal, .container-fluid');
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

click_text_match <- function(session, pattern, selector = "a, button, .nav-link, .btn, label") {
  js <- sprintf("
    (function() {
      const re = new RegExp(%s, 'i');
      const els = [...document.querySelectorAll(%s)];
      const el = els.find(e => re.test((e.textContent || '').trim()) && e.offsetParent !== null);
      if (!el) return false;
      el.scrollIntoView({block: 'center'});
      el.click();
      return true;
    })();
  ", jsonlite::toJSON(pattern, auto_unbox = TRUE),
     jsonlite::toJSON(selector, auto_unbox = TRUE))
  chromote_safe(session$Runtime$evaluate(
    expression = js, returnByValue = TRUE, timeout = 5000
  ), label = "click-text")
}

click_selector <- function(session, selector) {
  js <- sprintf("
    (function() {
      const el = document.querySelector(%s);
      if (!el) return false;
      el.scrollIntoView({block: 'center'});
      el.click();
      return true;
    })();
  ", jsonlite::toJSON(selector, auto_unbox = TRUE))
  chromote_safe(session$Runtime$evaluate(
    expression = js, returnByValue = TRUE, timeout = 5000
  ), label = "click")
}

test_one_teal_app <- function(target, out_dir, port) {
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

  proc_env <- c(
    Sys.getenv(),
    SHINYGLASS_PRESET = Sys.getenv("SHINYGLASS_PRESET", "light"),
    SHINYGLASS_PKG_ROOT = pkg_root
  )

  proc <- processx::process$new(
    command = normalizePath(Sys.which("Rscript")),
    args = c("-e", run_expr),
    stdout = "|",
    stderr = "|",
    env = proc_env
  )

  kill_app <- function() {
    if (proc$is_alive()) {
      tryCatch(proc$kill(tree = TRUE), error = function(e) proc$kill())
    }
  }
  on.exit(kill_app(), add = TRUE)

  # teal apps can take longer on first load
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
      wait_for_teal_ready(b, timeout = 90),
      label = "wait-ready",
      timeout = 100
    )
    if (!is.null(ready$error)) log("WARN wait: ", ready$error)
    Sys.sleep(1.5)

    capture_screenshot(b, file.path(out_dir, "01-initial.png"))
    shots <- shots + 1L
    log("screenshot: 01-initial.png")

    interactions <- target$interactions %||% character()

    if ("load-data" %in% interactions) {
      click_selector(b, "button.btn, .action-button, button")
      click_text_match(b, "Load")
      Sys.sleep(2)
      tryCatch({
        capture_screenshot(b, file.path(out_dir, "02-after-load.png"))
        shots <- shots + 1L
        log("screenshot: 02-after-load.png")
      }, error = function(e) issues <<- c(issues, conditionMessage(e)))
    }

    if ("module" %in% interactions) {
      # open module tree / second module if present
      b$Runtime$evaluate("
        (function() {
          const links = [...document.querySelectorAll(
            '.teal-modules-tree a, .teal-navbar a, .nav-link, .dropdown-item, a.action-button'
          )].filter(a => a.offsetParent !== null);
          if (links.length > 1) { links[1].click(); return true; }
          if (links.length === 1) { links[0].click(); return true; }
          return false;
        })();
      ")
      Sys.sleep(1.5)
      tryCatch({
        capture_screenshot(b, file.path(out_dir, sprintf("%02d-module.png", shots + 1L)))
        shots <- shots + 1L
        log("screenshot: module")
      }, error = function(e) issues <<- c(issues, conditionMessage(e)))
    }

    if ("filter" %in% interactions) {
      # expand filter panel / interact with a filter control
      b$Runtime$evaluate("
        (function() {
          const toggles = [...document.querySelectorAll(
            '.filter-panel button, .teal-filter-panel button, [id*=\"filter\"] button, .accordion-button, .card-header button'
          )].filter(b => b.offsetParent !== null);
          if (toggles[0]) { toggles[0].click(); return 'toggle'; }
          const inputs = document.querySelectorAll(
            '.filter-panel input, .filter-panel select, [id*=\"filter\"] input, [id*=\"filter\"] select'
          );
          if (inputs[0]) { inputs[0].focus(); return 'focus'; }
          return 'none';
        })();
      ")
      Sys.sleep(1.2)
      tryCatch({
        capture_screenshot(b, file.path(out_dir, sprintf("%02d-filter.png", shots + 1L)))
        shots <- shots + 1L
        log("screenshot: filter")
      }, error = function(e) issues <<- c(issues, conditionMessage(e)))
    }

    # mid-page scroll
    chromote_safe({
      b$Runtime$evaluate("window.scrollTo(0, Math.min(document.body.scrollHeight * 0.4, 500));")
    })
    Sys.sleep(0.5)
    tryCatch({
      capture_screenshot(b, file.path(out_dir, sprintf("%02d-scrolled.png", shots + 1L)))
      shots <- shots + 1L
      log("screenshot: scrolled")
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
plog("Apps:    ", paste(targets, collapse = ", "))

prepared <- lapply(targets, function(id) {
  plog("  setup: ", id)
  prepare_teal_glass_app(id, gallery_dir, pkg_root)
})

results <- data.frame(
  app = targets,
  label = vapply(prepared, function(x) x$label %||% x$id %||% "", character(1)),
  status = character(length(targets)),
  reason = character(length(targets)),
  shots = integer(length(targets)),
  stringsAsFactors = FALSE
)

base_port <- 4300L
for (i in seq_along(targets)) {
  app <- targets[[i]]
  plog("[", i, "/", length(targets), "] ", app)
  res <- tryCatch(
    test_one_teal_app(prepared[[i]], file.path(out_root, app), port = base_port + i),
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
  "# shinyglass visual test — teal.gallery",
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
  "Teal apps receive glass via `options(teal.bs_theme = glass_theme())`",
  "injected at the top of each staged `app.R`. Embedded `fluidPage` hosts",
  "also get `theme = glass_theme()`.",
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
  "1. **Header / navbar** — floating glass chrome, readable title",
  "2. **Module nav** — teal module tree / tabs pick up glass surfaces",
  "3. **Filter panel** — teal.slice filter UI readable; no solid white boxes",
  "4. **Main module** — example tables/plots not clipped; contrast OK",
  "5. **Footer** — present and legible on glass page background",
  "",
  "**Watch for:** teal-specific panels ignoring glass, filter accordion solid fills,",
  "dropdown menus transparent/unreadable, missing orbs/page gradient."
)

writeLines(lines, report_path)
write.csv(results, file.path(out_root, "results.csv"), row.names = FALSE)

plog("Done. Report: ", normalizePath(report_path))
print(results[, c("app", "status", "shots")])
invisible(results)
