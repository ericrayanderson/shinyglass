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
    file.path(app_dir, "app.r"),
    file.path(app_dir, "ui.R"),
    file.path(app_dir, "ui.r"),
    # nested golem / modular layouts
    file.path(app_dir, "ui", "ui.R"),
    file.path(app_dir, "app", "ui.R"),
    file.path(app_dir, "src", "app", "ui.R")
  )
  existing <- candidates[file.exists(candidates)]
  if (!length(existing)) return(NA_character_)

  # Prefer a file that actually constructs a supported page (not a thin
  # launcher that only sources other files / run_app()).
  for (f in existing) {
    code <- paste(readLines(f, warn = FALSE), collapse = "\n")
    if (grepl(page_pat, code, perl = TRUE)) return(f)
  }
  existing[[1]]
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

skip_ws <- function(code, pos) {
  pos <- as.integer(pos[[1]])
  n <- nchar(code)
  while (pos <= n && grepl("^\\s$", substr(code, pos, pos))) {
    pos <- pos + 1L
  }
  if (pos > n) NA_integer_ else pos
}

find_theme_value_end <- function(code, val_start) {
  val_start <- as.integer(val_start[[1]])
  if (is.na(val_start)) return(NA_integer_)
  ch <- substr(code, val_start, val_start)
  if (identical(ch, "(")) {
    return(find_matching_paren(code, val_start))
  }

  rest <- substr(code, val_start, nchar(code))
  name_m <- regexpr("^[A-Za-z.][A-Za-z0-9_.]*(::[A-Za-z.][A-Za-z0-9_.]*)?", rest, perl = TRUE)
  if (name_m[1] == 1L) {
    name_len <- as.integer(attr(name_m, "match.length")[[1]])
    after <- val_start + name_len
    after_ws <- skip_ws(code, after)
    if (!is.na(after_ws) && identical(substr(code, after_ws, after_ws), "(")) {
      return(find_matching_paren(code, after_ws))
    }
    return(val_start + name_len - 1L)
  }

  depth <- 0L
  i <- val_start
  n <- nchar(code)
  while (i <= n) {
    ch <- substr(code, i, i)
    if (ch == "(" || ch == "[" || ch == "{") depth <- depth + 1L
    if (ch == ")" || ch == "]" || ch == "}") {
      if (depth == 0L) return(i - 1L)
      depth <- depth - 1L
    }
    if (depth == 0L && (ch == "," || ch == "\n")) return(i - 1L)
    i <- i + 1L
  }
  n
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

  # gregexpr match.length is a vector — use first page call only
  page_open <- as.integer(m[1] + attr(m, "match.length")[1] - 1L)
  page_close <- find_matching_paren(code, page_open)
  if (is.na(page_close)) {
    return(NA_character_)
  }

  header <- substr(code, page_open + 1L, page_close - 1L)
  theme_m <- regexpr("theme\\s*=", header, perl = TRUE)

  if (theme_m[1] != -1) {
    theme_start <- as.integer(page_open + theme_m[1])
    val_start <- skip_ws(
      code,
      theme_start + as.integer(attr(theme_m, "match.length")[[1]])
    )
    val_end <- find_theme_value_end(code, val_start)
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
  # Skip only when bootstrapPage is the outer page constructor (no fluid/navbar/page_*)
  if (grepl("\\bbootstrapPage\\s*\\(", code, perl = TRUE) &&
        !grepl(page_pat, code, perl = TRUE)) {
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
  # ui_file may be nested (ui/ui.R); preserve relative path under staged dir
  rel <- sub(paste0("^", normalizePath(app_dir, winslash = "/"), "/?"), "",
             normalizePath(ui_file, winslash = "/"))
  if (!nzchar(rel) || identical(rel, normalizePath(ui_file, winslash = "/"))) {
    rel <- basename(ui_file)
  }
  out_path <- file.path(staged, rel)
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(patched, out_path)

  list(ok = TRUE, dir = staged, ui_file = rel)
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