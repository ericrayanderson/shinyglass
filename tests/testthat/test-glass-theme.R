test_that("glass_theme returns a bs_theme object", {
  skip_if_not_installed("bslib")
  theme <- glass_theme()
  expect_s3_class(theme, "bs_theme")
})

test_that("glass_theme supports light, dark, and auto presets", {
  skip_if_not_installed("bslib")
  light <- glass_theme(preset = "light")
  dark <- glass_theme(preset = "dark")
  auto <- glass_theme(preset = "auto")
  expect_s3_class(light, "bs_theme")
  expect_s3_class(dark, "bs_theme")
  expect_s3_class(auto, "bs_theme")
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

test_that("glass_theme sets preset data attributes in head", {
  skip_if_not_installed("bslib")
  dark <- glass_theme(preset = "dark", tint = FALSE, specular = FALSE, nav_morph = FALSE)
  deps <- bslib::bs_theme_dependencies(dark)
  preset_deps <- deps[vapply(deps, function(d) d$name, character(1)) == "shinyglass-preset"]
  expect_length(preset_deps, 1)
  head <- preset_deps[[1]]$head
  expect_match(head, 'var p="dark"')
  expect_match(head, "dataset\\.glassMode")
  expect_match(head, "dataset\\.glassPreset")
  expect_match(head, 'glassTint="false"')
  expect_match(head, 'glassSpecular="false"')
  expect_match(head, 'glassNavMorph="false"')
})

test_that("glass_theme auto preset is marked in head", {
  skip_if_not_installed("bslib")
  auto <- glass_theme(preset = "auto")
  deps <- bslib::bs_theme_dependencies(auto)
  preset_deps <- deps[vapply(deps, function(d) d$name, character(1)) == "shinyglass-preset"]
  expect_length(preset_deps, 1)
  expect_match(preset_deps[[1]]$head, 'var p="auto"')
})
test_that("compiled CSS ships dual light/dark variable packs", {
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
  expect_match(css, "data-glass-preset")
  expect_match(css, "--glass-page-bg")
  expect_match(css, "--glass-body-color")
  # Both packs present
  expect_true(grepl("data-glass-preset=\"light\"", css, fixed = TRUE) ||
    grepl("data-glass-preset=.light", css))
  expect_true(grepl("data-glass-preset=\"dark\"", css, fixed = TRUE) ||
    grepl("data-glass-preset=.dark", css))
  # Runtime page background
  expect_match(css, "var\\(--glass-page-bg\\)")
  # Layout contract from 0.1.1
  expect_match(css, "glass-sidebar-reserve")
  expect_match(css, "position:absolute\\s*!important")
  expect_match(css, "width:var\\(--_sidebar-width")
  expect_match(css, "\\.bslib-sidebar-layout \\.bslib-sidebar-layout")
  expect_match(css, "position:relative\\s*!important")
  expect_match(css, "main-sidebar")
  expect_match(css, "small-box")
  # White checkmark on checked checkboxes (not body-color / black stroke)
  expect_match(css, "form-check-input")
  expect_match(css, "stroke='%23fff'|stroke=\"%23fff\"|stroke='%23FFF'")
})

test_that("active-on-primary ink is light, not color-contrast black", {
  skip_if_not_installed("bslib")
  # Bootstrap color-contrast(#007AFF) is black; glass_theme must override.
  th <- glass_theme(primary = "#007AFF")
  vars <- bslib::bs_get_variables(
    th,
    c(
      "component-active-color",
      "form-check-input-checked-color",
      "form-check-input-indeterminate-color",
      "form-switch-checked-color",
      "pagination-active-color",
      "component-active-bg"
    )
  )
  expect_equal(toupper(vars[["component-active-color"]]), "#FFFFFF")
  expect_equal(toupper(vars[["form-check-input-checked-color"]]), "#FFFFFF")
  expect_equal(toupper(vars[["form-check-input-indeterminate-color"]]), "#FFFFFF")
  expect_equal(toupper(vars[["form-switch-checked-color"]]), "#FFFFFF")
  expect_equal(toupper(vars[["pagination-active-color"]]), "#FFFFFF")
  expect_equal(toupper(vars[["component-active-bg"]]), "#007AFF")

  deps <- bslib::bs_theme_dependencies(th)
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

  # Checked / indeterminate / switch should not keep black SVG marks on primary
  # (our CSS safety net + Sass vars). Allow black only outside checked states.
  checked_black <- grepl(
    "form-check-input:checked[^}]*stroke='%23000'|form-switch[^\"]*fill='%23000'",
    css
  )
  expect_false(checked_black)
  expect_match(css, "form-switch")
  expect_match(css, "indeterminate")
})

test_that("update_glass_theme sends shinyglass custom message", {
  skip_if_not_installed("shiny")
  msgs <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      msgs[[length(msgs) + 1L]] <<- list(type = type, message = message)
    }
  )
  update_glass_theme(session, preset = "dark", tint = FALSE, primary = "#AF52DE")
  expect_length(msgs, 1)
  expect_equal(msgs[[1]]$type, "shinyglass")
  expect_equal(msgs[[1]]$message$preset, "dark")
  expect_equal(msgs[[1]]$message$tint, FALSE)
  expect_equal(msgs[[1]]$message$primary, "#AF52DE")
})

test_that("update_glass_theme validates preset", {
  session <- list(sendCustomMessage = function(...) NULL)
  expect_error(update_glass_theme(session, preset = "neon"), "arg|preset")
  expect_error(update_glass_theme(NULL, preset = "dark"))
})

test_that("glass_theme_toggle returns labeled buttons", {
  skip_if_not_installed("shiny")
  ui <- glass_theme_toggle(inputId = "gt", selected = "dark")
  expect_s3_class(ui, "shiny.tag")
  html <- as.character(ui)
  expect_match(html, "gt_light")
  expect_match(html, "gt_dark")
  expect_match(html, "gt_auto")
  expect_match(html, "setPreset")
  expect_match(html, "glass-theme-toggle")
  expect_match(html, "dark")
})

test_that("head script includes primary CSS variables", {
  skip_if_not_installed("bslib")
  th <- glass_theme(primary = "#AF52DE")
  deps <- bslib::bs_theme_dependencies(th)
  preset_deps <- deps[vapply(deps, function(d) d$name, character(1)) == "shinyglass-preset"]
  expect_length(preset_deps, 1)
  head <- preset_deps[[1]]$head
  expect_match(head, "#AF52DE")
  expect_match(head, "--bs-primary")
  expect_match(head, "--bs-primary-rgb")
})

test_that("compiled CSS prefers reduced-motion and runtime primary hooks", {
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
  expect_match(css, "prefers-reduced-motion")
  expect_match(css, "--glass-accent")
  expect_match(css, "--bs-primary")
  expect_match(css, "shiny-plot-output")
  # Shiny checkboxInput markup (not only Bootstrap form-check-input)
  expect_match(css, "shiny-input-checkbox")
  expect_match(css, "glass-theme-toggle")
})
