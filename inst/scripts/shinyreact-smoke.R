#!/usr/bin/env Rscript
# Browser smoke test for inst/examples/shinyreact-glass.
# Installs nothing. Starts the example, checks the React components render,
# and switches light/dark. Optional first argument is a directory for
# light and dark screenshots.

local_lib <- "/tmp/r-lib"
if (dir.exists(local_lib)) {
  .libPaths(c(local_lib, .libPaths()))
}

if (!requireNamespace("shinyreact", quietly = TRUE)) {
  stop("shinyreact is required for the browser smoke test.")
}
if (!requireNamespace("chromote", quietly = TRUE)) {
  stop("chromote is required for the browser smoke test.")
}
if (!requireNamespace("processx", quietly = TRUE)) {
  stop("processx is required for the browser smoke test.")
}
if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("pkgload is required for the browser smoke test.")
}

chrome <- Sys.getenv("CHROMOTE_CHROME", "")
if (!nzchar(chrome)) {
  candidates <- c(
    Sys.getenv("CHROME_BIN", ""),
    Sys.getenv("CHROME_PATH", ""),
    "/usr/bin/google-chrome",
    "/usr/local/bin/google-chrome"
  )
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (length(candidates)) {
    Sys.setenv(CHROMOTE_CHROME = candidates[[1]])
  }
}

args <- commandArgs(trailingOnly = TRUE)
shot_dir <- if (length(args) >= 1 && nzchar(args[[1]])) args[[1]] else ""
if (nzchar(shot_dir) && !dir.exists(shot_dir)) {
  dir.create(shot_dir, recursive = TRUE, showWarnings = FALSE)
}

repo <- normalizePath(".")
if (!file.exists(file.path(repo, "DESCRIPTION"))) {
  stop("Run shinyreact-smoke.R from the package root.")
}

libs <- paste(sprintf("'%s'", .libPaths()), collapse = ", ")
port <- httpuv::randomPort(min = 30000, max = 40000)
url <- sprintf("http://127.0.0.1:%d", port)
expr <- sprintf(
  paste(
    ".libPaths(c(%s));",
    "pkgload::load_all(%s, quiet = TRUE);",
    "shiny::runApp('inst/examples/shinyreact-glass', port = %d, host = '127.0.0.1', launch.browser = FALSE)"
  ),
  libs,
  shQuote(repo),
  port
)

proc <- processx::process$new(
  command = file.path(R.home("bin"), "Rscript"),
  args = c("-e", expr),
  wd = repo,
  stdout = "|",
  stderr = "|"
)
on.exit({
  if (proc$is_alive()) proc$kill()
}, add = TRUE)

ok <- FALSE
for (i in seq_len(50)) {
  ok <- tryCatch(
    curl::curl_fetch_memory(url)$status_code == 200L,
    error = function(e) FALSE
  )
  if (isTRUE(ok)) break
  if (!proc$is_alive()) break
  Sys.sleep(0.4)
}
if (!isTRUE(ok)) {
  message(proc$read_all_output())
  message(proc$read_all_error())
  stop("shinyreact example did not start at ", url)
}

b <- chromote::ChromoteSession$new()
on.exit(try(b$close(), silent = TRUE), add = TRUE)
invisible(b$Page$enable())
invisible(b$Page$addScriptToEvaluateOnNewDocument(source = paste(
  "window.__glassErrors = [];",
  "window.addEventListener('error', function (e) {",
  "  window.__glassErrors.push(String(e.message || e));",
  "});",
  "var orig = console.error;",
  "console.error = function () {",
  "  window.__glassErrors.push(Array.prototype.join.call(arguments, ' '));",
  "  return orig.apply(console, arguments);",
  "};",
  sep = "\n"
)))
invisible(b$set_viewport_size(width = 1400, height = 1100))
invisible(b$go_to(url))

eval_js <- function(expr) {
  res <- b$Runtime$evaluate(
    expression = expr,
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = 25000
  )
  details <- res$exceptionDetails
  if (!is.null(details)) {
    text <- details$text
    if (is.null(text) && !is.null(details$exception$description)) {
      text <- details$exception$description
    }
    stop("JavaScript error: ", text)
  }
  res$result$value
}

