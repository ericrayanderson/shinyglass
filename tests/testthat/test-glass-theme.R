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
})