# dreamRs shinyWidgets gallery with glass_theme() replacing the default bslib theme.
#
# Run:
#   shiny::runApp(system.file("examples", "shinywidgets-gallery-glass.R", package = "shinyglass"))
#
# Requires: shinyWidgets, bslib

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
this_file <- if (length(file_arg)) sub("^--file=", "", file_arg[1]) else "."
pkg_root <- normalizePath(file.path(dirname(this_file), "..", ".."), winslash = "/")
source(file.path(pkg_root, "inst", "scripts", "glass-test-utils.R"))

if (!requireNamespace("shinyglass", quietly = TRUE)) {
  if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(pkg_root, quiet = TRUE)
  } else {
    stop("shinyglass is required.", call. = FALSE)
  }
}

if (!requireNamespace("shinyWidgets", quietly = TRUE)) {
  stop("Install shinyWidgets: install.packages(\"shinyWidgets\")", call. = FALSE)
}

src <- system.file("examples", "shinyWidgets", package = "shinyWidgets", mustWork = TRUE)
prep <- prepare_patched_app_dir(src)
if (!isTRUE(prep$ok)) {
  stop("Could not prepare shinyWidgets gallery: ", prep$reason, call. = FALSE)
}

shiny::runApp(
  appDir = prep$dir,
  host = Sys.getenv("SHINYGLASS_HOST", "127.0.0.1"),
  port = as.integer(Sys.getenv("SHINYGLASS_PORT", "0")),
  launch.browser = interactive()
)
