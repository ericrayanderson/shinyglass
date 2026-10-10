#!/usr/bin/env Rscript
# Deploy curated shinyglass demos to shinyapps.io.
#
# Prerequisites (one-time on your machine — do not commit secrets):
#   install.packages(c("rsconnect", "remotes"))
#   rsconnect::setAccountInfo(
#     name   = "<account>",
#     token  = "<token>",
#     secret = "<secret>"
#   )
#   # shinyglass MUST be installed from GitHub (not a local path) so renv can
#   # snapshot it:
#   remotes::install_github("ericrayanderson/shinyglass", upgrade = "never")
#
# Usage (from package root):
#   Rscript inst/scripts/deploy-shinyapps-demos.R
#   Rscript inst/scripts/deploy-shinyapps-demos.R --apps=core5
#   Rscript inst/scripts/deploy-shinyapps-demos.R --apps=demo,chat
#   Rscript inst/scripts/deploy-shinyapps-demos.R --apps=all --dry-run
#
# core5 (the default) is the five-app shinyapps.io set:
#   shinyglass-demo, shinyglass-dashboard, shinyglass-inputs,
#   shinyglass-olympics, shinyglass-chat.
# plotly_gt stays in the catalog. inst/examples/plotly-gt-demo.R stays a
# local example. intensity stays in the catalog too. `all` lists every
# catalog entry, which is more than the five hosted slots.
#
# After deploy, paste the printed URLs into README.md "Live demos".
#
# Harbor notes (`chat`, shinyapps name shinyglass-chat) answers with a
# local script unless GEMINI_API_KEY is set in the environment that runs
# this script. The value is written to a temporary .Renviron in the chat
# staging directory and is never printed. shinyapps.io rejects the
# Connect-only envVars argument of deployApp(). The staged file is the
# equivalent. Do not put the key in this script or the repo.
# The live chain is gemini-3.5-flash-lite, then gemini-3.8-flash, then
# gemini-3.7-flash. SHINYGLASS_CHAT_MODEL is tried first when set.
# Web search is off. Sources are the curated pages for the topic.
# Each session allows 8 messages of at most 400 characters. The local
# note is used only when every model in the chain fails.

# Hosted set for a shinyapps.io plan with five slots. plotly_gt is absent
# on purpose. olympics and chat stay.
core5_keys <- c("demo", "dashboard", "inputs", "olympics", "chat")

expand_app_keys <- function(apps_arg, catalog_names) {
  if (identical(apps_arg, "core5")) {
    return(core5_keys)
  }
  if (identical(apps_arg, "all")) {
    return(catalog_names)
  }
  trimws(strsplit(apps_arg, ",", fixed = TRUE)[[1]])
}

# Unquoted .Renviron tokens only. ${...} would expand, and a quote or
# newline would break the line. The value is never placed in a message.
renviron_line <- function(name, value) {
  if (!identical(name, "GEMINI_API_KEY")) {
    stop("Refusing to stage an unexpected variable name.", call. = FALSE)
  }
  if (!is.character(value) || length(value) != 1L || is.na(value) || !nzchar(value)) {
    stop("Refusing to stage an empty GEMINI_API_KEY.", call. = FALSE)
  }
  if (grepl("[^A-Za-z0-9_.=/+-]", value)) {
    stop(
      "Refusing to stage GEMINI_API_KEY because it contains characters this deploy path will not write.",
      call. = FALSE
    )
  }
  paste0(name, "=", value)
}

stage_chat_secret <- function(app_dir, app_name) {
  if (!identical(app_name, "shinyglass-chat")) {
    return(invisible(FALSE))
  }
  value <- Sys.getenv("GEMINI_API_KEY", "")
  if (!nzchar(value)) {
    message(
      "GEMINI_API_KEY is unset. ", app_name,
      " will keep the local script."
    )
    return(invisible(FALSE))
  }
  line <- renviron_line("GEMINI_API_KEY", value)
  path <- file.path(app_dir, ".Renviron")
  writeLines(line, path, useBytes = TRUE)
  Sys.chmod(path, "0600")
  message(
    "Staged GEMINI_API_KEY for ", app_name,
    " in a temporary .Renviron. The value was not logged."
  )
  invisible(TRUE)
}

`%||%` <- function(x, y) if (is.null(x) || !length(x) || (is.character(x) && !nzchar(x[[1]]))) y else x

