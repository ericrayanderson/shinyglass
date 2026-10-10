# Phone preview is an example helper, not a package export.

test_that("phone preview attaches assets and suppresses the frame", {
  helper <- testthat::test_path("../../inst/examples/_shared/phone-preview.R")
  skip_if_not(file.exists(helper))
  skip_if_not_installed("shiny")

  env <- new.env(parent = globalenv())
  sys.source(helper, env)
  env$.phone_preview_dir <- dirname(helper)

  page <- htmltools::div("app")
  outer <- env$phone_preview(page, app = "demo", request = NULL)
  framed <- env$phone_preview(
    page,
    app = "demo",
    request = list(QUERY_STRING = "other=1&frame=0")
  )

  dep_of <- function(ui) {
    deps <- htmltools::findDependencies(ui)
    deps <- Filter(function(dep) identical(dep$name, "shinyglass-phone-preview"), deps)
    expect_length(deps, 1L)
    deps[[1L]]
  }

  outer_dep <- dep_of(outer)
  frame_dep <- dep_of(framed)
  expect_identical(outer_dep$meta[["shinyglass-phone-app"]], "demo")
  expect_null(outer_dep$meta[["shinyglass-phone-frame"]])
  expect_identical(frame_dep$meta[["shinyglass-phone-frame"]], "0")
  expect_identical(outer_dep$script, "phone-preview.js")
  expect_identical(outer_dep$stylesheet, "phone-preview.css")
  expect_true(file.exists(file.path(outer_dep$src$file, "phone-preview.js")))

  # Attaching the dependency must not stack onto the shared page object.
  expect_length(htmltools::findDependencies(page), 0L)
  again <- env$phone_preview(page, app = "demo", request = NULL)
  expect_length(
    Filter(
      function(dep) identical(dep$name, "shinyglass-phone-preview"),
      htmltools::findDependencies(again)
    ),
    1L
  )

  expect_error(env$phone_preview(page, app = "Demo App"), "short id")
})

test_that("core5 staging copies the phone preview helper", {
  deploy_path <- testthat::test_path("../../inst/scripts/deploy-shinyapps-demos.R")
  skip_if_not(file.exists(deploy_path))
  src <- testthat::test_path("../../inst/examples/demo-app.R")
  skip_if_not(file.exists(src))

  env <- new.env(parent = baseenv())
  sys.source(deploy_path, env)

  dest <- tempfile("phone-stage-")
  env$stage_single(src, dest, c("shiny", "bslib", "shinyglass"))
  on.exit(unlink(dest, recursive = TRUE), add = TRUE)

  expect_true(file.exists(file.path(dest, "phone-preview", "phone-preview.js")))
  expect_true(file.exists(file.path(dest, "phone-preview", "phone-preview.css")))
  expect_true(file.exists(file.path(dest, "phone-preview", "phone-preview.R")))
  app <- paste(readLines(file.path(dest, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app, 'app = "demo"', fixed = TRUE)
  expect_match(app, "phone_preview(", fixed = TRUE)

  olympics <- testthat::test_path("../../inst/shinyapps/olympic-medals")
  skip_if_not(dir.exists(olympics))
  dest_olympics <- tempfile("olympics-stage-")
  env$stage_dreamrs(olympics, "app-glass.R", dest_olympics, c("shiny", "shinyglass"))
  on.exit(unlink(dest_olympics, recursive = TRUE), add = TRUE)
  expect_true(file.exists(file.path(dest_olympics, "app.R")))
  expect_true(file.exists(file.path(dest_olympics, "phone-preview", "phone-preview.js")))
  olympics_app <- paste(readLines(file.path(dest_olympics, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(olympics_app, 'app = "olympics"', fixed = TRUE)
})
