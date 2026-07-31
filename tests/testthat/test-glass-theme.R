test_that("glass_theme returns a bs_theme object", {
  skip_if_not_installed("bslib")
  theme <- glass_theme()
  expect_s3_class(theme, "bs_theme")
})

test_that("glass_theme supports light and dark presets", {
  skip_if_not_installed("bslib")
  light <- glass_theme(preset = "light")
  dark <- glass_theme(preset = "dark")
  expect_s3_class(light, "bs_theme")
  expect_s3_class(dark, "bs_theme")
  expect_false(identical(light, dark))
})

test_that("glass_theme compiles dependencies", {
  skip_if_not_installed("bslib")
  theme <- glass_theme()
  deps <- bslib::bs_theme_dependencies(theme)
  expect_true(length(deps) >= 1)
  dep_names <- vapply(deps, function(d) d$name, character(1))
  expect_true("shinyglass" %in% dep_names)
  expect_true("shinyglass-preset" %in% dep_names)
})

test_that("glass_theme sets preset data attribute in head", {
  skip_if_not_installed("bslib")
  dark <- glass_theme(preset = "dark")
  deps <- bslib::bs_theme_dependencies(dark)
  preset_deps <- deps[vapply(deps, function(d) d$name, character(1)) == "shinyglass-preset"]
  expect_length(preset_deps, 1)
  expect_match(preset_deps[[1]]$head, 'glassPreset="dark"')
})

test_that("compiled CSS reserves main space for open sidebars", {
  skip_if_not_installed("bslib")
  theme <- glass_theme()
  deps <- bslib::bs_theme_dependencies(theme)
  css_chunks <- character()
  for (d in deps) {
    src <- d$src$file %||% d$src
    sheets <- d$stylesheet
    if (is.null(sheets)) next
    for (f in if (is.list(sheets)) unlist(sheets) else sheets) {
      path <- file.path(src, f)
      if (file.exists(path)) {
        css_chunks <- c(css_chunks, paste(readLines(path, warn = FALSE), collapse = "\n"))
      }
    }
  }
  css <- paste(css_chunks, collapse = "\n")
  expect_match(css, "glass-sidebar-reserve")
  expect_match(css, "position:absolute\\s*!important")
  expect_match(css, "width:var\\(--_sidebar-width")
  # Nested layouts opt out of absolute float
  expect_match(css, "\\.bslib-sidebar-layout \\.bslib-sidebar-layout")
  expect_match(css, "position:relative\\s*!important")
})
