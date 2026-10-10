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
  # Phones must not download the stylesheet or the script. The loader is an
  # inline script at the end of the body, so it does not sit in the head
  # and change when the app connects. It fetches the assets only when the
  # desktop media query matches. The resource prefix matches the dependency.
  prefix <- "shinyglass-phone-preview-0.5.0"
  loader <- sprintf(
    '<script id="shinyglass-phone-preview-loader">
(function () {
  var DESKTOP = "(pointer: fine) and (min-width: 900px)";
  var root = document.documentElement;
  var frameMeta = document.querySelector("meta[name=\\"shinyglass-phone-frame\\"]");
  if (frameMeta && frameMeta.getAttribute("content") === "0") {
    var appMeta = document.querySelector("meta[name=\\"shinyglass-phone-app\\"]");
    if (appMeta) root.setAttribute("data-phone-app", appMeta.getAttribute("content") || "");
    root.setAttribute("data-phone-frame", "0");
    return;
  }
  var query = window.matchMedia(DESKTOP);
  function load() {
    if (!query.matches || document.querySelector("script[data-phone-preview]")) return;
    var script = document.createElement("script");
    script.src = "%s/phone-preview.js";
    script.async = false;
    script.setAttribute("data-phone-preview", "1");
    document.head.appendChild(script);
  }
  if (typeof query.addEventListener === "function") query.addEventListener("change", load);
  else if (typeof query.addListener === "function") query.addListener(load);
  load();
})();
</script>',
    prefix
  )
  dep <- htmltools::htmlDependency(
    name = "shinyglass-phone-preview",
    version = "0.5.0",
    src = c(file = dir),
    meta = meta,
    all_files = TRUE
  )
  page <- htmltools::attachDependencies(page, dep, append = TRUE)
  htmltools::tagList(page, htmltools::HTML(loader))
}
