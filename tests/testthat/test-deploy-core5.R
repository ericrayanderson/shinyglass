# The deploy script and workflow live outside the CRAN tarball
# (.Rbuildignore drops inst/scripts and .github). This test runs from a
# source checkout and skips under R CMD check.

test_that("core5 is the five hosted demos", {
  deploy_path <- testthat::test_path("../../inst/scripts/deploy-shinyapps-demos.R")
  skip_if_not(file.exists(deploy_path))

  env <- new.env(parent = baseenv())
  sys.source(deploy_path, env)

  catalog <- env$demo_catalog("/pkg")
  expect_identical(
    env$core5_keys,
    c("demo", "dashboard", "inputs", "olympics", "chat")
  )
  expect_identical(env$expand_app_keys("core5", names(catalog)), env$core5_keys)
  expect_false("plotly_gt" %in% env$core5_keys)
  expect_false("intensity" %in% env$core5_keys)
  expect_true(all(c("plotly_gt", "intensity", "olympics", "chat") %in%
    env$expand_app_keys("all", names(catalog))))
  expect_identical(catalog$chat$appName, "shinyglass-chat")
  expect_identical(catalog$olympics$appName, "shinyglass-olympics")
  expect_identical(catalog$plotly_gt$appName, "shinyglass-plotly-gt")
  expect_identical(catalog$demo$appName, "shinyglass-demo")
  expect_identical(catalog$dashboard$appName, "shinyglass-dashboard")
  expect_identical(catalog$inputs$appName, "shinyglass-inputs")
  expect_true(file.exists(testthat::test_path("../../inst/examples/plotly-gt-demo.R")))

  src <- paste(readLines(deploy_path, warn = FALSE), collapse = "\n")
  expect_match(src, 'get_flag("--apps", "core5")', fixed = TRUE)
  expect_false(grepl("envVars\\s*=", src))
  expect_false(grepl("deploy_args\\$envVars", src))

  wf_path <- testthat::test_path("../../.github/workflows/deploy-shinyapps.yaml")
  wf <- paste(readLines(wf_path, warn = FALSE), collapse = "\n")
  expect_match(
    wf,
    'apps <- "demo,dashboard,inputs,olympics,chat"',
    fixed = TRUE
  )
  expect_false(grepl("olympics,plotly_gt,chat", wf, fixed = TRUE))
  expect_match(wf, "GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}", fixed = TRUE)
  expect_false(grepl("echo", wf, fixed = TRUE))
})

