# Launch the compatibility fixture. Run from inst/scripts/browser:
#   Rscript compat-app.R
pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
app_path <- system.file("examples", "compat-glass.R", package = "shinyglass")
env <- new.env(parent = globalenv())
sys.source(app_path, env)
port <- as.integer(Sys.getenv("SHINYGLASS_COMPAT_PORT", "3942"))
if (is.na(port)) port <- 3942L
shiny::runApp(env$app, host = "127.0.0.1", port = port, launch.browser = FALSE)
