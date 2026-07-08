# Helpers for running dreamRs/shinyapps examples with shinyglass.
# Used by inst/examples/dreamrs-*.R launchers and capture scripts.

dreamrs_pkg_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg)) {
    return(normalizePath(file.path(dirname(sub("^--file=", "", file_arg[1])), "..", ".."), winslash = "/"))
  }
  normalizePath(file.path(getwd(), "."), winslash = "/")
}

dreamrs_app_dir <- function(app_name, pkg_root = NULL) {
  if (is.null(pkg_root)) {
    pkg_root <- Sys.getenv("SHINYGLASS_PKG_ROOT", dreamrs_pkg_root())
  }
  app_dir <- file.path(pkg_root, "inst", "shinyapps", app_name)
  if (!dir.exists(app_dir)) {
    stop(
      "dreamRs app '", app_name, "' not found at ", app_dir, ".\n",
      "Clone with: git clone https://github.com/dreamRs/shinyapps.git inst/shinyapps",
      call. = FALSE
    )
  }
  normalizePath(app_dir, winslash = "/")
}

dreamrs_glass_preset <- function() {
  match.arg(Sys.getenv("SHINYGLASS_PRESET", "light"), c("light", "dark"))
}

run_dreamrs_glass_app <- function(app_name) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("shiny is required.", call. = FALSE)
  }
  if (!requireNamespace("shinyglass", quietly = TRUE)) {
    stop("shinyglass is required.", call. = FALSE)
  }

  app_dir <- dreamrs_app_dir(app_name)
  entry <- file.path(app_dir, "app-glass.R")
  if (!file.exists(entry)) {
    stop("Glass entry point not found: ", entry, call. = FALSE)
  }

  shiny::runApp(
    appDir = entry,
    host = Sys.getenv("SHINYGLASS_HOST", "127.0.0.1"),
    port = as.integer(Sys.getenv("SHINYGLASS_PORT", "0")),
    launch.browser = FALSE
  )
}