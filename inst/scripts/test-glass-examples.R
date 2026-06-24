#!/usr/bin/env Rscript
# Smoke-test shinyglass on Shiny example app repos.
#
# Usage:
#   Rscript test-glass-examples.R /path/to/repo [limit]

args <- commandArgs(trailingOnly = TRUE)
repo_dir <- if (length(args) >= 1) args[[1]] else stop("Provide path to a cloned example repo")
limit <- if (length(args) >= 2) as.integer(args[[2]]) else Inf

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(file_arg)) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/"))
} else {
  "."
}
source(file.path(script_dir, "glass-test-utils.R"))

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || identical(x, "")) y else x

if (!requireNamespace("shinyglass", quietly = TRUE)) {
  stop("shinyglass must be installed before running this script.")
}

app_dirs <- discover_app_dirs(repo_dir)
if (is.finite(limit)) {
  app_dirs <- head(app_dirs, limit)
}

results <- data.frame(
  app = vapply(app_dirs, basename, character(1)),
  status = character(length(app_dirs)),
  detail = character(length(app_dirs)),
  stringsAsFactors = FALSE
)

for (i in seq_along(app_dirs)) {
  app_dir <- app_dirs[[i]]
  files <- find_app_files(app_dir)
  ui_file <- primary_ui_file(app_dir)

  if (length(files) == 0 || is.na(ui_file)) {
    results$status[i] <- "skip"
    results$detail[i] <- "no app.R/ui.R"
    next
  }

  code <- paste(readLines(ui_file, warn = FALSE), collapse = "\n")

  if (grepl("\\bbs_themer\\s*\\(", code, perl = TRUE)) {
    results$status[i] <- "skip"
    results$detail[i] <- "bs_themer demo"
    next
  }

  if (grepl("\\bbootstrapPage\\s*\\(", code, perl = TRUE)) {
    results$status[i] <- "skip"
    results$detail[i] <- "bootstrapPage (legacy)"
    next
  }

  if (!grepl(page_pat, code, perl = TRUE)) {
    results$status[i] <- "skip"
    results$detail[i] <- "no supported page function"
    next
  }

  patched <- replace_page_theme(code)
  if (is.na(patched)) {
    results$status[i] <- "skip"
    results$detail[i] <- "could not patch theme"
    next
  }

  tmp <- tempfile(fileext = ".R")
  writeLines(patched, tmp)

  res <- tryCatch({
    env <- new.env(parent = globalenv())
    old_wd <- getwd()
    setwd(app_dir)
    on.exit(setwd(old_wd), add = TRUE)

    for (f in files) {
      if (identical(f, ui_file)) {
        source(tmp, local = env, chdir = TRUE)
      } else {
        source(f, local = env, chdir = TRUE)
      }
    }

    if (exists("ui", envir = env, inherits = FALSE)) {
      ui <- env$ui
      if (!inherits(ui, c("shiny.tag", "shiny.tag.list", "list"))) {
        stop("ui is not a Shiny UI object")
      }
    }

    TRUE
  }, error = function(e) e)

  unlink(tmp)

  if (inherits(res, "error")) {
    results$status[i] <- "fail"
    results$detail[i] <- conditionMessage(res)
  } else {
    results$status[i] <- "pass"
    results$detail[i] <- basename(ui_file)
  }
}

cat("\nshinyglass smoke test (", repo_label(repo_dir), ")\n", sep = "")
cat("Directory:", repo_dir, "\n")
cat("Tested:", nrow(results), "apps\n\n")

print(table(results$status))

fails <- results[results$status == "fail", , drop = FALSE]
if (nrow(fails) > 0) {
  cat("\nFailures:\n")
  apply(fails, 1, function(row) cat(" -", row[["app"]], ":", row[["detail"]], "\n"))
}

cat(sprintf(
  "\nPass rate: %.0f%% (%d/%d)\n",
  100 * mean(results$status == "pass"),
  sum(results$status == "pass"),
  nrow(results)
))