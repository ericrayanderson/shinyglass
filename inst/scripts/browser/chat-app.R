# Launch the shinychat glass example. Run from inst/scripts/browser:
#   Rscript chat-app.R
pkgload::load_all(normalizePath("../../.."), quiet = TRUE)
app_dir <- system.file("examples/shinychat-glass", package = "shinyglass")
port <- as.integer(Sys.getenv("SHINYGLASS_CHAT_PORT", "3943"))
if (is.na(port)) port <- 3943L
shiny::runApp(app_dir, host = "127.0.0.1", port = port, launch.browser = FALSE)
