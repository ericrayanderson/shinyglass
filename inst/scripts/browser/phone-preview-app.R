# Launch one core demo for the phone-preview Playwright spec.
# Run from inst/scripts/browser:
#   Rscript phone-preview-app.R
# SHINYGLASS_PHONE_APP is a path relative to the package root, or absolute.
# SHINYGLASS_PHONE_PORT selects the port (default 3945).
pkgload::load_all(normalizePath("../../.."), quiet = TRUE)

root <- normalizePath("../../..")
app <- Sys.getenv("SHINYGLASS_PHONE_APP", unset = "")
if (!nzchar(app)) {
  app <- file.path(root, "inst", "examples", "demo-app.R")
} else if (!grepl("^/", app)) {
  app <- file.path(root, app)
}
if (!file.exists(app) && !dir.exists(app)) {
  stop("Missing phone preview app: ", app, call. = FALSE)
}

port <- as.integer(Sys.getenv("SHINYGLASS_PHONE_PORT", "3945"))
if (is.na(port)) port <- 3945L
shiny::runApp(app, host = "127.0.0.1", port = port, launch.browser = FALSE)
