# dreamRs Paris metro traffic dashboard with shinyglass.
# Source: https://github.com/dreamRs/shinyapps/tree/main/ratp-traffic
#
# Run:
#   shiny::runApp(system.file("examples", "dreamrs-ratp-traffic.R", package = "shinyglass"))
#
# Requires: shinydashboard, shinyWidgets, leaflet, leaflet.extras, sf,
#   billboarder, dplyr, scales, stringr

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
this_file <- if (length(file_arg)) sub("^--file=", "", file_arg[1]) else "."
pkg_root <- normalizePath(file.path(dirname(this_file), "..", ".."), winslash = "/")
source(file.path(pkg_root, "inst", "scripts", "dreamrs-glass-utils.R"))
run_dreamrs_glass_app("ratp-traffic")