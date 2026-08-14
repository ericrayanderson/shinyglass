#!/usr/bin/env Rscript
# Dual-theme glass contrast + structure audit for curated demos.
#
# Catches the class of bug where we style a wrapper node and Bootstrap paints
# the visible child (e.g. DT .paginate_button vs .page-link), plus solid-fill
# ink failures and Bootstrap light greys leaking into dark mode.
#
# Usage (from package root):
#   Rscript inst/scripts/audit-glass-contrast.R
#   Rscript inst/scripts/audit-glass-contrast.R --apps=dashboard,inputs,chrome --presets=dark
#   Rscript inst/scripts/audit-glass-contrast.R --min-contrast=3 --json=audit.json
#   Rscript inst/scripts/audit-glass-contrast.R --apps=chrome --screenshot-dir=visual-test-output/chrome
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
apps_arg <- get_flag("--apps", "demo,dashboard,inputs,plotly_gt,chrome")
presets_arg <- get_flag("--presets", "light,dark")
json_out <- get_flag("--json", NULL)
screenshot_dir <- get_flag("--screenshot-dir", NULL)
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

# CI / root containers: Chrome refuses to start without these, and the first
# session can flake with "debugging port not open after 10 seconds".
chromote::set_chrome_args(unique(c(
  chromote::default_chrome_args(),
  "--no-sandbox",
  "--disable-dev-shm-usage",
  "--disable-gpu"
)))

