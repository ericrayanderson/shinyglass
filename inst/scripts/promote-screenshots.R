#!/usr/bin/env Rscript
# Capture UI-only gallery screenshots (replaces copying from visual-test output).
#
# Usage:
#   Rscript promote-screenshots.R [shiny-examples-dir]
#
# Delegates to capture-gallery.R. Visual-test PNGs often include Shiny showcase
# code panels; this script always captures apps with display.mode = "normal".

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(sub("^--file=", "", file_arg[1]))
} else {
  "."
}

trailing <- commandArgs(trailingOnly = TRUE)
extra <- if (length(trailing)) trailing else character()

capture_script <- file.path(script_dir, "capture-gallery.R")
cmd_args <- c(capture_script, extra)
status <- system2(normalizePath(Sys.which("Rscript")), cmd_args, stdout = "", stderr = "")
if (!isTRUE(status == 0L)) {
  stop("capture-gallery.R failed.")
}
invisible(status)