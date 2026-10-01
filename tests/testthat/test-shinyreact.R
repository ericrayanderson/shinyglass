dep_names <- function(deps) {
  vapply(deps, function(d) d$name, character(1))
}

resolved_bootstrap <- function(ui) {
  deps <- htmltools::resolveDependencies(htmltools::findDependencies(ui))
  deps[dep_names(deps) == "bootstrap"]
}

css_text <- function(theme) {
  deps <- bslib::bs_theme_dependencies(theme)
  chunks <- character()
  for (d in deps) {
    src <- d$src
    if (is.list(src) && !is.null(src$file)) src <- src$file
    sheets <- d$stylesheet
    if (is.null(sheets)) next
    for (f in if (is.list(sheets)) unlist(sheets) else sheets) {
      path <- file.path(src, f)
      if (file.exists(path)) {
        chunks <- c(chunks, paste(readLines(path, warn = FALSE), collapse = "\n"))
      }
    }
  }
  paste(chunks, collapse = "\n")
}

local_react_www <- function() {
  dir <- tempfile("glass-react-")
  dir.create(file.path(dir, "www"), recursive = TRUE)
  writeLines("/* shinyreact entry */", file.path(dir, "www", "ui.js"))
  dir
}

test_that("compiled CSS ships an opt-in glass surface", {
  css <- css_text(glass_theme())
  expect_match(css, "\\.glass-surface")
  expect_match(css, "\\.glass-muted")
  expect_match(css, "\\.glass-sidebar")
  expect_match(css, "\\.glass-button-primary")
  expect_match(css, "\\.glass-page")
  expect_match(css, "glass-surface \\.shiny-plot-output|glass-surface.shiny-plot-output")
  js <- paste(readLines(system.file("js", "shiny-glass.js", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(js, "adoptShadow")
  expect_match(js, "data-shinyglass-shadow")
})

test_that("react module is an ES module and does not bundle React", {
  path <- system.file("js", "shinyglass-react.js", package = "shinyglass")
  js <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_match(js, "export function useGlassTheme")
  expect_match(js, "export function GlassSidebar")
  expect_match(js, "export function GlassButton")
  expect_match(js, "export function GlassSurface")
  expect_match(js, "window.shinyreact")
  expect_false(grepl("from \"react\"", js, fixed = TRUE))
  expect_false(grepl("from 'react'", js, fixed = TRUE))
  expect_false(grepl("#[0-9A-Fa-f]{3,8}", js))
  dep <- glass_react_dependency()
  expect_s3_class(dep, "html_dependency")
  expect_identical(dep$name, "shinyglass-react")
  expect_identical(dep$script$type, "module")
  theme_names <- dep_names(bslib::bs_theme_dependencies(glass_theme()))
  expect_false("shinyglass-react" %in% theme_names)
})

test_that("glass_theme_dependencies is a list of html dependencies", {
  deps <- glass_theme_dependencies(glass_theme(preset = "dark"))
  expect_true(length(deps) >= 1)
  expect_true(all(vapply(deps, inherits, logical(1), "html_dependency")))
  names <- dep_names(deps)
  expect_true("bootstrap" %in% names)
  expect_true("shinyglass" %in% names)
  expect_true("shinyglass-preset" %in% names)
  expect_true("shinyglass-react" %in% names)
  preset <- deps[names == "shinyglass-preset"][[1]]
  expect_match(preset$head, 'var p="dark"', fixed = TRUE)
  expect_error(glass_theme_dependencies(list()), "theme")
})

test_that("glass_page_react keeps Bootstrap and glass CSS", {
  skip_if_not_installed("shinyreact")
  dir <- local_react_www()
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)

  ui <- glass_page_react(theme = glass_theme(preset = "dark", scene = "harbor"), title = "Glass")
  bs <- resolved_bootstrap(ui)
  expect_length(bs, 1)
  expect_false(identical(bs[[1]]$version, "9999"))
  expect_true(length(bs[[1]]$stylesheet) >= 1)

  deps <- htmltools::findDependencies(ui)
  names <- dep_names(deps)
  expect_true("shinyglass" %in% names)
  expect_true("shinyreact" %in% names)
  expect_true("shinyglass-react" %in% names)
  preset <- deps[names == "shinyglass-preset"][[1]]
  expect_match(preset$head, 'var p="dark"', fixed = TRUE)
  expect_match(preset$head, 'var scene="harbor"', fixed = TRUE)
})

test_that("unnamed theme on page_react suppresses the glass stylesheet", {
  skip_if_not_installed("shinyreact")
  dir <- local_react_www()
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)

  named <- shinyreact::page_react(theme = glass_theme())
  unnamed <- shinyreact::page_react(glass_theme())

  named_bs <- resolved_bootstrap(named)
  unnamed_bs <- resolved_bootstrap(unnamed)
  expect_false(identical(named_bs[[1]]$version, "9999"))
  expect_identical(unnamed_bs[[1]]$version, "9999")
  expect_null(unnamed_bs[[1]]$stylesheet)
})

test_that("page_react_html accepts glass_theme_dependencies as extra_deps", {
  skip_if_not_installed("shinyreact")
  dir <- tempfile("glass-html-")
  dir.create(file.path(dir, "www"), recursive = TRUE)
  # Placeholder must match shinyreact's deps_placeholder exactly.
  writeLines(
    c(
      "<!DOCTYPE html>",
      "<html>",
      "<head>",
      shinyreact:::deps_placeholder,
      "</head>",
      "<body></body>",
      "</html>"
    ),
    file.path(dir, "www", "index.html")
  )
  ui <- shinyreact::page_react_html(
    path = file.path(dir, "www", "index.html"),
    extra_deps = glass_theme_dependencies(glass_theme(preset = "light"))
  )
  deps <- htmltools::findDependencies(ui)
  names <- dep_names(deps)
  expect_true("shinyglass" %in% names)
  expect_true("bootstrap" %in% names)
  expect_true("shinyglass-react" %in% names)
  expect_false("9999" %in% vapply(deps, function(d) d$version, ""))
})

script_src <- function(dep) {
  sc <- dep$script
  if (is.null(sc)) {
    return(NA_character_)
  }
  if (is.list(sc) && !is.null(sc$src)) {
    return(sc$src)
  }
  if (is.character(sc)) {
    return(sc[[1]])
  }
  NA_character_
}

test_that("react module script is before the app module", {
  skip_if_not_installed("shinyreact")
  dir <- local_react_www()
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)

  ui <- glass_page_react(theme = glass_theme())
  deps <- htmltools::renderTags(ui)$dependencies
  srcs <- vapply(deps, script_src, character(1))
  react_pos <- match("shinyglass-react.js", srcs)
  ui_pos <- match("ui.js", srcs)
  expect_false(is.na(react_pos))
  expect_gt(ui_pos, react_pos)
  react_dep <- deps[[react_pos]]
  expect_identical(react_dep$script$type, "module")

  head <- htmltools::renderDependencies(deps)
  react_html <- regexpr("shinyglass-react\\.js", head)[[1]]
  ui_html <- regexpr("ui\\.js", head)[[1]]
  expect_gt(react_html, 0)
  expect_gt(ui_html, react_html)
  expect_match(head, "shinyglass-react.js\" type=\"module\"|type=\"module\"[^>]*shinyglass-react.js")
})

test_that("example client uses components and no hard-coded colors", {
  ex <- system.file("examples/shinyreact-glass", package = "shinyglass")
  expect_false(file.exists(file.path(ex, "www", "ui.css")))
  ui <- paste(readLines(file.path(ex, "www", "ui.js"), warn = FALSE), collapse = "\n")
  app <- paste(readLines(file.path(ex, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(ui, "useGlassTheme")
  expect_match(ui, "GlassSidebar")
  expect_match(ui, "GlassButton")
  expect_match(ui, "GlassSurface")
  expect_false(grepl("#[0-9A-Fa-f]{3,8}", ui))
  expect_false(grepl("#[0-9A-Fa-f]{3,8}", app))
  expect_match(app, "glass_plot_colors")
})

test_that("glass_page_react rejects a non-theme and a missing shinyreact", {
  if (!requireNamespace("shinyreact", quietly = TRUE)) {
    expect_error(glass_page_react(), "shinyreact")
    return()
  }
  expect_error(glass_page_react(theme = "dark"), "theme")
})