test_that("chat deploy stages GEMINI_API_KEY without logging it", {
  deploy_path <- testthat::test_path("../../inst/scripts/deploy-shinyapps-demos.R")
  skip_if_not(file.exists(deploy_path))

  env <- new.env(parent = baseenv())
  sys.source(deploy_path, env)

  secret <- "AIzaSyTESTKEY_do-not-leak"
  old <- Sys.getenv("GEMINI_API_KEY", unset = NA_character_)
  on.exit({
    if (is.na(old)) Sys.unsetenv("GEMINI_API_KEY") else Sys.setenv(GEMINI_API_KEY = old)
  }, add = TRUE)

  expect_identical(
    env$renviron_line("GEMINI_API_KEY", secret),
    paste0("GEMINI_API_KEY=", secret)
  )
  odd <- "AIzaSyAB+cd/ef="
  expect_identical(
    env$renviron_line("GEMINI_API_KEY", odd),
    paste0("GEMINI_API_KEY=", odd)
  )

  leaked <- paste0(secret, " ${HOME}")
  err <- tryCatch(
    env$renviron_line("GEMINI_API_KEY", leaked),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "characters")
  expect_false(grepl(secret, err, fixed = TRUE))
  expect_false(grepl("HOME", err, fixed = TRUE))

  dir <- tempfile("chat-stage-")
  dir.create(dir)
  Sys.unsetenv("GEMINI_API_KEY")
  quiet <- character()
  withCallingHandlers(
    staged <- env$stage_chat_secret(dir, "shinyglass-chat"),
    message = function(m) {
      quiet <<- c(quiet, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_false(staged)
  expect_false(file.exists(file.path(dir, ".Renviron")))
  expect_true(any(grepl("unset", quiet, fixed = TRUE)))

  other <- tempfile("other-stage-")
  dir.create(other)
  Sys.setenv(GEMINI_API_KEY = secret)
  expect_false(env$stage_chat_secret(other, "shinyglass-demo"))
  expect_false(file.exists(file.path(other, ".Renviron")))

  logged <- character()
  withCallingHandlers(
    staged <- env$stage_chat_secret(dir, "shinyglass-chat"),
    message = function(m) {
      logged <<- c(logged, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_true(staged)
  expect_false(any(grepl(secret, logged, fixed = TRUE)))
  expect_true(any(grepl("not logged", logged, fixed = TRUE)))

  path <- file.path(dir, ".Renviron")
  expect_true(file.exists(path))
  perms <- bitwAnd(as.integer(file.info(path)$mode), 511L)
  expect_identical(perms, 384L)

  Sys.unsetenv("GEMINI_API_KEY")
  readRenviron(path)
  expect_identical(Sys.getenv("GEMINI_API_KEY"), secret)
  unlink(path)
  unlink(other, recursive = TRUE)
})

test_that("chat staging copies www favicons and the icon is inline", {
  deploy_path <- testthat::test_path("../../inst/scripts/deploy-shinyapps-demos.R")
  skip_if_not(file.exists(deploy_path))
  src <- testthat::test_path("../../inst/examples/shinychat-glass/app.R")
  skip_if_not(file.exists(src))

  env <- new.env(parent = baseenv())
  sys.source(deploy_path, env)

  dest <- tempfile("chat-www-")
  env$stage_single(src, dest, c("shiny", "bslib", "shinyglass", "shinychat", "ellmer", "later"))
  on.exit(unlink(dest, recursive = TRUE), add = TRUE)

  expect_true(file.exists(file.path(dest, "app.R")))
  expect_true(file.exists(file.path(dest, "www", "favicon.svg")))
  expect_true(file.exists(file.path(dest, "www", "favicon.ico")))
  expect_gt(file.info(file.path(dest, "www", "favicon.ico"))$size, 32)

  app <- paste(readLines(file.path(dest, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app, "data:image/svg+xml;base64,", fixed = TRUE)
  expect_false(grepl('href = "favicon.svg"', app, fixed = TRUE))
  expect_match(app, 'href = "favicon.ico"', fixed = TRUE)
})

test_that("harbor notes loads a staged Renviron without printing the key", {
  app_path <- testthat::test_path("../../inst/examples/shinychat-glass/app.R")
  if (!file.exists(app_path)) {
    app_path <- system.file("examples/shinychat-glass", "app.R", package = "shinyglass")
  }
  skip_if_not(nzchar(app_path) && file.exists(app_path))
  skip_if_not_installed("shinychat", "0.5.0")
  skip_if_not_installed("ellmer", "0.5.0")
  skip_if_not_installed("coro")

  app_env <- new.env(parent = globalenv())
  sys.source(app_path, app_env)

  secret <- "AIzaSyTESTKEY_do-not-leak"
  old_gemini <- Sys.getenv("GEMINI_API_KEY", unset = NA_character_)
  old_google <- Sys.getenv("GOOGLE_API_KEY", unset = NA_character_)
  old_wd <- getwd()
  on.exit({
    setwd(old_wd)
    if (is.na(old_gemini)) Sys.unsetenv("GEMINI_API_KEY") else Sys.setenv(GEMINI_API_KEY = old_gemini)
    if (is.na(old_google)) Sys.unsetenv("GOOGLE_API_KEY") else Sys.setenv(GOOGLE_API_KEY = old_google)
  }, add = TRUE)

  dir <- tempfile("chat-renviron-")
  dir.create(dir)
  writeLines(paste0("GEMINI_API_KEY=", secret), file.path(dir, ".Renviron"))
  Sys.unsetenv(c("GEMINI_API_KEY", "GOOGLE_API_KEY"))
  setwd(dir)

  logged <- character()
  val <- NULL
  withCallingHandlers(
    {
      val <- app_env$gemini_key()
    },
    message = function(m) {
      logged <<- c(logged, conditionMessage(m))
      invokeRestart("muffleMessage")
    },
    warning = function(w) {
      logged <<- c(logged, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(val, secret)
  expect_false(any(grepl(secret, logged, fixed = TRUE)))
})
