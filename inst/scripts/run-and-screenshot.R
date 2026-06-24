#!/usr/bin/env Rscript
# Start a Shiny app, capture a headless-browser screenshot, then stop.
#
# Usage:
#   Rscript run-and-screenshot.R [app.R] [port] [output.png]
#
# Example:
#   Rscript inst/scripts/run-and-screenshot.R inst/examples/test-app.R 3847 screenshot.png

args <- commandArgs(trailingOnly = TRUE)
app_path <- if (length(args) >= 1) args[[1]] else system.file("examples", "test-app.R", package = "shinyglass")
port <- if (length(args) >= 2) as.integer(args[[2]]) else 3847L
out_path <- if (length(args) >= 3) args[[3]] else "screenshot.png"
url <- sprintf("http://127.0.0.1:%d", port)

if (!file.exists(app_path)) {
  stop("App not found: ", app_path)
}

script_dir <- dirname(normalizePath(commandArgs(trailingOnly = FALSE)[4], winslash = "/", mustWork = FALSE))
screenshot_sh <- file.path(script_dir, "headless-screenshot.sh")
if (!file.exists(screenshot_sh)) {
  stop("headless-screenshot.sh not found at: ", screenshot_sh)
}

message("Starting app: ", app_path)
proc <- processx::process$new(
  command = normalizePath(Sys.which("Rscript")),
  args = c(
    "-e",
    sprintf(
      "shiny::runApp('%s', host='127.0.0.1', port=%d, launch.browser=FALSE)",
      gsub("'", "\\\\'", normalizePath(app_path, winslash = "/")),
      port
    )
  ),
  stdout = "|",
  stderr = "|"
)

on.exit({
  if (proc$is_alive()) {
    message("Stopping app...")
    proc$kill()
  }
}, add = TRUE)

ready <- FALSE
for (i in seq_len(40)) {
  if (!proc$is_alive()) {
    stop("App process exited early:\n", proc$read_all_error())
  }
  resp <- tryCatch(
    curl::curl_fetch_memory(url),
    error = function(e) NULL
  )
  if (!is.null(resp) && resp$status_code == 200) {
    ready <- TRUE
    break
  }
  Sys.sleep(0.5)
}
if (!ready) {
  stop("Timed out waiting for app at ", url)
}

message("App ready at ", url)
status <- system2("bash", c(screenshot_sh, url, out_path), stdout = TRUE, stderr = TRUE)
cat(paste(status, collapse = "\n"), "\n")
if (!file.exists(out_path)) {
  stop("Screenshot was not created.")
}
message("Screenshot saved: ", normalizePath(out_path))