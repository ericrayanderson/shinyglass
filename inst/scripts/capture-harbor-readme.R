#!/usr/bin/env Rscript
# README stills of Harbor notes (the shinychat flagship).
# Light and dark, after the local scripted reply. No API key.
#
# From the package root:
#   Rscript inst/scripts/capture-harbor-readme.R

suppressPackageStartupMessages({
  library(processx)
  library(chromote)
  library(curl)
})

chromote::set_chrome_args(unique(c(
  chromote::default_chrome_args(),
  "--no-sandbox",
  "--disable-dev-shm-usage",
  "--disable-gpu"
)))

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(sub("^--file=", "", file_arg[[1]]))
} else {
  "inst/scripts"
}
pkg_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/")
fig_dir <- file.path(pkg_root, "man", "figures")
app_path <- file.path(pkg_root, "inst", "examples", "shinychat-glass", "app.R")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
if (!file.exists(app_path)) stop("Missing ", app_path)

if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(pkg_root, quiet = TRUE)
}

capture_harbor <- function(preset, filename, port) {
  url <- sprintf("http://127.0.0.1:%d", port)
  launch <- sprintf(
    paste(
      "pkgload::load_all(%s, quiet = TRUE)",
      "Sys.setenv(SHINYGLASS_CHAT_PACE = '0')",
      "shiny::runApp(%s, host = '127.0.0.1', port = %d, launch.browser = FALSE)",
      sep = "; "
    ),
    deparse(pkg_root),
    deparse(normalizePath(app_path, winslash = "/")),
    as.integer(port)
  )
  env <- Sys.getenv()
  env[["SHINYGLASS_PRESET"]] <- preset
  env[["SHINYGLASS_CHAT_PACE"]] <- "0"
  proc <- processx::process$new(
    command = normalizePath(Sys.which("Rscript")),
    args = c("-e", launch),
    env = env,
    stdout = "|",
    stderr = "|"
  )
  on.exit({
    if (proc$is_alive()) try(proc$kill(tree = TRUE), silent = TRUE)
  }, add = TRUE)

  ready <- FALSE
  for (i in seq_len(90)) {
    if (!proc$is_alive()) {
      stop("Harbor app exited early (", preset, "):\n", proc$read_all_error())
    }
    ok <- tryCatch(
      curl::curl_fetch_memory(url)$status_code == 200L,
      error = function(e) FALSE
    )
    if (ok) {
      ready <- TRUE
      break
    }
    Sys.sleep(0.4)
  }
  if (!ready) stop("Timed out waiting for ", url)

  b <- chromote::ChromoteSession$new()
  on.exit(try(b$close(), silent = TRUE), add = TRUE)
  b$set_viewport_size(width = 1280L, height = 900L)
  b$go_to(url)

  ready_ui <- b$Runtime$evaluate(
    expression = "
      new Promise((resolve) => {
        const deadline = Date.now() + 45000;
        const check = () => {
          const composer = document.querySelector('.shiny-chat-input .tiptap, .ProseMirror');
          const suggestion = document.querySelector('.suggestion');
          const header = document.querySelector('.shiny-chat-page-header');
          if (composer && suggestion && header) { resolve(true); return; }
          if (Date.now() > deadline) { resolve(false); return; }
          setTimeout(check, 250);
        };
        check();
      });
    ",
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = 50000
  )
  if (!isTRUE(ready_ui$result$value)) {
    stop("Harbor UI did not become ready (", preset, ")")
  }

  clicked <- b$Runtime$evaluate(
    expression = "
      (function() {
        const el = Array.from(document.querySelectorAll('.suggestion, button, [data-suggestion-submit]'))
          .find((node) => /glass_theme work/i.test(node.textContent || ''));
        if (!el) return false;
        el.click();
        return true;
      })();
    ",
    returnByValue = TRUE
  )
  if (!isTRUE(clicked$result$value)) stop("Could not click the dawn suggestion")

  replied <- b$Runtime$evaluate(
    expression = "
      new Promise((resolve) => {
        const deadline = Date.now() + 20000;
        const check = () => {
          const tool = document.querySelector('.shiny-tool-card, .shiny-chat-tool-group');
          const cite = document.querySelector('.harbor-pill');
          const text = document.body.innerText || '';
          if (tool && cite && /Read glass_theme/.test(text) && /Liquid Glass/.test(text)) {
            resolve(true);
            return;
          }
          if (Date.now() > deadline) { resolve(false); return; }
          setTimeout(check, 200);
        };
        check();
      });
    ",
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = 25000
  )
  if (!isTRUE(replied$result$value)) stop("Scripted reply did not finish (", preset, ")")

  listed <- b$Runtime$evaluate(
    expression = "
      new Promise((resolve) => {
        const deadline = Date.now() + 12000;
        const check = () => {
          const empty = document.querySelector('.shiny-chat-history-empty');
          const item = document.querySelector('.shiny-chat-history-item, .shiny-chat-history-item-select');
          const label = (item && (item.innerText || item.textContent) || '').trim();
          if (item && label && (!empty || empty.offsetParent === null)) {
            resolve(label.slice(0, 80));
            return;
          }
          if (Date.now() > deadline) { resolve(''); return; }
          setTimeout(check, 250);
        };
        check();
      });
    ",
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = 15000
  )
  if (!nzchar(listed$result$value %||% "")) {
    stop("Sidebar did not list the current conversation (", preset, ")")
  }

  b$Runtime$evaluate(
    expression = "
      (function() {
        const active = document.activeElement;
        if (active && active !== document.body) active.blur();
        document.querySelectorAll('.ProseMirror, .tiptap, [contenteditable=\"true\"]').forEach((el) => {
          el.blur();
        });
        window.getSelection()?.removeAllRanges();
      })();
    "
  )
  b$Runtime$evaluate(
    expression = "
      (function() {
        const nodes = document.querySelectorAll(
          '.shiny-chat-messages, .shiny-chat-output, .shiny-chat-container'
        );
        nodes.forEach((el) => { el.scrollTop = el.scrollHeight; });
        const tool = document.querySelector('.shiny-tool-card, .shiny-chat-tool-group');
        if (tool) tool.scrollIntoView({block: 'center'});
      })();
    "
  )
  Sys.sleep(0.5)

  dest <- file.path(fig_dir, filename)
  b$screenshot(filename = dest)
  message("Wrote ", dest, " (", round(file.info(dest)$size / 1024), " KiB)")
  invisible(dest)
}

capture_harbor("light", "harbor-notes.png", 13941L)
capture_harbor("dark", "harbor-notes-dark.png", 13942L)
message("Done.")
