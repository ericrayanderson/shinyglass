#!/usr/bin/env Rscript
# Tier A/B visual coverage for shinyglass beyond classic shiny-examples.
#
# Tier A: SuperZIP (leaflet/map chrome), shinyWidgets gallery (custom inputs)
# Tier B: bs4Dash minimal dashboard (AdminLTE3 boxes / value boxes)
#
# Usage:
#   Rscript inst/scripts/visual-test-tier-ab.R [output-dir]
#
# Env:
#   SHINYGLASS_EXAMPLES_DIR  path to cloned rstudio/shiny-examples
#   SHINYGLASS_SUPERZIP_DIR  path to 063-superzip-example directly
#   SHINYGLASS_PRESET        light|dark (default light)

args <- commandArgs(trailingOnly = TRUE)

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/"))
} else {
  normalizePath("inst/scripts", winslash = "/")
}
pkg_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/")

source(file.path(script_dir, "glass-test-utils.R"))
source(file.path(script_dir, "tier-ab-utils.R"))

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
  # Prefer dev sources so SCSS fixes are visible without reinstall
  tryCatch(pkgload::load_all(pkg_root, quiet = TRUE), error = function(e) NULL)
}

out_root <- if (length(args) >= 1) {
  normalizePath(args[[1]], winslash = "/", mustWork = FALSE)
} else {
  file.path(pkg_root, "visual-test-output", "tier-ab")
}
dir.create(out_root, recursive = TRUE, showWarnings = FALSE)

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

capture_screenshot <- function(session, path, width = 1400L, height = 900L) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  session$set_viewport_size(width = width, height = height)
  session$screenshot(path)
}

