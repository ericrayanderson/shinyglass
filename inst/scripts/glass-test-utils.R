# Shared helpers for shinyglass example testing scripts.

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

repo_label <- function(root) {
  if (dir.exists(file.path(root, "inst/examples-shiny"))) "bslib" else "shiny-examples"
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

prepare_patched_app_dir <- function(app_dir) {
  ui_file <- primary_ui_file(app_dir)
  if (is.na(ui_file)) {
    return(list(ok = FALSE, reason = "no app.R/ui.R"))
  }

  code <- paste(readLines(ui_file, warn = FALSE), collapse = "\n")

  if (grepl("\\bbs_themer\\s*\\(", code, perl = TRUE)) {
    return(list(ok = FALSE, reason = "bs_themer demo"))
  }
  if (grepl("\\bbootstrapPage\\s*\\(", code, perl = TRUE)) {
    return(list(ok = FALSE, reason = "bootstrapPage (legacy)"))
  }
  if (!grepl(page_pat, code, perl = TRUE)) {
    return(list(ok = FALSE, reason = "no supported page function"))
  }

  patched <- replace_page_theme(code)
  if (is.na(patched)) {
    return(list(ok = FALSE, reason = "could not patch theme"))
  }

  tmp <- tempfile("glass-app-")
  dir.create(tmp, recursive = TRUE)
  file.copy(app_dir, tmp, recursive = TRUE)
  staged <- file.path(tmp, basename(app_dir))
  writeLines(patched, file.path(staged, basename(ui_file)))

  list(ok = TRUE, dir = staged, ui_file = basename(ui_file))
}

wait_for_url <- function(url, timeout = 60) {
  deadline <- Sys.time() + timeout
  h <- curl::new_handle(connecttimeout = 3L, timeout = 5L)
  while (Sys.time() < deadline) {
    ok <- tryCatch(
      curl::curl_fetch_memory(url, handle = h)$status_code == 200,
      error = function(e) FALSE
    )
    if (ok) return(TRUE)
    Sys.sleep(0.5)
  }
  FALSE
}

wait_for_shiny <- function(session, timeout = 30) {
  js <- sprintf("
    new Promise((resolve, reject) => {
      const deadline = Date.now() + %d;
      const check = () => {
        const bound = document.querySelectorAll('.shiny-bound-output, .shiny-bound-input').length;
        const busy = document.querySelectorAll('.shiny-busy').length;
        if (bound > 0 && busy === 0) { resolve(true); return; }
        if (Date.now() > deadline) { resolve(false); return; }
        setTimeout(check, 300);
      };
      check();
    });
  ", timeout * 1000L)

  session$Runtime$evaluate(
    expression = js,
    awaitPromise = TRUE,
    returnByValue = TRUE,
    timeout = (timeout + 5) * 1000
  )
}