open_chromote_session <- function(attempts = 4L) {
  last <- NULL
  for (i in seq_len(attempts)) {
    sess <- tryCatch(chromote::ChromoteSession$new(), error = function(e) e)
    if (!inherits(sess, "error")) {
      return(sess)
    }
    last <- sess
    Sys.sleep(1.25 * i)
  }
  stop(last)
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
      ),
      list(
        name = "focus-dt-length",
        js = "
          (function() {
            const sel = document.querySelector('.dataTables_length select');
            if (!sel) return false;
            sel.focus();
            return true;
          })();
        ",
        wait_ms = 200
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
        wait_ms = 500,
        sample = TRUE
      ),
      list(
        name = "open-datepicker",
        js = "
          (function() {
            return new Promise((resolve) => {
              const start = Date.now();
              const tick = () => {
                const el = document.querySelector('#date input, .shiny-date-input input');
                const $ = window.jQuery || window.$;
                const method = $ && $.fn && ($.fn.bsDatepicker ? 'bsDatepicker' : ($.fn.datepicker ? 'datepicker' : null));
                if (el && method) {
                  el.scrollIntoView({block: 'center'});
                  $(el)[method]('show');
                  resolve(true);
                  return;
                }
                if (Date.now() - start > 8000) { resolve(false); return; }
                setTimeout(tick, 150);
              };
              tick();
            });
          })();
        ",
        wait_ms = 500,
        sample = TRUE,
        expect = ".datepicker-dropdown, .datepicker[style*='display: block']"
      ),
      list(
        name = "open-modal",
        js = "
          (function() {
            const btn = document.getElementById('show_modal');
            if (btn) { btn.click(); return true; }
            return false;
          })();
        ",
        wait_ms = 400,
        sample = TRUE,
        expect = ".modal.show, .modal-content"
      ),
      list(
        name = "show-notification",
        js = "
          (function() {
            if (window.Shiny && Shiny.setInputValue) {
              Shiny.setInputValue('action', Date.now(), {priority: 'event'});
              return true;
            }
            const btn = document.getElementById('action');
            if (btn) { btn.click(); return true; }
            return false;
          })();
        ",
        wait_ms = 400,
        sample = TRUE
      )
    )
  ),
  chrome = list(
    label = "chrome-kitchen-sink",
    path = file.path(pkg_root, "inst", "examples", "chrome-kitchen-sink.R"),
    needs = character(),
    wait = c("#date", "#notify_message", ".navbar"),
    extra_selectors = c(
      ".datepicker",
      ".datepicker .day",
      ".datepicker .day.active",
      ".datepicker-switch",
      ".shiny-notification",
      ".shiny-notification-message",
      ".shiny-notification-warning",
      ".shiny-notification-error",
      ".btn-close",
      ".accordion-button",
      ".accordion-button:not(.collapsed)",
      ".accordion-body",
      ".tooltip-inner",
      ".popover",
      ".popover-body",
      ".dropdown-menu.show, .navbar-nav .dropdown-menu",
      ".nav-pills .nav-link.active",
      ".form-select[multiple]",
      ".btn-file, .shiny-input-container:has(input[type='file']) .btn",
      ".modal-content",
      ".well"
    ),
    interactions = list(
      list(
        name = "open-datepicker",
        js = "
          (function() {
            return new Promise((resolve) => {
              const start = Date.now();
              const tick = () => {
                const el = document.querySelector('#date input, .shiny-date-input input');
                const $ = window.jQuery || window.$;
                const method = $ && $.fn && ($.fn.bsDatepicker ? 'bsDatepicker' : ($.fn.datepicker ? 'datepicker' : null));
                if (el && method) {
                  el.scrollIntoView({block: 'center'});
                  $(el)[method]('show');
                  resolve(true);
                  return;
                }
                if (Date.now() - start > 8000) { resolve(false); return; }
                setTimeout(tick, 150);
              };
              tick();
            });
          })();
        ",
        wait_ms = 500,
        sample = TRUE,
        expect = ".datepicker-dropdown, .datepicker[style*='display: block']"
      ),
      list(
        name = "close-datepicker",
        js = "
          (function() {
            const $ = window.jQuery || window.$;
            const el = document.querySelector('#date input, .shiny-date-input input');
            const method = $ && $.fn && ($.fn.bsDatepicker ? 'bsDatepicker' : ($.fn.datepicker ? 'datepicker' : null));
            if (el && method) { $(el)[method]('hide'); }
            document.body.click();
            return true;
          })();
        ",
        wait_ms = 200
      ),
      list(
        name = "open-navbar-menu",
        js = "
          (function() {
            const tog = document.querySelector('.navbar-nav .dropdown-toggle');
            if (!tog) return false;
            tog.click();
            return true;
          })();
        ",
        wait_ms = 400,
        sample = TRUE,
        expect = ".dropdown-menu.show, .navbar-nav .dropdown-menu"
      ),
      list(
        name = "close-navbar-menu",
        js = "
          (function() {
            const tog = document.querySelector('.navbar-nav .dropdown-toggle');
            if (tog) tog.click();
            return true;
          })();
        ",
        wait_ms = 200
      ),
      list(
        name = "show-notifications",
        js = "
          (function() {
            const ids = ['notify_default','notify_message','notify_warning','notify_error'];
            let n = 0;
            ids.forEach((id) => {
              if (window.Shiny && Shiny.setInputValue) {
                Shiny.setInputValue(id, Date.now() + Math.random(), {priority: 'event'});
                n++;
              } else {
                const b = document.getElementById(id);
                if (b) { b.click(); n++; }
              }
            });
            return n > 0;
          })();
        ",
        wait_ms = 700,
        sample = TRUE,
        expect = ".shiny-notification"
      ),
      list(
        name = "nav-bslib",
        js = "
          (function() {
            const link = Array.from(document.querySelectorAll('.navbar .nav-link, .nav-link'))
              .find((el) => (el.textContent || '').trim() === 'bslib');
            if (!link) return false;
            link.click();
            return true;
          })();
        ",
        wait_ms = 400
      ),
      list(
        name = "open-accordion",
        js = "
          (function() {
            const btns = document.querySelectorAll('.accordion-button');
            if (btns.length < 2) return false;
            btns[1].scrollIntoView({block: 'center'});
            btns[1].click();
            return true;
          })();
        ",
        wait_ms = 400,
        sample = TRUE,
        expect = ".accordion-button"
      ),
      list(
        name = "show-tooltip",
        js = "
          (function() {
            const el = document.getElementById('tip_btn');
            if (!el) return false;
            el.scrollIntoView({block: 'center'});
            if (window.bootstrap && bootstrap.Tooltip) {
              const inst = bootstrap.Tooltip.getOrCreateInstance(el);
              inst.show();
              return true;
            }
            el.dispatchEvent(new MouseEvent('mouseenter', {bubbles: true}));
            el.focus();
            return true;
          })();
        ",
        wait_ms = 400,
        sample = TRUE
      ),
      list(
        name = "open-popover",
        js = "
          (function() {
            const el = document.getElementById('pop_btn');
            if (!el) return false;
            el.scrollIntoView({block: 'center'});
            if (window.bootstrap && bootstrap.Popover) {
              const inst = bootstrap.Popover.getOrCreateInstance(el);
              inst.show();
              return true;
            }
            el.click();
            return true;
          })();
        ",
        wait_ms = 400,
        sample = TRUE
      ),
      list(
        name = "show-modal",
        js = "
          (function() {
            if (window.Shiny && Shiny.setInputValue) {
              Shiny.setInputValue('show_server_modal', Date.now(), {priority: 'event'});
              return true;
            }
            const b = document.getElementById('show_server_modal');
            if (b) { b.click(); return true; }
            return false;
          })();
        ",
        wait_ms = 600,
        sample = TRUE,
        expect = ".modal.show, .modal-content"
      ),
      list(
        name = "intensity-clear",
        js = "
          (function() {
            if (window.shinyglass && window.shinyglass.setIntensity) {
              window.shinyglass.setIntensity(0);
              return true;
            }
            return false;
          })();
        ",
        wait_ms = 350,
        sample = TRUE
      ),
      list(
        name = "intensity-tinted",
        js = "
          (function() {
            if (window.shinyglass && window.shinyglass.setIntensity) {
              window.shinyglass.setIntensity(1);
              return true;
            }
            return false;
          })();
        ",
        wait_ms = 350,
        sample = TRUE
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
  ".datepicker",
  ".datepicker .day",
  ".btn-close",
  ".accordion-button",
  ".dropdown-menu.show",
  ".modal-content",
  ".tooltip-inner",
  ".popover",
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

normalize_findings <- function(fr) {
  if (is.null(fr)) return(list())
  if (is.data.frame(fr)) {
    return(lapply(seq_len(nrow(fr)), function(i) as.list(fr[i, ])))
  }
  if (!is.list(fr)) return(list())
  if (!is.null(fr$level) && is.character(fr$level) && length(fr$level) == 1) {
    return(list(fr))
  }
  fr
}

selectors_for <- function(spec) {
  extra <- spec$extra_selectors %||% character()
  unique(c(core_selectors, extra))
}

run_audit_js <- function(session, selectors, preset) {
  inject <- paste0(
    audit_js,
    "\n; runGlassAudit(",
    jsonlite::toJSON(selectors), ", ",
    jsonlite::toJSON(preset, auto_unbox = TRUE), ", ",
    jsonlite::toJSON(min_contrast, auto_unbox = TRUE),
    ");"
  )
  result <- session$Runtime$evaluate(
    expression = inject,
    returnByValue = TRUE,
    timeout = 20000
  )
  result$result$value
}

maybe_screenshot <- function(session, app_key, preset, phase) {
  if (is.null(screenshot_dir) || !nzchar(screenshot_dir)) return(invisible(NULL))
  dir.create(screenshot_dir, recursive = TRUE, showWarnings = FALSE)
  dest <- file.path(
    screenshot_dir,
    sprintf("%s-%s-%s.png", app_key, preset, gsub("[^A-Za-z0-9_-]+", "-", phase))
  )
  tryCatch(
    session$screenshot(filename = dest, selector = "html"),
    error = function(e) {
      try(session$screenshot(filename = dest), silent = TRUE)
    }
  )
  invisible(dest)
}

expect_present <- function(session, selector) {
  if (is.null(selector) || !nzchar(selector)) return(TRUE)
  js <- sprintf(
    "(function(){
      try {
        const el = document.querySelector(%s);
        if (!el) return false;
        const cs = getComputedStyle(el);
        if (cs.display === 'none' || cs.visibility === 'hidden' || Number(cs.opacity) === 0) return false;
        const r = el.getBoundingClientRect();
        return r.width > 2 && r.height > 2;
      } catch(e) { return false; }
    })();",
    jsonlite::toJSON(selector, auto_unbox = TRUE)
  )
  out <- tryCatch(
    session$Runtime$evaluate(expression = js, returnByValue = TRUE),
    error = function(e) NULL
  )
  isTRUE(out$result$value)
}

run_case <- function(app_key, preset, port) {
  spec <- catalog[[app_key]]
  findings <- list()
  meta <- list(app = app_key, label = spec$label, preset = preset, port = port)
  sels <- selectors_for(spec)
  last_preset <- preset

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

  b <- open_chromote_session()
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

  collect_sample <- function(phase, keep_all = FALSE) {
    val <- tryCatch(
      run_audit_js(b, sels, preset),
      error = function(e) NULL
    )
    maybe_screenshot(b, app_key, preset, phase)
    if (is.null(val) || is.null(val$findings)) {
      return(list(list(
        level = "FAIL",
        code = "audit-js-failed",
        message = paste("Browser audit returned no findings payload at", phase),
        meta = list(phase = phase)
      )))
    }
    last_preset <<- val$preset %||% preset
    rows <- normalize_findings(val$findings)
    if (!keep_all) {
      rows <- Filter(function(r) {
        toupper(as.character(r$level %||% "")) %in% c("FAIL", "WARN")
      }, rows)
    }
    lapply(rows, function(r) {
      r$meta <- c(r$meta %||% list(), list(phase = phase))
      r
    })
  }

  # interactions — sample open-state overlays when requested
  for (ix in spec$interactions) {
    phase <- ix$name %||% "interaction"
    tryCatch({
      b$Runtime$evaluate(
        expression = ix$js,
        returnByValue = TRUE,
        awaitPromise = TRUE,
        timeout = 15000
      )
      Sys.sleep((ix$wait_ms %||% 500) / 1000)
      if (!is.null(ix$expect) && !expect_present(b, ix$expect)) {
        findings <<- c(findings, list(list(
          level = "WARN",
          code = "expect-missing",
          message = paste(phase, "did not reveal", ix$expect),
          meta = list(phase = phase, expect = ix$expect)
        )))
      }
      if (isTRUE(ix$sample)) {
        findings <<- c(findings, collect_sample(phase, keep_all = FALSE))
      }
    }, error = function(e) {
      findings <<- c(findings, list(list(
        level = "WARN",
        code = "interaction-failed",
        message = paste(phase, conditionMessage(e)),
        meta = list()
      )))
    })
  }

  findings <- c(findings, collect_sample("final", keep_all = TRUE))

  list(meta = meta, findings = findings, glass_preset = last_preset)
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
    ),
    list(
      code = "scss-datepicker",
      ok = grepl(".datepicker", scss, fixed = TRUE) &&
        grepl("datepicker-dropdown", scss, fixed = TRUE),
      message = "glass.scss must style bootstrap-datepicker popup"
    ),
    list(
      code = "scss-notification",
      ok = grepl(".shiny-notification", scss, fixed = TRUE) &&
        grepl("shiny-notification-warning", scss, fixed = TRUE),
      message = "glass.scss must style Shiny notification types"
    ),
    list(
      code = "scss-btn-close",
      ok = grepl(".btn-close", scss, fixed = TRUE),
      message = "glass.scss must style Bootstrap .btn-close"
    ),
    list(
      code = "scss-accordion",
      ok = grepl("\n.accordion-button", scss, fixed = TRUE),
      message = "glass.scss must style generic .accordion-button (not teal-only)"
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
