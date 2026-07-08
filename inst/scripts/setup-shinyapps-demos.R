#!/usr/bin/env Rscript
# Refresh vendored dreamRs/shinyapps sources.
# After running, restore app-glass.R files from git (they are shinyglass-specific).

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(sub("^--file=", "", file_arg[1]))
} else {
  "."
}
pkg_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/")
dest <- file.path(pkg_root, "inst", "shinyapps")
tmp <- tempfile("shinyapps-")
dir.create(tmp, showWarnings = FALSE)

status <- system2(
  "git",
  c("clone", "--depth", "1", "https://github.com/dreamRs/shinyapps.git", tmp),
  stdout = TRUE,
  stderr = TRUE
)
if (!is.null(attr(status, "status")) && attr(status, "status") != 0L) {
  stop("git clone failed:\n", paste(status, collapse = "\n"), call. = FALSE)
}

unlink(file.path(tmp, ".git"), recursive = TRUE)
readme <- file.path(dest, "README.md")
if (file.exists(readme)) {
  file.copy(readme, file.path(tmp, "README.shinyglass.md"), overwrite = TRUE)
}
unlink(dest, recursive = TRUE)
file.rename(tmp, dest)
if (file.exists(file.path(dest, "README.shinyglass.md"))) {
  file.rename(file.path(dest, "README.shinyglass.md"), file.path(dest, "README.md"))
}

message("Updated dreamRs apps in ", dest)
message("Run: git checkout -- inst/shinyapps/*/app-glass.R inst/shinyapps/README.md")