demo_catalog <- function(pkg_root) {
  list(
    demo = list(
      appName = "shinyglass-demo",
      source = file.path(pkg_root, "inst", "examples", "demo-app.R"),
      kind = "single",
      imports = c("shiny", "bslib", "ggplot2", "shinyglass")
    ),
    dashboard = list(
      appName = "shinyglass-dashboard",
      source = file.path(pkg_root, "inst", "examples", "bslib-dashboard.R"),
      kind = "single",
      imports = c("shiny", "bslib", "ggplot2", "DT", "shinyglass")
    ),
    intensity = list(
      appName = "shinyglass-intensity",
      source = file.path(pkg_root, "inst", "examples", "intensity-slider-demo.R"),
      kind = "single",
      imports = c("shiny", "bslib", "ggplot2", "shinyglass")
    ),
    inputs = list(
      appName = "shinyglass-inputs",
      source = file.path(pkg_root, "inst", "examples", "inputs-gallery.R"),
      kind = "single",
      imports = c("shiny", "bslib", "shinyglass")
    ),
    olympics = list(
      appName = "shinyglass-olympics",
      source = file.path(pkg_root, "inst", "shinyapps", "olympic-medals"),
      kind = "dreamrs",
      entry = "app-glass.R",
      imports = c(
        "shiny", "shinyWidgets", "ggplot2", "ggthemes", "ggtext", "bslib", "dplyr",
        "data.table", "reactable", "tidyr", "shinyglass"
      )
    ),
    plotly_gt = list(
      appName = "shinyglass-plotly-gt",
      source = file.path(pkg_root, "inst", "examples", "plotly-gt-demo.R"),
      kind = "single",
      imports = c("shiny", "bslib", "plotly", "gt", "waiter", "shinyglass")
    ),
    chat = list(
      appName = "shinyglass-chat",
      source = file.path(pkg_root, "inst", "examples", "shinychat-glass", "app.R"),
      kind = "single",
      imports = c("shiny", "bslib", "shinyglass", "shinychat", "ellmer", "later")
    )
  )
}

write_demo_description <- function(app_dir, imports) {
  writeLines(
    c(
      "Package: shinyglassdemo",
      "Title: shinyglass demo",
      "Version: 0.0.0.9000",
      paste0("Imports: ", paste(imports, collapse = ", ")),
      "Remotes: github::ericrayanderson/shinyglass"
    ),
    file.path(app_dir, "DESCRIPTION")
  )
}

stage_single <- function(src_file, app_dir, imports) {
  if (!file.exists(src_file)) {
    stop("Missing example: ", src_file, call. = FALSE)
  }
  if (dir.exists(app_dir)) {
    unlink(app_dir, recursive = TRUE)
  }
  dir.create(app_dir, recursive = TRUE, showWarnings = FALSE)
  writeLines(
    c(
      "# Generated by deploy-shinyapps-demos.R — do not edit by hand",
      readLines(src_file, warn = FALSE)
    ),
    file.path(app_dir, "app.R")
  )
  # A sibling www/ is the app static root. shinyapps.io serves the app
  # on a subpath, so favicon files have to be staged next to app.R.
  www_src <- file.path(dirname(src_file), "www")
  if (dir.exists(www_src)) {
    ok <- file.copy(www_src, app_dir, recursive = TRUE)
    if (!isTRUE(ok)) {
      stop("Could not stage www assets from ", www_src, call. = FALSE)
    }
  }
  write_demo_description(app_dir, imports)
}

stage_dreamrs <- function(app_src, entry, app_dir, imports) {
  if (!dir.exists(app_src)) {
    stop(
      "Missing dreamRs app dir: ", app_src,
      "\nVendored under inst/shinyapps (not in CRAN tarball).",
      call. = FALSE
    )
  }
  if (dir.exists(app_dir)) {
    unlink(app_dir, recursive = TRUE)
  }
  dir.create(dirname(app_dir), recursive = TRUE, showWarnings = FALSE)
  file.copy(app_src, dirname(app_dir), recursive = TRUE)
  copied <- file.path(dirname(app_dir), basename(app_src))
  if (!identical(normalizePath(copied), normalizePath(app_dir, mustWork = FALSE))) {
    if (dir.exists(app_dir)) {
      unlink(app_dir, recursive = TRUE)
    }
    file.rename(copied, app_dir)
  }
  entry_path <- file.path(app_dir, entry)
  if (!file.exists(entry_path)) {
    stop("Missing entry ", entry, " in ", app_dir, call. = FALSE)
  }
  file.copy(entry_path, file.path(app_dir, "app.R"), overwrite = TRUE)
  write_demo_description(app_dir, imports)
}

if (sys.nframe() == 0L) {

args <- commandArgs(trailingOnly = TRUE)

get_flag <- function(flag, default = NULL) {
  hit <- grep(paste0("^", flag, "="), args, value = TRUE)
  if (!length(hit)) {
    return(default)
  }
  sub(paste0("^", flag, "="), "", hit[[1]])
}

has_flag <- function(flag) any(args == flag)

dry_run <- has_flag("--dry-run")
account <- get_flag("--account", NULL)
apps_arg <- get_flag("--apps", "core5")

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  stop('Install rsconnect first: install.packages("rsconnect")', call. = FALSE)
}

