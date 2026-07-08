# SuperZIP (leaflet + absolutePanel + DT) with glass_theme().
# Source: rstudio/shiny-examples/063-superzip-example
#
# Run:
#   # once: git clone https://github.com/rstudio/shiny-examples.git
#   Sys.setenv(SHINYGLASS_EXAMPLES_DIR = "/path/to/shiny-examples")
#   shiny::runApp(system.file("examples", "superzip-glass.R", package = "shinyglass"))
#
# Requires: leaflet, dplyr, DT, RColorBrewer, scales, lattice

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
this_file <- if (length(file_arg)) sub("^--file=", "", file_arg[1]) else "."
pkg_root <- normalizePath(file.path(dirname(this_file), "..", ".."), winslash = "/")
source(file.path(pkg_root, "inst", "scripts", "glass-test-utils.R"))
source(file.path(pkg_root, "inst", "scripts", "tier-ab-utils.R"))

if (!requireNamespace("shinyglass", quietly = TRUE)) {
  if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(pkg_root, quiet = TRUE)
  } else {
    stop("shinyglass is required.", call. = FALSE)
  }
}

for (pkg in c("leaflet", "dplyr", "DT", "RColorBrewer", "scales", "lattice")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Install package '", pkg, "' for SuperZIP.", call. = FALSE)
  }
}

app_src <- resolve_superzip_dir()
prep <- prepare_patched_app_dir(app_src)
if (!isTRUE(prep$ok)) {
  stop("Could not prepare SuperZIP with glass_theme(): ", prep$reason, call. = FALSE)
}

shiny::runApp(
  appDir = prep$dir,
  host = Sys.getenv("SHINYGLASS_HOST", "127.0.0.1"),
  port = as.integer(Sys.getenv("SHINYGLASS_PORT", "0")),
  launch.browser = interactive()
)
