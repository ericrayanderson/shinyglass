#!/usr/bin/env Rscript
# Headless-browser screenshot of a running Shiny app using chromote.
# Waits for Shiny outputs to bind before capturing.
#
# Usage:
#   Rscript chromote-screenshot.R [url] [output.png] [width] [height]

args <- commandArgs(trailingOnly = TRUE)
url <- if (length(args) >= 1) args[[1]] else "http://127.0.0.1:3847"
out <- if (length(args) >= 2) args[[2]] else "screenshot.png"
width <- if (length(args) >= 3) as.integer(args[[3]]) else 1400L
height <- if (length(args) >= 4) as.integer(args[[4]]) else 1100L

if (!requireNamespace("chromote", quietly = TRUE)) {
  stop("chromote package is required for this script.")
}

wait_for_app <- function(url, attempts = 40) {
  for (i in seq_len(attempts)) {
    ok <- tryCatch({
      curl::curl_fetch_memory(url)$status_code == 200
    }, error = function(e) FALSE)
    if (ok) return(invisible(TRUE))
    Sys.sleep(0.5)
  }
  stop("App not reachable at ", url)
}

wait_for_shiny_outputs <- function(session, timeout = 30) {
  js <- sprintf("
    new Promise((resolve, reject) => {
      const deadline = Date.now() + %d;
      const check = () => {
        const plotImg = document.querySelector('#demo_plot img');
        const summary = document.querySelector('#summary');
        const plotReady = plotImg && plotImg.complete && plotImg.naturalWidth > 0;
        const summaryReady = summary && summary.textContent.trim().length > 0;
        if (plotReady && summaryReady) {
          resolve(true);
          return;
        }
        if (Date.now() > deadline) {
          reject('Timed out waiting for Shiny outputs');
          return;
        }
        setTimeout(check, 250);
      };
      check();
    });
  ", timeout * 1000L)

  session$Runtime$evaluate(
    expression = js,
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = (timeout + 5) * 1000
  )
}

message("Waiting for app at ", url, " ...")
wait_for_app(url)

message("Launching headless Chrome via chromote ...")
b <- chromote::ChromoteSession$new()
on.exit(b$close(), add = TRUE)

b$set_viewport_size(width = width, height = height)
b$go_to(url)

message("Waiting for Shiny outputs ...")
tryCatch(
  {
    wait_for_shiny_outputs(b, timeout = 30)
    message("Outputs ready.")
  },
  error = function(e) {
    message("Warning: ", conditionMessage(e), " — capturing anyway.")
    Sys.sleep(5)
  }
)

b$screenshot(out)
message("Screenshot saved: ", normalizePath(out))