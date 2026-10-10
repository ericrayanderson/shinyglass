# Desktop phone preview for the hosted demos.
# Not a package export. deploy-shinyapps-demos.R copies this directory
# into each staged app as phone-preview/. Apps source this file, then call
# phone_preview() on the page object.

phone_preview_frame_value <- function(request) {
  if (is.null(request)) {
    return("")
  }
  qs <- request$QUERY_STRING
  if (is.null(qs) || !nzchar(qs)) {
    return("")
  }
  parsed <- shiny::parseQueryString(qs)
  value <- parsed[["frame"]]
  if (is.null(value) || !length(value)) {
    return("")
  }
  as.character(value[[1L]])
}

phone_preview_asset_dir <- function() {
  hinted <- NULL
  if (exists(".phone_preview_dir", inherits = TRUE)) {
    hinted <- get(".phone_preview_dir", inherits = TRUE)
  }
  candidates <- character()
  if (is.character(hinted) && length(hinted) == 1L && nzchar(hinted)) {
    candidates <- c(candidates, hinted)
  }
  candidates <- c(candidates, file.path(getwd(), "phone-preview"))
  root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  for (i in seq_len(8L)) {
    candidates <- c(
      candidates,
      file.path(root, "inst", "examples", "_shared"),
      file.path(root, "_shared")
    )
    parent <- dirname(root)
    if (identical(parent, root)) break
    root <- parent
  }
  installed <- system.file("examples", "_shared", package = "shinyglass")
  if (nzchar(installed)) candidates <- c(candidates, installed)
  candidates <- unique(candidates[nzchar(candidates)])
  for (dir in candidates) {
    if (file.exists(file.path(dir, "phone-preview.js")) &&
        file.exists(file.path(dir, "phone-preview.css"))) {
      return(normalizePath(dir, winslash = "/", mustWork = TRUE))
    }
  }
  ""
}

phone_preview <- function(page, app, request = NULL) {
  if (!is.character(app) || length(app) != 1L || !grepl("^[a-z0-9-]+$", app)) {
    stop("`app` must be a short id such as \"demo\".", call. = FALSE)
  }
  dir <- phone_preview_asset_dir()
  if (!nzchar(dir)) {
    stop("Phone preview assets were not found.", call. = FALSE)
  }
  frame <- phone_preview_frame_value(request)
  meta <- list(`shinyglass-phone-app` = app)
  if (identical(frame, "0")) {
    meta[["shinyglass-phone-frame"]] <- "0"
  }
  dep <- htmltools::htmlDependency(
    name = "shinyglass-phone-preview",
    version = "0.5.0",
    src = c(file = dir),
    script = "phone-preview.js",
    stylesheet = "phone-preview.css",
    meta = meta,
    all_files = FALSE
  )
  htmltools::attachDependencies(page, dep, append = TRUE)
}