# setup-r exports an unnamed renv repository override and pak stamps
# Repository: RSPM. Snapshot against public CRAN so shinyapps.io can fetch
# the same source tarballs. Fail the URL check below if anything still
# records a non-URL repository name.
if (identical(Sys.getenv("GITHUB_ACTIONS"), "true")) {
  Sys.unsetenv(c("RENV_CONFIG_REPOS_OVERRIDE", "RSPM"))
  options(repos = c(CRAN = "https://cloud.r-project.org"))
}

script_path <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1]
)
if (!is.na(script_path) && nzchar(script_path)) {
  pkg_root <- normalizePath(file.path(dirname(script_path), "..", ".."), winslash = "/")
} else {
  pkg_root <- normalizePath(".", winslash = "/")
}

# Fail fast if shinyglass is a local-path install (renv cannot snapshot those).
sg_desc <- utils::packageDescription("shinyglass")
if (is.list(sg_desc)) {
  remote_type <- sg_desc$RemoteType
  if (is.null(remote_type) || !remote_type %in% c("github", "gitlab", "bitbucket", "url", "standard")) {
    # CRAN install has no RemoteType — OK. Local/path installs often have
    # RemoteType "local" or empty with RemoteUrl file://
    if (identical(remote_type, "local") ||
      grepl("^file:", sg_desc$RemoteUrl %||% "")) {
      stop(
        "shinyglass is installed from a local path; renv cannot snapshot it.\n",
        "Reinstall from GitHub first:\n",
        "  remotes::install_github(\"ericrayanderson/shinyglass\", upgrade = \"never\", force = TRUE)",
        call. = FALSE
      )
    }
  }
}

catalog <- demo_catalog(pkg_root)
stopifnot(
  all(core5_keys %in% names(catalog)),
  "olympics" %in% core5_keys,
  "chat" %in% core5_keys,
  !"plotly_gt" %in% core5_keys
)
app_keys <- expand_app_keys(apps_arg, names(catalog))

unknown <- setdiff(app_keys, names(catalog))
if (length(unknown)) {
  stop(
    "Unknown apps: ", paste(unknown, collapse = ", "),
    "\nChoose from: ", paste(names(catalog), collapse = ", "),
    call. = FALSE
  )
}

staging <- file.path(tempdir(), "shinyglass-deploy")
dir.create(staging, showWarnings = FALSE, recursive = TRUE)

urls <- character()
for (key in app_keys) {
  spec <- catalog[[key]]
  app_dir <- file.path(staging, spec$appName)
  message("Staging ", spec$appName, " …")
  imports <- spec$imports %||% c("shiny", "bslib", "shinyglass")
  if (identical(spec$kind, "single")) {
    stage_single(spec$source, app_dir, imports)
  } else {
    stage_dreamrs(spec$source, spec$entry, app_dir, imports)
  }
  # Names only travel in the log. The Connect-only envVars argument
  # aborts on shinyapps.io, so the key rides in the staged file.
  stage_chat_secret(app_dir, spec$appName)

  # Use the same dependency resolver as deployment, including in dry runs.
  deps <- rsconnect::appDependencies(app_dir)
  repos <- deps$Repository
  invalid <- !is.na(repos) & nzchar(repos) & !grepl("^https?://", repos)
  if (any(invalid)) {
    stop("Unresolved dependency repository for: ",
         paste(sprintf("%s (%s)", deps$Package[invalid], repos[invalid]),
               collapse = ", "),
         call. = FALSE)
  }
  message("Validated ", nrow(deps), " dependencies for ", spec$appName)

  if (dry_run) {
    message("[dry-run] would deployApp(", app_dir, ", appName = ", spec$appName, ")")
    next
  }

  deploy_args <- list(
    appDir = app_dir,
    appName = spec$appName,
    forceUpdate = TRUE,
    lint = FALSE,
    launch.browser = FALSE,
    # Anyone with the URL can view (not account-only).
    appVisibility = "public"
  )
  if (!is.null(account) && nzchar(account)) {
    deploy_args$account <- account
  }

  message("Deploying ", spec$appName, " …")
  do.call(rsconnect::deployApp, deploy_args)

  acct <- account
  if (is.null(acct) || !nzchar(acct)) {
    accts <- tryCatch(rsconnect::accounts(), error = function(e) NULL)
    if (!is.null(accts) && nrow(accts)) {
      acct <- accts$name[[1]]
    }
  }
  if (is.null(acct) || !nzchar(acct)) {
    acct <- "<account>"
  }
  url <- sprintf("https://%s.shinyapps.io/%s/", acct, spec$appName)
  urls <- c(urls, sprintf("- [%s](%s)", spec$appName, url))
  message("  → ", url)
}

if (length(urls)) {
  message("\n## Live demos (paste into README)\n")
  message(paste(urls, collapse = "\n"))
}

message("\nDone.")

}
