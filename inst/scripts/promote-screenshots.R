#!/usr/bin/env Rscript
# Promote curated visual-test screenshots into man/figures/gallery/.
#
# Usage:
#   Rscript promote-screenshots.R [visual-test-output-dir]
#
# Optional env:
#   SHINYGLASS_DOWNLOAD_SCREENSHOT  Path to a fresh 04-download.png override
#
# Defaults to the latest shiny-examples-curated-* folder under
# visual-test-output/, or visual-test-output/shiny-examples if none found.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
pkg_root <- if (length(file_arg)) {
  normalizePath(
    file.path(dirname(sub("^--file=", "", file_arg[1])), "..", ".."),
    winslash = "/"
  )
} else {
  normalizePath(getwd(), winslash = "/")
}

trailing <- commandArgs(trailingOnly = TRUE)

default_input <- function() {
  out_root <- file.path(pkg_root, "visual-test-output")
  curated <- list.dirs(out_root, recursive = FALSE, full.names = TRUE)
  curated <- curated[grepl("shiny-examples-curated", basename(curated))]
  if (length(curated)) {
    return(curated[[length(curated)]])
  }
  file.path(out_root, "shiny-examples")
}

input_dir <- if (length(trailing) >= 1) {
  normalizePath(trailing[[1]], winslash = "/", mustWork = TRUE)
} else {
  default_input()
}

gallery_dir <- file.path(pkg_root, "man", "figures", "gallery")
dir.create(gallery_dir, recursive = TRUE, showWarnings = FALSE)

manifest <- list(
  list(app = "001-hello", src = "01-initial.png", dest = "01-fluid-sidebar.png"),
  list(app = "006-tabsets", src = "02-nav-plot.png", dest = "02-tabsets.png"),
  list(app = "007-widgets", src = "02-button-update-view.png", dest = "03-action-button.png"),
  list(app = "010-download", src = "01-initial.png", dest = "04-download.png"),
  list(app = "012-datatables", src = "01-initial.png", dest = "05-datatables.png"),
  list(app = "013-selectize", src = "01-initial.png", dest = "06-selectize.png"),
  list(app = "015-layout-navbar", src = "01-initial.png", dest = "07-navbar.png"),
  list(
    dest = "08-page-sidebar.png",
    fixed = file.path(pkg_root, "man", "figures", "apple-glass-reference.png")
  )
)

promoted <- character()
skipped <- character()

for (item in manifest) {
  dest_path <- file.path(gallery_dir, item$dest)

  if (!is.null(item$fixed)) {
    if (!file.exists(item$fixed)) {
      skipped <- c(skipped, sprintf("%s (missing %s)", item$dest, item$fixed))
      next
    }
    file.copy(item$fixed, dest_path, overwrite = TRUE)
    promoted <- c(promoted, item$dest)
    next
  }

  src_path <- file.path(input_dir, item$app, item$src)
  if (!file.exists(src_path)) {
    skipped <- c(skipped, sprintf("%s (missing %s)", item$dest, src_path))
    next
  }
  file.copy(src_path, dest_path, overwrite = TRUE)
  promoted <- c(promoted, item$dest)
}

override <- Sys.getenv("SHINYGLASS_DOWNLOAD_SCREENSHOT", unset = "")
if (nzchar(override) && file.exists(override)) {
  file.copy(override, file.path(gallery_dir, "04-download.png"), overwrite = TRUE)
  message("Applied SHINYGLASS_DOWNLOAD_SCREENSHOT override for 04-download.png")
}

cat("Gallery directory:", gallery_dir, "\n")
cat("Input:", input_dir, "\n\n")
cat("Promoted (", length(promoted), "):\n", sep = "")
for (f in promoted) cat("  -", f, "\n")
if (length(skipped)) {
  cat("\nSkipped (", length(skipped), "):\n", sep = "")
  for (s in skipped) cat("  -", s, "\n")
}

invisible(promoted)