invisible(eval_js("
  new Promise((resolve, reject) => {
    const deadline = Date.now() + 20000;
    const check = () => {
      const app = document.querySelector('#app.glass-page');
      const side = document.querySelector('#controls.glass-sidebar');
      const plot = document.querySelector('#dist img');
      const hook = window.shinyglass && typeof window.shinyglass.useGlassTheme === 'function';
      const btn = document.querySelector('#preset-dark.glass-button');
      const plotReady = plot && plot.complete && plot.naturalWidth > 0;
      if (app && side && hook && btn && plotReady) {
        resolve(true);
        return;
      }
      if (Date.now() > deadline) {
        reject('timed out waiting for the example');
        return;
      }
      setTimeout(check, 200);
    };
    check();
  })
"))

surface <- eval_js("
  (() => {
    const el = document.querySelector('#controls');
    const cs = getComputedStyle(el);
    const filter = cs.backdropFilter || cs.webkitBackdropFilter || '';
    return JSON.stringify({
      filter: filter,
      mode: document.documentElement.dataset.glassMode,
      scene: document.documentElement.dataset.glassScene,
      readout: document.querySelector('#preset-readout').textContent
    });
  })()
")
surface <- jsonlite::fromJSON(surface)
if (!grepl("blur", surface$filter, ignore.case = TRUE)) {
  stop("Sidebar backdrop-filter has no blur: ", surface$filter)
}
if (!grepl("tahoe", surface$readout)) {
  stop("Theme hook readout did not track the scene: ", surface$readout)
}

switch_mode <- function(mode, plot_must_change = TRUE) {
  eval_js(sprintf("
    new Promise((resolve, reject) => {
      const before = (document.querySelector('#dist img') || {}).src || '';
      const beforeColor = getComputedStyle(document.querySelector('#title')).color;
      document.querySelector('#preset-%s').click();
      const deadline = Date.now() + 10000;
      const mustChange = %s;
      const check = () => {
        const img = document.querySelector('#dist img');
        const live = document.documentElement.dataset.glassMode;
        const preset = document.documentElement.dataset.glassPreset;
        const readout = document.querySelector('#preset-readout').textContent || '';
        const title = getComputedStyle(document.querySelector('#title')).color;
        const plotReady = img && img.complete && img.naturalWidth > 0 && (!mustChange || img.src !== before);
        const pressed = document.querySelector('#preset-%s').getAttribute('aria-pressed') === 'true';
        if (live === '%s' && preset === '%s' && readout.indexOf('mode %s') !== -1 && readout.indexOf('resolved %s') !== -1 && pressed && plotReady) {
          resolve(JSON.stringify({ readout: readout, title: title, beforeTitle: beforeColor }));
          return;
        }
        if (Date.now() > deadline) {
          reject('timed out switching to %s (mode=' + live + ', preset=' + preset + ', pressed=' + pressed + ')');
          return;
        }
        setTimeout(check, 100);
      };
      check();
    })
  ", mode, if (plot_must_change) "true" else "false", mode, mode, mode, mode, mode, mode))
}

# Pin light first. Auto may already have resolved to light, so the plot
# image is allowed to stay put on this establishing click.
light_first <- jsonlite::fromJSON(switch_mode("light", plot_must_change = FALSE))
dark <- jsonlite::fromJSON(switch_mode("dark", plot_must_change = TRUE))
if (!grepl("resolved dark", dark$readout)) {
  stop("Dark readout was: ", dark$readout)
}
if (identical(dark$title, light_first$title)) {
  stop("Title ink did not change between light and dark.")
}
if (nzchar(shot_dir)) {
  invisible(b$screenshot(file.path(shot_dir, "react-components-dark.png")))
}

light <- jsonlite::fromJSON(switch_mode("light", plot_must_change = TRUE))
if (!grepl("resolved light", light$readout)) {
  stop("Light readout was: ", light$readout)
}
if (nzchar(shot_dir)) {
  invisible(b$screenshot(file.path(shot_dir, "react-components-light.png")))
}
dark_readout <- dark$readout
light_readout <- light$readout

errors <- eval_js("
  (window.__glassErrors || []).filter(function (msg) {
    return !/favicon|Download the React DevTools/i.test(String(msg));
  })
")
if (length(errors)) {
  stop("Browser errors:\n", paste(errors, collapse = "\n"))
}

message("shinyreact smoke passed: ", url)
message("light readout: ", light_readout)
message("dark readout: ", dark_readout)
if (nzchar(shot_dir)) {
  message("screenshots in ", shot_dir)
}
