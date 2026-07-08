# dreamRs Olympic medals explorer with shinyglass.
# Source: https://github.com/dreamRs/shinyapps/tree/main/olympic-medals
#
# Run:
#   shiny::runApp(system.file("examples", "dreamrs-olympic-medals.R", package = "shinyglass"))
#
# Requires: shinyWidgets, reactable, ggplot2, dplyr, data.table, tidyr, ggtext, ggthemes

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
this_file <- if (length(file_arg)) sub("^--file=", "", file_arg[1]) else "."
pkg_root <- normalizePath(file.path(dirname(this_file), "..", ".."), winslash = "/")
source(file.path(pkg_root, "inst", "scripts", "dreamrs-glass-utils.R"))
run_dreamrs_glass_app("olympic-medals")