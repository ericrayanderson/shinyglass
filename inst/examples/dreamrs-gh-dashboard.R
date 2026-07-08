# dreamRs GitHub dashboard with shinyglass.
# Source: https://github.com/dreamRs/shinyapps/tree/main/gh-dashboard
#
# Run:
#   shiny::runApp(system.file("examples", "dreamrs-gh-dashboard.R", package = "shinyglass"))
#
# Requires: shinyWidgets, phosphoricons, shinyjs, gh, ggplot2, data.table

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
this_file <- if (length(file_arg)) sub("^--file=", "", file_arg[1]) else "."
pkg_root <- normalizePath(file.path(dirname(this_file), "..", ".."), winslash = "/")
source(file.path(pkg_root, "inst", "scripts", "dreamrs-glass-utils.R"))
run_dreamrs_glass_app("gh-dashboard")