wait_for_app_ready <- function(session, mode = c("default", "superzip", "widgets", "bs4dash"), timeout = 60) {
  mode <- match.arg(mode)
  extra <- switch(
    mode,
    superzip = "
      const map = document.querySelector('.leaflet-container');
      const tiles = document.querySelectorAll('.leaflet-tile-loaded').length;
      if (!map || tiles < 1) { retry(); return; }
    ",
    widgets = "
      const inputs = document.querySelectorAll('.shiny-bound-input, .form-group, .bootstrap-switch').length;
      if (inputs < 3) { retry(); return; }
    ",
    bs4dash = "
      const boxes = document.querySelectorAll('.card, .small-box, .info-box, .brand-link').length;
      if (boxes < 2) { retry(); return; }
    ",
    default = ""
  )
  js <- sprintf("
    new Promise((resolve) => {
      const deadline = Date.now() + %d;
      const retry = () => {
        if (Date.now() > deadline) { resolve(false); return; }
        setTimeout(check, 350);
      };
      const check = () => {
        const bound = document.querySelectorAll('.shiny-bound-output, .shiny-bound-input').length;
        const busy = document.querySelectorAll('.recalculating, .shiny-busy').length;
        if (!(bound > 0 && busy === 0)) { retry(); return; }
        %s
        resolve(true);
      };
      check();
    });
  ", timeout * 1000L, extra)
  session$Runtime$evaluate(
    expression = js,
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = (timeout + 5) * 1000
  )
}

click_if_present <- function(session, selector) {
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

test_one_target <- function(target, out_dir, port) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  log_path <- file.path(out_dir, "test-log.txt")
  log <- function(...) cat(paste0(..., "\n"), file = log_path, append = TRUE)

  if (!isTRUE(target$ok)) {
    log("SKIP: ", target$reason %||% "unknown")
    return(list(
      status = "skip",
      reason = target$reason %||% "unknown",
      shots = 0L,
      tier = target$tier %||% NA_character_,
      label = target$label %||% target$id
    ))
  }

  url <- sprintf("http://127.0.0.1:%d", port)
  app_path <- normalizePath(target$dir, winslash = "/")
  run_expr <- sprintf(
    paste(
      "if (requireNamespace('pkgload', quietly = TRUE)) {",
      "  try(pkgload::load_all('%s', quiet = TRUE), silent = TRUE)",
      "}",
      "shiny::runApp('%s', host='127.0.0.1', port=%d, launch.browser=FALSE)",
      sep = "; "
    ),
    gsub("'", "\\\\'", pkg_root),
    gsub("'", "\\\\'", app_path),
    port
  )

  proc_env <- c(
    Sys.getenv(),
    SHINYGLASS_PRESET = Sys.getenv("SHINYGLASS_PRESET", "light"),
    SHINYGLASS_PKG_ROOT = pkg_root
  )
  if (!is.null(target$env) && length(target$env)) {
    proc_env[names(target$env)] <- target$env
  }

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

  if (!wait_for_url(url, timeout = 90)) {
    err <- proc$read_all_error()
    log("FAIL: app did not start\n", err)
    return(list(
      status = "fail",
      reason = "app did not start",
      shots = 0L,
      tier = target$tier,
      label = target$label
    ))
  }

  mode <- switch(
    target$id,
    superzip = "superzip",
    `shinywidgets-gallery` = "widgets",
    `bs4dash-demo` = "bs4dash",
    "default"
  )

  shots <- 0L
  issues <- character()
  b <- NULL

  tryCatch({
    b <- chromote::ChromoteSession$new()
    on.exit(close_chromote(b), add = TRUE)

    nav <- chromote_safe(b$go_to(url), label = "navigate", timeout = 45)
    if (!is.null(nav$error)) stop(nav$error)

    ready <- chromote_safe(
      wait_for_app_ready(b, mode = mode, timeout = 75),
      label = "wait-ready",
      timeout = 80
    )
    if (!is.null(ready$error)) log("WARN wait: ", ready$error)
    Sys.sleep(1.2)

    capture_screenshot(b, file.path(out_dir, "01-initial.png"))
    shots <- shots + 1L
    log("screenshot: 01-initial.png")

    # Target-specific interactions
    if (identical(target$id, "superzip")) {
      click_if_present(b, "a[data-value='Data explorer'], .navbar-nav a[href='#tab-2'], a[href*='explorer']")
      # Prefer tab by text
      b$Runtime$evaluate("
        [...document.querySelectorAll('.navbar-nav a, .nav-link')].find(a => /data explorer/i.test(a.textContent))?.click();
      ")
      Sys.sleep(1.5)
      tryCatch({
        capture_screenshot(b, file.path(out_dir, "02-data-explorer.png"))
        shots <- shots + 1L
        log("screenshot: 02-data-explorer.png")
      }, error = function(e) {
        issues <<- c(issues, conditionMessage(e))
      })
    }

    if (identical(target$id, "shinywidgets-gallery")) {
      # Jump to a few dense widget tabs
      for (tab in c("tabPretty", "tabMaterialSwitch", "tabPickerInput")) {
        b$Runtime$evaluate(sprintf("
          (function() {
            const a = document.querySelector('a[data-value=\"%s\"], a[href=\"#%s\"]');
            if (a) { a.click(); return true; }
            const byText = [...document.querySelectorAll('.nav-link, .list-group-item')]
              .find(el => el.textContent && el.textContent.includes('%s'));
            if (byText) { byText.click(); return true; }
            return false;
          })();
        ", tab, tab, gsub("tab", "", tab)))
        Sys.sleep(1)
      }
      tryCatch({
        capture_screenshot(b, file.path(out_dir, "02-widgets-tab.png"))
        shots <- shots + 1L
        log("screenshot: 02-widgets-tab.png")
      }, error = function(e) {
        issues <<- c(issues, conditionMessage(e))
      })
    }

    if (identical(target$id, "bs4dash-demo")) {
      click_if_present(b, "a[href='#shiny-tab-boxes'], a[data-value='boxes']")
      b$Runtime$evaluate("
        [...document.querySelectorAll('.nav-link, .nav-sidebar a')].find(a => /boxes/i.test(a.textContent))?.click();
      ")
      Sys.sleep(1)
      tryCatch({
        capture_screenshot(b, file.path(out_dir, "02-boxes-tab.png"))
        shots <- shots + 1L
        log("screenshot: 02-boxes-tab.png")
      }, error = function(e) {
        issues <<- c(issues, conditionMessage(e))
      })

      click_if_present(b, "#notify")
      Sys.sleep(0.8)
      tryCatch({
        capture_screenshot(b, file.path(out_dir, "03-notification.png"))
        shots <- shots + 1L
        log("screenshot: 03-notification.png")
      }, error = function(e) {
        issues <<- c(issues, conditionMessage(e))
      })
    }

    # Mid-page scroll
    chromote_safe({
      b$Runtime$evaluate("window.scrollTo(0, Math.min(document.body.scrollHeight * 0.45, 600));")
    })
    Sys.sleep(0.5)
    tryCatch({
      capture_screenshot(b, file.path(out_dir, sprintf("%02d-scrolled.png", shots + 1L)))
      shots <- shots + 1L
      log("screenshot: scrolled")
    }, error = function(e) {
      issues <<- c(issues, conditionMessage(e))
    })

  }, error = function(e) {
    issues <<- c(issues, conditionMessage(e))
    log("ERROR: ", conditionMessage(e))
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
    tier = target$tier,
    label = target$label
  )
}

targets <- c("superzip", "shinywidgets-gallery", "bs4dash-demo")
plog("Preparing tier A/B targets…")

prepared <- lapply(targets, function(id) {
  plog("  setup: ", id)
  prepare_tier_ab_app(id, pkg_root = pkg_root)
})

results <- data.frame(
  app = targets,
  tier = vapply(prepared, function(x) x$tier %||% "", character(1)),
  label = vapply(prepared, function(x) x$label %||% x$id %||% "", character(1)),
  status = character(length(targets)),
  reason = character(length(targets)),
  shots = integer(length(targets)),
  stringsAsFactors = FALSE
)

base_port <- 4200L
for (i in seq_along(targets)) {
  app <- targets[[i]]
  plog("[", i, "/", length(targets), "] ", app, " (tier ", prepared[[i]]$tier %||% "?", ")")
  res <- tryCatch(
    test_one_target(prepared[[i]], file.path(out_root, app), port = base_port + i),
    error = function(e) list(
      status = "fail",
      reason = conditionMessage(e),
      shots = 0L,
      tier = prepared[[i]]$tier,
      label = prepared[[i]]$label %||% app
    )
  )
  results$status[i] <- res$status
  results$reason[i] <- res$reason %||% ""
  results$shots[i] <- res$shots
  results$tier[i] <- res$tier %||% results$tier[i]
  results$label[i] <- res$label %||% results$label[i]
  plog("  -> ", res$status, if (nzchar(res$reason %||% "")) paste0(" (", res$reason, ")") else "")
}

report_path <- file.path(out_root, "REPORT.md")
lines <- c(
  "# shinyglass visual test — tier A/B coverage",
  "",
  paste0("- Package: `", pkg_root, "`"),
  paste0("- Date: ", Sys.time()),
  paste0("- Apps tested: ", nrow(results)),
  paste0("- Screenshots taken: ", sum(results$shots)),
  "",
  "## Goals",
  "",
  "| Tier | Focus | Apps |",
  "|------|-------|------|",
  "| A | Leaflet map chrome, dense custom inputs | SuperZIP, shinyWidgets gallery |",
  "| B | AdminLTE3 / bs4Dash boxes & value boxes | bs4dash-glass-demo |",
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
  "| App | Tier | Status | Shots | Notes |",
  "|-----|------|--------|-------|-------|"
)

for (i in seq_len(nrow(results))) {
  lines <- c(lines, sprintf(
    "| %s | %s | %s | %d | %s |",
    results$app[i],
    results$tier[i],
    results$status[i],
    results$shots[i],
    gsub("\\|", "/", paste(results$label[i], results$reason[i], sep = " — "))
  ))
}

lines <- c(
  lines,
  "",
  "## Manual launchers",
  "",
  "```r",
  "shiny::runApp(system.file('examples', 'superzip-glass.R', package = 'shinyglass'))",
  "shiny::runApp(system.file('examples', 'shinywidgets-gallery-glass.R', package = 'shinyglass'))",
  "shiny::runApp(system.file('examples', 'bs4dash-glass-demo.R', package = 'shinyglass'))",
  "```",
  "",
  "## Review checklist",
  "",
  "1. SuperZIP — map tiles under glass navbar; floating ZIP explorer panel; DT tab",
  "2. shinyWidgets — switch/pretty/picker controls readable on glass surfaces",
  "3. bs4Dash — value boxes and `.box` cards pick up glass styles; sidebar usable",
  "",
  "**Watch for:** map control z-index under navbar, widget label contrast,",
  "AdminLTE solid fills beating glass backgrounds, overflowing boxes."
)

writeLines(lines, report_path)
write.csv(results, file.path(out_root, "results.csv"), row.names = FALSE)

plog("Done. Report: ", normalizePath(report_path))
print(results[, c("app", "tier", "status", "shots")])
invisible(results)
