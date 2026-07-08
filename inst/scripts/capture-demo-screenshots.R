#!/usr/bin/env Rscript
# Capture README / pkgdown screenshots for bundled example apps.

suppressPackageStartupMessages({
  library(processx)
  library(chromote)
  library(curl)
})

wait_for_shiny <- function(
    session,
    timeout = 45,
    min_rows = 1L,
    mode = c("default", "querychat"),
    filtered = FALSE) {
  mode <- match.arg(mode)
  metric_sel <- if (mode == "querychat") {
    "#metric_n, #metric_species, #metric_petal"
  } else {
    "#metric_n, #metric_species, #metric_sepal, #metric_petal"
  }
  extra_checks <- if (mode == "querychat") {
    if (isTRUE(filtered)) {
      "
        const sql = document.querySelector('#sql_query');
        const sqlReady = sql && /setosa/i.test(sql.textContent);
        const metricsNumeric = metricN && metricSpecies && metricPetal &&
          /\\d/.test(metricN.textContent) &&
          /\\d/.test(metricSpecies.textContent) &&
          /\\d/.test(metricPetal.textContent);
        if (!sqlReady || !metricsNumeric) {
          if (Date.now() > deadline) { resolve(false); return; }
          setTimeout(check, 300);
          return;
        }
      "
    } else {
      "
        const sql = document.querySelector('#sql_query');
        const sqlReady = sql && sql.textContent.trim().length > 0;
        const metricsNumeric = metricN && metricSpecies && metricPetal &&
          /\\d/.test(metricN.textContent) &&
          /\\d/.test(metricSpecies.textContent) &&
          /\\d/.test(metricPetal.textContent);
        if (!sqlReady || !metricsNumeric) {
          if (Date.now() > deadline) { resolve(false); return; }
          setTimeout(check, 300);
          return;
        }
      "
    }
  } else {
    ""
  }
  js <- sprintf("
    new Promise((resolve) => {
      const deadline = Date.now() + %d;
      const minRows = %d;
      const check = () => {
        const plotImg = document.querySelector(
          '#hero_plot img, #dist_plot img, #scatter_plot img, #species_plot img, .shiny-plot-output img'
        );
        const plotReady = plotImg && plotImg.complete && plotImg.naturalWidth > 0;
        const tableRows = document.querySelectorAll('.dataTables_wrapper tbody tr').length;
        const metricN = document.querySelector('#metric_n');
        const metricSpecies = document.querySelector('#metric_species');
        const metricPetal = document.querySelector('#metric_petal');
        const metricSepal = document.querySelector('#metric_sepal');
        const metrics = document.querySelector('%s');
        const metricsReady = metrics && metrics.textContent.trim().length > 0;
        const bound = document.querySelectorAll('.shiny-bound-output, .shiny-bound-input').length;
        if (!(bound > 0 && plotReady && tableRows >= minRows && metricsReady)) {
          if (Date.now() > deadline) { resolve(false); return; }
          setTimeout(check, 300);
          return;
        }
        %s
        resolve(true);
      };
      check();
    });
  ", timeout * 1000L, as.integer(min_rows), metric_sel, extra_checks)
  session$Runtime$evaluate(
    expression = js,
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = (timeout + 5) * 1000
  )
}

prep_screenshot_layout <- function(session) {
  session$Runtime$evaluate(expression = "
    window.scrollTo(0, 0);
    document.body.classList.remove('glass-nav-compact');
    document.body.classList.add('glass-nav-expanded');
    document.querySelectorAll('.navbar, .tabbable > .nav-tabs').forEach((el) => {
      el.style.transform = 'none';
      el.style.opacity = '1';
    });
  ")
}

hide_sidebar_toggle <- function(session) {
  session$Runtime$evaluate(expression = "
    document.querySelectorAll('.collapse-toggle').forEach((el) => {
      el.style.display = 'none';
    });
  ")
}

hide_sidebar_panel <- function(session) {
  session$Runtime$evaluate(expression = "
    document.querySelectorAll('.bslib-sidebar-layout > .sidebar').forEach((el) => {
      el.style.display = 'none';
    });
    document.querySelectorAll('.collapse-toggle').forEach((el) => {
      el.style.display = 'none';
    });
    const main = document.querySelector('.bslib-page-main, .main');
    if (main) {
      main.style.paddingLeft = 'var(--glass-float-margin, 0.85rem)';
      main.style.paddingRight = 'var(--glass-float-margin, 0.85rem)';
    }
    window.scrollTo(0, 0);
  ")
  Sys.sleep(0.5)
}

disable_content_tint <- function(session) {
  session$Runtime$evaluate(expression = "
    document.documentElement.classList.remove('glass-tint-active');
    [
      '--glass-tint-strength',
      '--glass-tint-r', '--glass-tint-g', '--glass-tint-b',
      '--glass-bg', '--glass-bg-hover', '--glass-border',
      '--glass-orb-tint-1', '--glass-orb-tint-2', '--glass-orb-tint-3'
    ].forEach((prop) => document.documentElement.style.removeProperty(prop));
    window.__shinyglassDisableTint = true;
    if (window.tintTimer) clearTimeout(window.tintTimer);
  ")
}

wait_for_button <- function(session, id, timeout = 20) {
  js <- sprintf("
    new Promise((resolve) => {
      const deadline = Date.now() + %d;
      const check = () => {
        if (document.getElementById('%s')) {
          resolve(true);
          return;
        }
        if (Date.now() > deadline) {
          resolve(false);
          return;
        }
        setTimeout(check, 200);
      };
      check();
    });
  ", timeout * 1000L, id)
  out <- session$Runtime$evaluate(
    expression = js,
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = (timeout + 5) * 1000
  )
  isTRUE(out$result$value)
}

click_button <- function(session, id) {
  session$Runtime$evaluate(expression = sprintf("
    (function() {
      const el = document.getElementById('%s');
      if (el) {
        el.click();
        return true;
      }
      if (window.Shiny && window.Shiny.setInputValue) {
        window.Shiny.setInputValue('%s', Date.now(), { priority: 'event' });
        return true;
      }
      return false;
    })();
  ", id, id), returnByValue = TRUE)
}

capture_app <- function(
    app_path,
    out_path,
    port = 3847L,
    width = 1400L,
    height = 900L,
    env = character(),
    hide_sidebar_toggle = TRUE,
    hide_sidebar_panel = FALSE,
    disable_tint = FALSE,
    wait_mode = c("default", "querychat"),
    prep = NULL) {
  wait_mode <- match.arg(wait_mode)
  url <- sprintf("http://127.0.0.1:%d", port)
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  script_dir <- if (length(file_arg)) {
    dirname(sub("^--file=", "", file_arg[1]))
  } else {
    "."
  }
  pkg_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/")
  launch_expr <- sprintf(
    paste(
      "if (requireNamespace('pkgload', quietly = TRUE)) {",
      "  pkgload::load_all('%s', quiet = TRUE)",
      "} else {",
      "  devtools::load_all('%s', quiet = TRUE)",
      "}",
      "shiny::runApp('%s', host='127.0.0.1', port=%d, launch.browser=FALSE)",
      sep = "; "
    ),
    gsub("'", "\\\\'", pkg_root),
    gsub("'", "\\\\'", pkg_root),
    gsub("'", "\\\\'", normalizePath(app_path, winslash = "/")),
    port
  )
  proc <- processx::process$new(
    command = normalizePath(Sys.which("Rscript")),
    args = c("-e", launch_expr),
    env = c(Sys.getenv(), env),
    stdout = "|",
    stderr = "|"
  )
  on.exit(if (proc$is_alive()) proc$kill(), add = TRUE)

  ready <- FALSE
  for (i in seq_len(80)) {
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
  initial_wait <- if (wait_mode == "querychat") 4 else 2
  Sys.sleep(initial_wait)
  if (isTRUE(disable_tint)) {
    disable_content_tint(b)
    Sys.sleep(0.25)
  }
  tryCatch(
    wait_for_shiny(b, timeout = if (wait_mode == "querychat") 60 else 45, mode = wait_mode),
    error = function(e) NULL
  )

  if (is.function(prep)) {
    prep(b)
    tryCatch(
      wait_for_shiny(
        b,
        timeout = if (wait_mode == "querychat") 60 else 40,
        min_rows = 8L,
        mode = wait_mode,
        filtered = wait_mode == "querychat"
      ),
      error = function(e) NULL
    )
    Sys.sleep(if (wait_mode == "querychat") 2 else 1)
  }

  if (isTRUE(hide_sidebar_panel)) {
    hide_sidebar_panel(b)
  } else if (isTRUE(hide_sidebar_toggle)) {
    hide_sidebar_toggle(b)
    Sys.sleep(0.25)
  }

  prep_screenshot_layout(b)

  if (isTRUE(disable_tint)) {
    disable_content_tint(b)
    Sys.sleep(0.35)
  }

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

examples_dir <- file.path(pkg_root, "inst", "examples")

capture_app(
  file.path(examples_dir, "bslib-dashboard.R"),
  file.path(fig_dir, "bslib-dashboard.png"),
  port = 3850L,
  height = 880L,
  hide_sidebar_panel = TRUE
)
capture_app(
  file.path(examples_dir, "bslib-dashboard.R"),
  file.path(fig_dir, "bslib-dashboard-dark.png"),
  port = 3851L,
  height = 880L,
  env = c(SHINYGLASS_PRESET = "dark"),
  hide_sidebar_panel = TRUE
)

prep_querychat <- function(session) {
  if (!wait_for_button(session, "filter_setosa", timeout = 25)) {
    warning("Timed out waiting for #filter_setosa during screenshot prep.", call. = FALSE)
    return(invisible(NULL))
  }
  clicked <- click_button(session, "filter_setosa")
  if (!isTRUE(clicked$result$value)) {
    warning("Could not click #filter_setosa during screenshot prep.", call. = FALSE)
  }
  Sys.sleep(2)
}

capture_app(
  file.path(examples_dir, "querychat-demo.R"),
  file.path(fig_dir, "querychat-demo.png"),
  port = 3852L,
  height = 920L,
  prep = prep_querychat,
  disable_tint = TRUE,
  hide_sidebar_panel = TRUE,
  wait_mode = "querychat"
)
capture_app(
  file.path(examples_dir, "querychat-demo.R"),
  file.path(fig_dir, "querychat-demo-dark.png"),
  port = 3853L,
  height = 920L,
  env = c(SHINYGLASS_PRESET = "dark"),
  prep = prep_querychat,
  disable_tint = TRUE,
  hide_sidebar_panel = TRUE,
  wait_mode = "querychat"
)