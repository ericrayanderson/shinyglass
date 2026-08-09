#!/usr/bin/env Rscript
# Dual-theme glass contrast + structure audit for curated demos.
#
# Catches the class of bug where we style a wrapper node and Bootstrap paints
# the visible child (e.g. DT .paginate_button vs .page-link), plus solid-fill
# ink failures and Bootstrap light greys leaking into dark mode.
#
# Usage (from package root):
#   Rscript inst/scripts/audit-glass-contrast.R
#   Rscript inst/scripts/audit-glass-contrast.R --apps=dashboard,inputs --presets=dark
#   Rscript inst/scripts/audit-glass-contrast.R --min-contrast=3 --json=audit.json
#
# Exit code 1 if any FAIL findings; 0 if only PASS/WARN/SKIP.
#
# Requires: shinyglass (or pkgload), shiny, chromote, processx, curl.
# Optional apps skip when Suggests packages are missing (DT, ggplot2, …).

args <- commandArgs(trailingOnly = TRUE)

get_flag <- function(flag, default = NULL) {
  hit <- grep(paste0("^", flag, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^", flag, "="), "", hit[[1]])
}

has_flag <- function(flag) any(args == flag)

min_contrast <- as.numeric(get_flag("--min-contrast", "3"))
if (is.na(min_contrast) || min_contrast <= 0) min_contrast <- 3
apps_arg <- get_flag("--apps", "demo,dashboard,inputs,plotly_gt")
presets_arg <- get_flag("--presets", "light,dark")
json_out <- get_flag("--json", NULL)
port_base <- as.integer(get_flag("--port-base", "3910"))
if (is.na(port_base)) port_base <- 3910L

app_keys <- trimws(strsplit(apps_arg, ",", fixed = TRUE)[[1]])
presets <- trimws(strsplit(presets_arg, ",", fixed = TRUE)[[1]])
presets <- match.arg(presets, c("light", "dark"), several.ok = TRUE)

for (pkg in c("chromote", "processx", "curl", "jsonlite")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Install ", pkg, " first: install.packages(\"", pkg, "\")", call. = FALSE)
  }
}

script_path <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1]
)
if (!is.na(script_path) && nzchar(script_path)) {
  pkg_root <- normalizePath(file.path(dirname(script_path), "..", ".."), winslash = "/")
} else {
  pkg_root <- normalizePath(".", winslash = "/")
}

if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(pkg_root, quiet = TRUE)
} else if (requireNamespace("shinyglass", quietly = TRUE)) {
  # use installed package
} else {
  stop("Need pkgload::load_all() or installed shinyglass", call. = FALSE)
}

`%||%` <- function(x, y) {
  if (is.null(x) || !length(x) || (is.character(x) && !nzchar(x[[1]]))) y else x
}

catalog <- list(
  demo = list(
    label = "demo-app",
    path = file.path(pkg_root, "inst", "examples", "demo-app.R"),
    needs = character(),
    wait = c("#dist_plot img", ".shiny-bound-input"),
    interactions = list()
  ),
  dashboard = list(
    label = "bslib-dashboard",
    path = file.path(pkg_root, "inst", "examples", "bslib-dashboard.R"),
    needs = c("ggplot2", "DT"),
    wait = c("#dist_plot img", "#metric_n", ".dataTables_paginate .page-link"),
    interactions = list(
      list(
        name = "open-dt-page-2",
        js = "
          (function() {
            const link = Array.from(document.querySelectorAll('.dataTables_paginate .page-link'))
              .find((el) => el.textContent.trim() === '2');
            if (link) { link.click(); return true; }
            return false;
          })();
        ",
        wait_ms = 800
      )
    )
  ),
  inputs = list(
    label = "inputs-gallery",
    path = file.path(pkg_root, "inst", "examples", "inputs-gallery.R"),
    needs = character(),
    wait = c("#text", ".btn-primary", ".irs-single"),
    interactions = list(
      list(
        name = "open-selectize",
        js = "
          (function() {
            const inp = document.querySelector('.selectize-input');
            if (!inp) return false;
            inp.click();
            return true;
          })();
        ",
        wait_ms = 500
      ),
      list(
        name = "show-notification",
        js = "
          (function() {
            if (window.Shiny && Shiny.notifications) {
              // server-driven preferred; client fallback banner
            }
            if (window.Shiny && Shiny.setInputValue) {
              Shiny.setInputValue('action', Date.now(), {priority: 'event'});
              return true;
            }
            const btn = document.getElementById('action');
            if (btn) { btn.click(); return true; }
            return false;
          })();
        ",
        wait_ms = 400
      )
    )
  ),
  shinywidgets = list(
    label = "shinywidgets-gallery",
    path = file.path(pkg_root, "inst", "examples", "shinywidgets-gallery-glass.R"),
    needs = c("shinyWidgets"),
    wait = c(".shiny-bound-input", "body"),
    interactions = list()
  ),
  plotly_gt = list(
    label = "plotly-gt-demo",
    path = file.path(pkg_root, "inst", "examples", "plotly-gt-demo.R"),
    needs = c("plotly", "gt"),
    wait = c(".js-plotly-plot", ".gt_table", ".shiny-bound-input"),
    interactions = list(
      list(
        name = "hover-modebar",
        js = "
          (function() {
            const btn = document.querySelector('.modebar-btn');
            if (btn) { btn.dispatchEvent(new MouseEvent('mouseenter', {bubbles:true})); return true; }
            return false;
          })();
        ",
        wait_ms = 300
      )
    )
  )
)

