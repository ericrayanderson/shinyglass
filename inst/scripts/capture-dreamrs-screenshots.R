#!/usr/bin/env Rscript
# Capture light/dark screenshots for dreamRs/shinyapps glass demos.

suppressPackageStartupMessages({
  library(processx)
  library(chromote)
  library(curl)
})

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
shinyapps_dir <- file.path(pkg_root, "inst", "shinyapps")

hide_sidebar_toggle <- function(session) {
  session$Runtime$evaluate(expression = "
    document.querySelectorAll('.collapse-toggle').forEach((el) => {
      el.style.display = 'none';
    });
  ")
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

apply_widget_glass_overrides <- function(session) {
  session$Runtime$evaluate(expression = "
    document.querySelectorAll('.stati').forEach((el) => {
      el.style.setProperty('background', 'var(--glass-bg)', 'important');
      el.style.setProperty('background-color', 'var(--glass-bg)', 'important');
      el.style.setProperty('color', 'inherit', 'important');
      el.querySelectorAll('.stati-value, .stati-subtitle, i, svg').forEach((child) => {
        child.style.setProperty('color', 'inherit', 'important');
        child.style.removeProperty('fill');
      });
    });
    document.querySelectorAll('.Reactable').forEach((el) => {
      el.style.setProperty('background-color', 'var(--glass-bg)', 'important');
      el.style.setProperty('color', 'inherit', 'important');
    });
  ")
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

wait_for_app <- function(session, mode = c("default", "gh", "olympic", "naissances", "ratp"), timeout = 60) {
  mode <- match.arg(mode)
  extra <- switch(
    mode,
    gh = "
      const stars = document.querySelector('#n_stars, [id$=\"n_stars\"]');
      const starsReady = stars && /\\d/.test(stars.textContent);
      if (!starsReady) { retry(); return; }
    ",
    olympic = "
      const tableRows = document.querySelectorAll('.rt-tbody .rt-tr-group').length;
      if (tableRows < 3) { retry(); return; }
    ",
    naissances = "
      const cards = document.querySelectorAll('.stati');
      const cardReady = cards.length >= 3;
      if (!cardReady) { retry(); return; }
    ",
    ratp = "
      const map = document.querySelector('.leaflet-container');
      const tiles = document.querySelectorAll('.leaflet-tile-loaded').length;
      if (!map || tiles < 2) { retry(); return; }
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
        const plotImg = document.querySelector(
          '.shiny-plot-output img, .billboarder-output svg, .apexcharts-svg'
        );
        const plotReady = plotImg && (
          (plotImg.tagName === 'IMG' && plotImg.complete && plotImg.naturalWidth > 0) ||
          plotImg.tagName !== 'IMG'
        );
        const bound = document.querySelectorAll('.shiny-bound-output').length;
        if (!(bound > 2 && plotReady)) { retry(); return; }
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

prep_gh <- function(session) {
  session$Runtime$evaluate(expression = "
    (function() {
      const input = document.querySelector('#gh_user2 input[type=\"search\"], #gh_user2 input');
      if (input) {
        input.value = 'dreamRs';
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
      const btn = document.querySelector('#gh_user2 .btn-search, #gh_user2 button');
      if (btn) { btn.click(); return true; }
      if (window.Shiny && window.Shiny.setInputValue) {
        window.Shiny.setInputValue('gh_user2', 'dreamRs', { priority: 'event' });
        return true;
      }
      return false;
    })();
  ", returnByValue = TRUE)
  Sys.sleep(8)
}

prep_ratp <- function(session) {
  session$Runtime$evaluate(expression = "
    (function() {
      const toggle = document.querySelector('#choix_ligne .dropdown-toggle, #choix_ligne button');
      if (toggle) toggle.click();
      const item = [...document.querySelectorAll('#choix_ligne .dropdown-menu .dropdown-item, #choix_ligne li a')]
        .find((el) => el.textContent.includes('Ligne 1') || el.textContent.trim() === '1');
      if (item) { item.click(); return true; }
      return false;
    })();
  ", returnByValue = TRUE)
  Sys.sleep(4)
}

capture_dreamrs_app <- function(
    app_name,
    out_light,
    out_dark,
    port = 3860L,
    width = 1400L,
    height = 900L,
    wait_mode = "default",
    prep = NULL,
    disable_tint = TRUE) {
  app_file <- file.path(shinyapps_dir, app_name, "app-glass.R")
  if (!file.exists(app_file)) {
    stop("Missing ", app_file)
  }

  capture_one <- function(out_path, preset = c("light", "dark")) {
    preset <- match.arg(preset)
    url <- sprintf("http://127.0.0.1:%d", port)
    env <- if (preset == "dark") c(SHINYGLASS_PRESET = "dark") else character()
    app_dir <- dirname(normalizePath(app_file, winslash = "/"))
    launch_expr <- sprintf(
      paste(
        "if (requireNamespace('pkgload', quietly = TRUE)) {",
        "  pkgload::load_all('%s', quiet = TRUE)",
        "} else {",
        "  devtools::load_all('%s', quiet = TRUE)",
        "}",
        "setwd('%s')",
        "shiny::runApp('%s', host='127.0.0.1', port=%d, launch.browser=FALSE)",
        sep = "; "
      ),
      gsub("'", "\\\\'", pkg_root),
      gsub("'", "\\\\'", pkg_root),
      gsub("'", "\\\\'", app_dir),
      gsub("'", "\\\\'", normalizePath(app_file, winslash = "/")),
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
    for (i in seq_len(100)) {
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
    if (!ready) stop("Timed out waiting for ", url)

    b <- chromote::ChromoteSession$new()
    on.exit(b$close(), add = TRUE)
    b$set_viewport_size(width = width, height = height)
    b$go_to(url)
    Sys.sleep(3)
    if (isTRUE(disable_tint)) {
      disable_content_tint(b)
      Sys.sleep(0.25)
    }
    tryCatch(wait_for_app(b, mode = wait_mode, timeout = 75), error = function(e) NULL)
    if (is.function(prep)) {
      prep(b)
      tryCatch(wait_for_app(b, mode = wait_mode, timeout = 75), error = function(e) NULL)
      Sys.sleep(1.5)
    }
    hide_sidebar_toggle(b)
    prep_screenshot_layout(b)
    apply_widget_glass_overrides(b)
    if (isTRUE(disable_tint)) {
      disable_content_tint(b)
      Sys.sleep(0.35)
    }
    Sys.sleep(0.5)
    b$screenshot(filename = out_path)
    message("Saved ", out_path)
  }

  capture_one(out_light, "light")
  capture_one(out_dark, "dark")
}

capture_dreamrs_app(
  "gh-dashboard",
  file.path(fig_dir, "dreamrs-gh-dashboard.png"),
  file.path(fig_dir, "dreamrs-gh-dashboard-dark.png"),
  port = 3860L,
  height = 960L,
  wait_mode = "gh",
  prep = prep_gh
)
capture_dreamrs_app(
  "olympic-medals",
  file.path(fig_dir, "dreamrs-olympic-medals.png"),
  file.path(fig_dir, "dreamrs-olympic-medals-dark.png"),
  port = 3862L,
  height = 960L,
  wait_mode = "olympic"
)
capture_dreamrs_app(
  "tdb-naissances",
  file.path(fig_dir, "dreamrs-tdb-naissances.png"),
  file.path(fig_dir, "dreamrs-tdb-naissances-dark.png"),
  port = 3864L,
  height = 920L,
  wait_mode = "naissances"
)
capture_dreamrs_app(
  "ratp-traffic",
  file.path(fig_dir, "dreamrs-ratp-traffic.png"),
  file.path(fig_dir, "dreamrs-ratp-traffic-dark.png"),
  port = 3866L,
  height = 940L,
  wait_mode = "ratp",
  prep = prep_ratp
)