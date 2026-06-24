#!/usr/bin/env Rscript
# Smoke-test shinyglass on rstudio/shiny-examples apps.
#
# Usage:
#   Rscript test-shiny-examples.R /path/to/shiny-examples [limit]
#
# For each example, injects theme = glass_theme() into the page function,
# sources the app, and checks that the UI builds without error.

args <- commandArgs(trailingOnly = TRUE)
examples_dir <- if (length(args) >= 1) args[[1]] else stop("Provide path to shiny-examples clone")
limit <- if (length(args) >= 2) as.integer(args[[2]]) else Inf

if (!dir.exists(examples_dir)) {
  stop("Directory not found: ", examples_dir)
}

if (!requireNamespace("shinyglass", quietly = TRUE)) {
  stop("shinyglass must be installed before running this script.")
}

page_fns <- c("fluidPage", "navbarPage", "fixedPage", "navlistPanel")
page_pat <- paste0("\\b(", paste(page_fns, collapse = "|"), ")\\s*\\(")

find_app_files <- function(app_dir) {
  candidates <- c(
    file.path(app_dir, "global.R"),
    file.path(app_dir, "ui.R"),
    file.path(app_dir, "ui.r"),
    file.path(app_dir, "server.R"),
    file.path(app_dir, "server.r"),
    file.path(app_dir, "app.R")
  )
  unique(candidates[file.exists(candidates)])
}

primary_ui_file <- function(app_dir) {
  candidates <- c(
    file.path(app_dir, "app.R"),
    file.path(app_dir, "ui.R"),
    file.path(app_dir, "ui.r")
  )
  hit <- candidates[file.exists(candidates)]
  if (length(hit)) hit[[1]] else NA_character_
}

inject_theme <- function(code) {
  if (grepl("theme\\s*=\\s*glass_theme\\s*\\(", code, perl = TRUE)) {
    return(code)
  }

  if (!grepl("library\\s*\\(\\s*shinyglass\\s*\\)", code, perl = TRUE)) {
    code <- paste0("library(shinyglass)\n", code)
  }

  m <- gregexpr(page_pat, code, perl = TRUE)[[1]]
  if (length(m) == 0 || m[1] == -1) {
    return(NA_character_)
  }

  pos <- m[1] + attr(m, "match.length") - 1L
  paste0(
    substr(code, 1, pos),
    "theme = glass_theme(), ",
    substr(code, pos + 1, nchar(code))
  )
}

app_dirs <- list.dirs(examples_dir, recursive = FALSE, full.names = TRUE)
app_dirs <- app_dirs[grepl("/[0-9]{3}-", app_dirs)]
app_dirs <- sort(app_dirs)
if (is.finite(limit)) {
  app_dirs <- head(app_dirs, limit)
}

results <- data.frame(
  app = basename(app_dirs),
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

  patched <- inject_theme(code)
  if (is.na(patched)) {
    results$status[i] <- "skip"
    results$detail[i] <- "could not inject theme"
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
    } else if (!exists("server", envir = env, inherits = FALSE)) {
      # Many shiny-examples ui.R files use a bare fluidPage() expression
      # (no ui <-). Sourcing without error is enough for a smoke test.
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

cat("\nshinyglass x shiny-examples smoke test\n")
cat("Directory:", examples_dir, "\n")
cat("Tested:", nrow(results), "apps\n\n")

print(table(results$status))

fails <- results[results$status == "fail", , drop = FALSE]
if (nrow(fails) > 0) {
  cat("\nFailures:\n")
  apply(fails, 1, function(row) cat(" -", row[["app"]], ":", row[["detail"]], "\n"))
}

skips <- results[results$status == "skip", , drop = FALSE]
if (nrow(skips) > 0) {
  cat("\nSkipped:\n")
  apply(skips, 1, function(row) cat(" -", row[["app"]], ":", row[["detail"]], "\n"))
}

cat(sprintf(
  "\nPass rate: %.0f%% (%d/%d)\n",
  100 * mean(results$status == "pass"),
  sum(results$status == "pass"),
  nrow(results)
))