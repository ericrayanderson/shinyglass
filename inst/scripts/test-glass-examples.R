#!/usr/bin/env Rscript
# Smoke-test shinyglass on Shiny example app repos.
#
# Supports:
#   - rstudio/shiny-examples  (001-hello/, 002-text/, ...)
#   - rstudio/bslib           (inst/examples-shiny/card/, ...)
#
# Usage:
#   Rscript test-glass-examples.R /path/to/repo [limit]

args <- commandArgs(trailingOnly = TRUE)
repo_dir <- if (length(args) >= 1) args[[1]] else stop("Provide path to a cloned example repo")
limit <- if (length(args) >= 2) as.integer(args[[2]]) else Inf

if (!dir.exists(repo_dir)) {
  stop("Directory not found: ", repo_dir)
}

if (!requireNamespace("shinyglass", quietly = TRUE)) {
  stop("shinyglass must be installed before running this script.")
}

page_fns <- c(
  "fluidPage", "navbarPage", "fixedPage", "navlistPanel",
  "page_fluid", "page_navbar", "page_sidebar", "page_fillable", "page_fixed"
)
page_pat <- paste0("\\b(", paste(page_fns, collapse = "|"), ")\\s*\\(")

discover_app_dirs <- function(root) {
  bslib_dirs <- file.path(root, "inst/examples-shiny")
  if (dir.exists(bslib_dirs)) {
    dirs <- list.dirs(bslib_dirs, recursive = FALSE, full.names = TRUE)
    dirs <- dirs[file.exists(file.path(dirs, "app.R"))]
    return(sort(dirs))
  }

  dirs <- list.dirs(root, recursive = FALSE, full.names = TRUE)
  dirs <- dirs[grepl("/[0-9]{3}-", dirs)]
  sort(dirs)
}

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

find_matching_paren <- function(text, open_pos) {
  open_pos <- as.integer(open_pos[[1]])
  if (is.na(open_pos) || open_pos < 1L || open_pos > nchar(text)) {
    return(NA_integer_)
  }
  depth <- 0L
  i <- open_pos
  n <- nchar(text)
  while (i <= n) {
    ch <- substr(text, i, i)
    if (ch == "(") depth <- depth + 1L
    if (ch == ")") {
      depth <- depth - 1L
      if (depth == 0L) return(i)
    }
    i <- i + 1L
  }
  NA_integer_
}

replace_page_theme <- function(code) {
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

  page_open <- m[1] + attr(m, "match.length") - 1L
  page_close <- find_matching_paren(code, page_open)
  if (is.na(page_close)) {
    return(NA_character_)
  }

  header <- substr(code, page_open + 1L, page_close - 1L)
  theme_m <- regexpr("theme\\s*=", header, perl = TRUE)

  if (theme_m[1] != -1) {
    theme_start <- page_open + theme_m[1]
    val_start <- theme_start + attr(theme_m, "match.length")
    while (val_start <= nchar(code) && grepl("\\s", substr(code, val_start, val_start))) {
      val_start <- val_start + 1L
    }

    if (substr(code, val_start, val_start) == "(") {
      val_end <- find_matching_paren(code, val_start)
    } else {
      rest <- substr(code, val_start, nchar(code))
      fn_paren <- regexpr("\\(", rest, perl = TRUE)
      if (fn_paren[1] != -1) {
        val_end <- find_matching_paren(code, val_start + fn_paren[1] - 1L)
      } else {
        end_m <- regexpr(",|\\n", rest, perl = TRUE)
        val_end <- if (end_m[1] == -1) nchar(code) else val_start + end_m[1] - 2L
      }
    }

    if (is.na(val_end)) {
      return(NA_character_)
    }

    tail <- substr(code, val_end + 1L, nchar(code))
    tail <- sub("^\\s*,\\s*", "", tail, perl = TRUE)

    paste0(
      substr(code, 1, theme_start - 1L),
      "theme = glass_theme(), ",
      tail
    )
  } else {
    paste0(
      substr(code, 1, page_open),
      "theme = glass_theme(), ",
      substr(code, page_open + 1L, nchar(code))
    )
  }
}

app_dirs <- discover_app_dirs(repo_dir)
if (is.finite(limit)) {
  app_dirs <- head(app_dirs, limit)
}

repo_label <- if (dir.exists(file.path(repo_dir, "inst/examples-shiny"))) "bslib" else "shiny-examples"

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

cat("\nshinyglass smoke test (", repo_label, ")\n", sep = "")
cat("Directory:", repo_dir, "\n")
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