unknown <- setdiff(app_keys, names(catalog))
if (length(unknown)) {
  stop(
    "Unknown apps: ", paste(unknown, collapse = ", "),
    "\nChoose from: ", paste(names(catalog), collapse = ", "),
    call. = FALSE
  )
}

# Selectors sampled on every app (missing → SKIP, not FAIL)
core_selectors <- c(
  "body",
  ".btn-primary",
  ".btn-secondary",
  ".form-control",
  ".form-select",
  ".form-check-input:checked",
  ".navbar",
  ".card",
  ".selectize-input",
  ".selectize-dropdown",
  ".irs-single",
  ".irs-bar",
  ".dataTables_paginate .page-link",
  ".page-item.active .page-link",
  ".page-item.disabled .page-link",
  ".paginate_button.current .page-link",
  ".value-box.bg-primary, .bslib-value-box .bg-primary, .bg-primary.value-box, [class*='value-box'] .bg-primary, .bslib-value-box.bg-primary",
  ".bg-primary",
  ".bg-success",
  ".bg-info",
  ".nav-tabs .nav-link.active",
  ".shiny-notification",
  ".js-plotly-plot",
  ".modebar",
  ".modebar-btn",
  ".gt_table",
  ".gt_col_heading",
  ".gt_row",
  ".waiter-overlay",
  ".swal2-popup"
)

audit_js_path <- file.path(pkg_root, "inst", "scripts", "audit-glass-contrast.js")
if (!file.exists(audit_js_path)) {
  stop("Missing ", audit_js_path, call. = FALSE)
}
audit_js <- paste(readLines(audit_js_path, warn = FALSE), collapse = "\n")

