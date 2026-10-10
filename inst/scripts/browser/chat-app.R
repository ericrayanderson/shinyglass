# Launch the shinychat glass example from a deploy-style stage.
# Run from inst/scripts/browser:
#   Rscript chat-app.R
# SHINYGLASS_CHAT_MOCK_LIVE=1 answers through the local live stand-in.
# SHINYGLASS_CHAT_PORT selects the port (default 3943).
pkgload::load_all(normalizePath("../../.."), quiet = TRUE)

deploy_path <- normalizePath("../deploy-shinyapps-demos.R")
env <- new.env(parent = baseenv())
sys.source(deploy_path, env)

src <- system.file("examples/shinychat-glass", "app.R", package = "shinyglass")
if (!nzchar(src) || !file.exists(src)) {
  stop("Missing shinychat-glass example.", call. = FALSE)
}

stage_dir <- file.path(tempdir(), paste0("shinyglass-chat-browser-", Sys.getpid()))
env$stage_single(
  src,
  stage_dir,
  c("shiny", "bslib", "shinyglass", "shinychat", "ellmer", "later")
)

port <- as.integer(Sys.getenv("SHINYGLASS_CHAT_PORT", "3943"))
if (is.na(port)) port <- 3943L
shiny::runApp(stage_dir, host = "127.0.0.1", port = port, launch.browser = FALSE)
