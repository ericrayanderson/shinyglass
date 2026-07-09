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