#!/usr/bin/env Rscript
# Visual regression test: run example apps with glass_theme(), screenshot
# initial state + after interactions, write analysis report.
#
# Usage:
#   Rscript visual-test-examples.R /path/to/repo [/path/to/output] [limit]
#
# Examples:
#   Rscript visual-test-examples.R ~/bslib ./visual-test-out/bslib
#   Rscript visual-test-examples.R ~/shiny-examples ./visual-test-out/shiny 20

args <- commandArgs(trailingOnly = TRUE)
repo_dir <- if (length(args) >= 1) args[[1]] else stop("Provide path to cloned repo")
out_root <- if (length(args) >= 2) args[[2]] else file.path("visual-test-output", repo_label(repo_dir))
limit <- if (length(args) >= 3) as.integer(args[[3]]) else Inf

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/"))
} else {
  "."
}
source(file.path(script_dir, "glass-test-utils.R"))

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || identical(x, "")) y else x

for (pkg in c("shinyglass", "chromote", "processx", "curl", "jsonlite")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(pkg, " is required. Install it before running this script.")
  }
}

dir.create(out_root, recursive = TRUE, showWarnings = FALSE)

chromote_click <- function(session, selector) {
  js <- sprintf("
    (function() {
      const el = document.querySelector(%s);
      if (!el) return false;
      el.scrollIntoView({block: 'center'});
      el.click();
      return true;
    })();
  ", jsonlite::toJSON(selector, auto_unbox = TRUE))

  session$Runtime$evaluate(
    expression = js,
    returnByValue = TRUE,
    timeout = 5000
  )
}

chromote_focus <- function(session, selector) {
  js <- sprintf("
    (function() {
      const el = document.querySelector(%s);
      if (!el) return false;
      el.scrollIntoView({block: 'center'});
      el.focus();
      if (el.tagName === 'SELECT') {
        el.dispatchEvent(new MouseEvent('mousedown', {bubbles: true}));
      }
      return true;
    })();
  ", jsonlite::toJSON(selector, auto_unbox = TRUE))

  session$Runtime$evaluate(
    expression = js,
    returnByValue = TRUE,
    timeout = 5000
  )
}

chromote_collect_selectors <- function(session) {
  js <- "
    (function() {
      const nav = [...document.querySelectorAll('.navbar-nav .nav-link, .nav-tabs .nav-link')]
        .filter(el => el.offsetParent !== null)
        .map(el => ({type: 'nav', text: (el.textContent || '').trim().slice(0,40), selector: uniqueSelector(el)}));
      const buttons = [...document.querySelectorAll('button.btn, .btn.btn-primary, .action-button')]
        .filter(el => el.offsetParent !== null && !el.disabled)
        .slice(0, 3)
        .map(el => ({type: 'button', text: (el.textContent || '').trim().slice(0,40), selector: uniqueSelector(el)}));
      const selects = [...document.querySelectorAll('select.form-select, select.shiny-input-select')]
        .filter(el => el.offsetParent !== null)
        .slice(0, 2)
        .map(el => ({type: 'select', text: (el.id || 'select'), selector: uniqueSelector(el)}));
      function uniqueSelector(el) {
        if (el.id) return '#' + CSS.escape(el.id);
        if (el.className) {
          const cls = [...el.classList].filter(c => !c.startsWith('shiny-')).slice(0,2).join('.');
          if (cls) return el.tagName.toLowerCase() + '.' + cls;
        }
        return el.tagName.toLowerCase();
      }
      return JSON.stringify([...nav.slice(0,5), ...buttons, ...selects]);
    })();
  "

  res <- session$Runtime$evaluate(expression = js, returnByValue = TRUE, timeout = 5000)
  out <- tryCatch(jsonlite::fromJSON(res$result$value), error = function(e) list())
  if (is.data.frame(out)) out else if (length(out) == 0) data.frame() else as.data.frame(out, stringsAsFactors = FALSE)
}

capture_screenshot <- function(session, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  session$set_viewport_size(width = 1400, height = 900)
  session$screenshot(path)
}

slugify <- function(x) {
  x <- gsub("[^a-zA-Z0-9]+", "-", x)
  x <- gsub("^-|-$", "", x)
  tolower(substr(x, 1, 40))
}

test_one_app <- function(app_dir, out_dir, port = 4000L) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  log_path <- file.path(out_dir, "test-log.txt")
  log <- function(...) cat(paste0(..., "\n"), file = log_path, append = TRUE)

  prep <- prepare_patched_app_dir(app_dir)
  if (!prep$ok) {
    log("SKIP: ", prep$reason)
    return(list(status = "skip", reason = prep$reason, shots = 0L))
  }

  url <- sprintf("http://127.0.0.1:%d", port)
  run_expr <- sprintf(
    "shiny::runApp('%s', host='127.0.0.1', port=%d, launch.browser=FALSE)",
    gsub("'", "\\\\'", normalizePath(prep$dir, winslash = "/")),
    port
  )

  proc <- processx::process$new(
    command = normalizePath(Sys.which("Rscript")),
    args = c("-e", run_expr),
    stdout = "|",
    stderr = "|"
  )

  on.exit({
    if (proc$is_alive()) proc$kill()
  }, add = TRUE)

  if (!wait_for_url(url, timeout = 90)) {
    err <- proc$read_all_error()
    log("FAIL: app did not start\n", err)
    return(list(status = "fail", reason = "app did not start", shots = 0L))
  }

  shots <- 0L
  issues <- character()

  b <- chromote::ChromoteSession$new()
  on.exit(b$close(), add = TRUE)

  tryCatch({
    b$go_to(url)
    wait_for_shiny(b, timeout = 45)
    Sys.sleep(1)

    initial <- file.path(out_dir, "01-initial.png")
    capture_screenshot(b, initial)
    shots <- shots + 1L
    log("screenshot: 01-initial.png")

    actions <- chromote_collect_selectors(b)
    step <- 2L

    if (nrow(actions) > 0) {
      for (i in seq_len(nrow(actions))) {
        row <- actions[i, , drop = FALSE]
        label <- slugify(paste(row$type, row$text))
        fname <- sprintf("%02d-%s.png", step, label)

        ok <- FALSE
        if (row$type == "select") {
          ok <- isTRUE(chromote_focus(b, row$selector)$result$value)
        } else {
          ok <- isTRUE(chromote_click(b, row$selector)$result$value)
        }

        if (!ok) {
          log("interaction miss: ", row$type, " ", row$text)
          next
        }

        Sys.sleep(1.2)
        capture_screenshot(b, file.path(out_dir, fname))
        shots <- shots + 1L
        log("screenshot: ", fname, " (", row$type, ": ", row$text, ")")
        step <- step + 1L
      }
    }

    # Scroll pass for long pages
    b$Runtime$evaluate("window.scrollTo(0, document.body.scrollHeight * 0.5);")
    Sys.sleep(0.5)
    scrolled <- file.path(out_dir, sprintf("%02d-scrolled.png", step))
    capture_screenshot(b, scrolled)
    shots <- shots + 1L
    log("screenshot: scrolled")

  }, error = function(e) {
    issues <<- c(issues, conditionMessage(e))
    log("ERROR: ", conditionMessage(e))
  })

  if (length(issues)) {
    return(list(status = "partial", reason = paste(issues, collapse = "; "), shots = shots))
  }
  list(status = "pass", reason = NA_character_, shots = shots)
}

app_dirs <- discover_app_dirs(repo_dir)
if (is.finite(limit)) app_dirs <- head(app_dirs, limit)

message("Visual testing ", length(app_dirs), " apps from ", repo_label(repo_dir))
message("Output: ", normalizePath(out_root))

results <- data.frame(
  app = basename(app_dirs),
  status = character(length(app_dirs)),
  reason = character(length(app_dirs)),
  shots = integer(length(app_dirs)),
  stringsAsFactors = FALSE
)

base_port <- 4100L
for (i in seq_along(app_dirs)) {
  app <- basename(app_dirs[[i]])
  message("[", i, "/", length(app_dirs), "] ", app)
  out_dir <- file.path(out_root, app)
  res <- test_one_app(app_dirs[[i]], out_dir, port = base_port + i)
  results$status[i] <- res$status
  results$reason[i] <- res$reason %||% ""
  results$shots[i] <- res$shots
}

report_path <- file.path(out_root, "REPORT.md")
lines <- c(
  paste0("# shinyglass visual test — ", repo_label(repo_dir)),
  "",
  paste0("- Repo: `", repo_dir, "`"),
  paste0("- Date: ", Sys.time()),
  paste0("- Apps tested: ", nrow(results)),
  paste0("- Screenshots taken: ", sum(results$shots)),
  "",
  "## Summary",
  "",
  paste0("| Status | Count |"),
  paste0("|--------|-------|"),
  paste0("| pass | ", sum(results$status == "pass"), " |"),
  paste0("| partial | ", sum(results$status == "partial"), " |"),
  paste0("| fail | ", sum(results$status == "fail"), " |"),
  paste0("| skip | ", sum(results$status == "skip"), " |"),
  "",
  "## Apps",
  "",
  "| App | Status | Screenshots | Notes |",
  "|-----|--------|-------------|-------|"
)

for (i in seq_len(nrow(results))) {
  lines <- c(lines, sprintf(
    "| %s | %s | %d | %s |",
    results$app[i],
    results$status[i],
    results$shots[i],
    gsub("\\|", "/", results$reason[i], fixed = FALSE)
  ))
}

lines <- c(lines, "", "## Review checklist", "",
  "For each app folder, inspect screenshots in order:",
  "1. `01-initial.png` — glass surfaces, background, typography",
  "2. Interaction shots — nav tabs, buttons, select menus",
  "3. `*-scrolled.png` — layout at scroll midpoint",
  "",
  "**Watch for:** select dropdown bleed-through, low contrast text, broken",
  "layouts in sidebars/cards/datatables, modals, and dark-on-glass issues."
)

writeLines(lines, report_path)
write.csv(results, file.path(out_root, "results.csv"), row.names = FALSE)

cat("\nDone. Report:", normalizePath(report_path), "\n")
print(table(results$status))