wait_ready <- function(session, selectors, timeout = 45) {
  sel_json <- jsonlite::toJSON(selectors, auto_unbox = FALSE)
  js <- sprintf("
    new Promise((resolve) => {
      const deadline = Date.now() + %d;
      const sels = %s;
      const check = () => {
        const bound = document.querySelectorAll('.shiny-bound-input, .shiny-bound-output').length > 0;
        const ok = sels.every((s) => {
          try { return !!document.querySelector(s); } catch (e) { return true; }
        });
        if (bound && ok) { resolve(true); return; }
        if (Date.now() > deadline) { resolve(false); return; }
        setTimeout(check, 250);
      };
      check();
    });
  ", as.integer(timeout * 1000), sel_json)
  out <- session$Runtime$evaluate(
    expression = js,
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = (timeout + 5) * 1000
  )
  isTRUE(out$result$value)
}

launch_app <- function(app_path, port, preset) {
  url <- sprintf("http://127.0.0.1:%d", port)
  launch <- sprintf(
    paste(
      "if (requireNamespace('pkgload', quietly = TRUE)) {",
      "  pkgload::load_all(%s, quiet = TRUE)",
      "} else {",
      "  library(shinyglass)",
      "}",
      "shiny::runApp(%s, host = '127.0.0.1', port = %d, launch.browser = FALSE)",
      sep = "; "
    ),
    deparse(pkg_root),
    deparse(normalizePath(app_path, winslash = "/")),
    as.integer(port)
  )
  env <- Sys.getenv()
  env[["SHINYGLASS_PRESET"]] <- preset
  proc <- processx::process$new(
    command = normalizePath(Sys.which("Rscript")),
    args = c("-e", launch),
    env = env,
    stdout = "|",
    stderr = "|"
  )
  ready <- FALSE
  for (i in seq_len(90)) {
    if (!proc$is_alive()) {
      err <- proc$read_all_error()
      stop("App exited early (", basename(app_path), "):\n", err, call. = FALSE)
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
    if (proc$is_alive()) proc$kill()
    stop("Timed out waiting for ", url, call. = FALSE)
  }
  list(proc = proc, url = url)
}

run_case <- function(app_key, preset, port) {
  spec <- catalog[[app_key]]
  findings <- list()
  meta <- list(app = app_key, label = spec$label, preset = preset, port = port)

  missing <- spec$needs[!vapply(spec$needs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    return(list(
      meta = meta,
      findings = list(list(
        level = "SKIP",
        code = "deps",
        message = paste("missing packages:", paste(missing, collapse = ", ")),
        meta = list()
      ))
    ))
  }
  if (!file.exists(spec$path)) {
    return(list(
      meta = meta,
      findings = list(list(
        level = "SKIP",
        code = "missing-app",
        message = paste("file not found:", spec$path),
        meta = list()
      ))
    ))
  }

  launched <- launch_app(spec$path, port, preset)
  proc <- launched$proc
  on.exit({
    if (proc$is_alive()) try(proc$kill(tree = TRUE), silent = TRUE)
  }, add = TRUE)

  b <- chromote::ChromoteSession$new()
  on.exit(try(b$close(), silent = TRUE), add = TRUE)
  b$set_viewport_size(width = 1400L, height = 900L)
  b$go_to(launched$url)
  Sys.sleep(1.5)
  ready <- tryCatch(
    wait_ready(b, spec$wait, timeout = 50),
    error = function(e) FALSE
  )
  if (!ready) {
    findings <- c(findings, list(list(
      level = "WARN",
      code = "ready-timeout",
      message = "UI readiness wait timed out; auditing anyway",
      meta = list(wait = spec$wait)
    )))
  }

  # interactions
  for (ix in spec$interactions) {
    tryCatch({
      b$Runtime$evaluate(expression = ix$js, returnByValue = TRUE)
      Sys.sleep((ix$wait_ms %||% 500) / 1000)
    }, error = function(e) {
      findings <<- c(findings, list(list(
        level = "WARN",
        code = "interaction-failed",
        message = paste(ix$name, conditionMessage(e)),
        meta = list()
      )))
    })
  }

  # inject audit functions + run
  inject <- paste0(
    audit_js,
    "\n; runGlassAudit(",
    jsonlite::toJSON(core_selectors), ", ",
    jsonlite::toJSON(preset, auto_unbox = TRUE), ", ",
    jsonlite::toJSON(min_contrast, auto_unbox = TRUE),
    ");"
  )
  result <- b$Runtime$evaluate(
    expression = inject,
    returnByValue = TRUE,
    timeout = 20000
  )
  val <- result$result$value
  if (is.null(val) || is.null(val$findings)) {
    findings <- c(findings, list(list(
      level = "FAIL",
      code = "audit-js-failed",
      message = "Browser audit returned no findings payload",
      meta = list()
    )))
  } else {
    # normalize list of findings
    fr <- val$findings
    if (is.data.frame(fr)) {
      # chromote sometimes simplifies
      findings <- c(findings, lapply(seq_len(nrow(fr)), function(i) {
        as.list(fr[i, ])
      }))
    } else if (is.list(fr)) {
      # may be named list of single finding or list of findings
      if (!is.null(fr$level) && is.character(fr$level) && length(fr$level) == 1) {
        findings <- c(findings, list(fr))
      } else {
        findings <- c(findings, fr)
      }
    }
  }

  list(meta = meta, findings = findings, glass_preset = val$preset %||% preset)
}

# Static SCSS structure checks (no browser)
scss_path <- file.path(pkg_root, "inst", "scss", "glass.scss")
static_findings <- list()
if (file.exists(scss_path)) {
  scss <- paste(readLines(scss_path, warn = FALSE), collapse = "\n")
  checks <- list(
    list(
      code = "scss-dt-page-link",
      ok = grepl("dataTables_paginate", scss, fixed = TRUE) &&
        grepl("\\.page-link", scss),
      message = "glass.scss must style .dataTables_paginate .page-link (visible DT surface)"
    ),
    list(
      code = "scss-page-item-active",
      ok = grepl("page-item.active", scss, fixed = TRUE) ||
        grepl("page-item\\.active", scss),
      message = "glass.scss must style .page-item.active .page-link"
    ),
    list(
      code = "scss-disabled-page",
      ok = grepl("page-item.disabled", scss, fixed = TRUE) ||
        grepl("paginate_button.disabled", scss, fixed = TRUE),
      message = "glass.scss must style disabled pagination chips"
    ),
    list(
      code = "scss-value-box-ink",
      ok = grepl("glass-on", scss, fixed = TRUE) && grepl("value-box", scss),
      message = "glass.scss must set value-box / solid fill ink"
    ),
    list(
      code = "scss-form-check",
      ok = grepl("form-check-input", scss, fixed = TRUE),
      message = "glass.scss must style form-check-input checked states"
    )
  )
  for (ch in checks) {
    static_findings <- c(static_findings, list(list(
      level = if (ch$ok) "PASS" else "FAIL",
      code = ch$code,
      message = ch$message,
      meta = list(file = "inst/scss/glass.scss")
    )))
  }
} else {
  static_findings <- list(list(
    level = "FAIL",
    code = "scss-missing",
    message = "inst/scss/glass.scss not found",
    meta = list()
  ))
}

all_rows <- list()
port <- port_base
case_i <- 0L

message("== shinyglass contrast audit ==")
message("apps: ", paste(app_keys, collapse = ", "))
message("presets: ", paste(presets, collapse = ", "))
message("min contrast: ", min_contrast)
message("static SCSS checks: ", length(static_findings))

for (f in static_findings) {
  all_rows <- c(all_rows, list(c(
    list(app = "_static", preset = "-", label = "scss"),
    f
  )))
}

for (app_key in app_keys) {
  for (preset in presets) {
    case_i <- case_i + 1L
    port <- port_base + case_i
    message(sprintf("\n→ %s @ %s (port %d)", catalog[[app_key]]$label, preset, port))
    res <- tryCatch(
      run_case(app_key, preset, port),
      error = function(e) {
        list(
          meta = list(app = app_key, label = catalog[[app_key]]$label, preset = preset),
          findings = list(list(
            level = "FAIL",
            code = "run-error",
            message = conditionMessage(e),
            meta = list()
          ))
        )
      }
    )
    for (f in res$findings) {
      if (!is.list(f)) next
      row <- c(
        list(
          app = res$meta$app %||% app_key,
          label = res$meta$label %||% app_key,
          preset = res$meta$preset %||% preset
        ),
        f
      )
      all_rows <- c(all_rows, list(row))
    }
  }
}

level_of <- function(row) toupper(as.character(row$level %||% "WARN"))

n_fail <- sum(vapply(all_rows, function(r) level_of(r) == "FAIL", logical(1)))
n_warn <- sum(vapply(all_rows, function(r) level_of(r) == "WARN", logical(1)))
n_pass <- sum(vapply(all_rows, function(r) level_of(r) == "PASS", logical(1)))
n_skip <- sum(vapply(all_rows, function(r) level_of(r) == "SKIP", logical(1)))

# Print failures and warnings first
message("\n== findings ==")
for (row in all_rows) {
  lv <- level_of(row)
  if (!lv %in% c("FAIL", "WARN")) next
  msg <- row$message %||% row$code %||% "?"
  message(sprintf(
    "[%s] %s/%s %s — %s",
    lv,
    row$app %||% "?",
    row$preset %||% "?",
    row$code %||% "",
    msg
  ))
}

message(sprintf(
  "\n== summary ==\nFAIL %d  WARN %d  PASS %d  SKIP %d  total %d",
  n_fail, n_warn, n_pass, n_skip, length(all_rows)
))

if (!is.null(json_out) && nzchar(json_out)) {
  # simplify for JSON
  payload <- lapply(all_rows, function(r) {
    list(
      app = r$app,
      label = r$label,
      preset = r$preset,
      level = level_of(r),
      code = r$code,
      message = r$message,
      meta = r$meta
    )
  })
  jsonlite::write_json(
    list(
      min_contrast = min_contrast,
      summary = list(fail = n_fail, warn = n_warn, pass = n_pass, skip = n_skip),
      findings = payload
    ),
    json_out,
    auto_unbox = TRUE,
    pretty = TRUE
  )
  message("Wrote ", json_out)
}

if (n_fail > 0) {
  message("\nAudit FAILED")
  quit(status = 1)
}
message("\nAudit OK")
quit(status = 0)
