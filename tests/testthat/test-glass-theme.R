test_that("slider bounds and step reject invalid ranges", {
  for (bad in c(NA_real_, NaN, Inf, -Inf, 0, -0.1)) {
    expect_error(glass_intensity_slider(step = bad))
  }
  expect_error(glass_intensity_slider(min = -0.1))
  expect_error(glass_intensity_slider(max = 1.1))
  expect_error(glass_intensity_slider(min = Inf))
  expect_error(glass_intensity_slider(min = 0.5, max = 0.5))
  expect_error(glass_intensity_slider(min = 0.5, value = 0.2), "within")
  expect_no_error(glass_intensity_slider(min = 0.6, max = 0.9))
  explicit <- as.character(glass_intensity_slider(value = 0.7, label = NULL))
  expect_match(explicit, 'data-glass-initial-intensity="0.7"', fixed = TRUE)
  expect_match(explicit, 'aria-label="Liquid Glass intensity"', fixed = TRUE)
  expect_false(grepl("aria-valuenow", explicit, fixed = TRUE))
  expect_false(grepl("data-glass-initial-intensity", as.character(glass_intensity_slider()), fixed = TRUE))
})

test_that("ambient motion can be disabled independently", {
  th <- glass_theme(ambient_motion = FALSE)
  deps <- bslib::bs_theme_dependencies(th)
  head <- deps[[which(vapply(deps, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
  expect_match(head, 'glassAmbientMotion="false"', fixed = TRUE)
  expect_error(glass_theme(ambient_motion = NA))
})

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

test_that("glass_theme material clear is marked in head and CSS", {
  skip_if_not_installed("bslib")
  expect_warning(
    th <- glass_theme(material = "clear"),
    "deprecated"
  )
  deps <- bslib::bs_theme_dependencies(th)
  preset_deps <- deps[vapply(deps, function(d) d$name, character(1)) == "shinyglass-preset"]
  expect_length(preset_deps, 1)
  expect_match(preset_deps[[1]]$head, 'var material="clear"', fixed = TRUE)
  expect_match(preset_deps[[1]]$head, "glassMaterial=material", fixed = TRUE)

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
  expect_match(css, "data-glass-material")
  expect_match(css, "--glass-bg-content")
  expect_match(css, "--glass-rim")
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
  # Bootstrap color-contrast(#007AFF) is black at 4.5:1; glass_theme must fix.
  th <- glass_theme(primary = "#007AFF")
  vars <- bslib::bs_get_variables(
    th,
    c(
      "min-contrast-ratio",
      "component-active-color",
      "form-check-input-checked-color",
      "form-check-input-indeterminate-color",
      "form-switch-checked-color",
      "pagination-active-color",
      "component-active-bg"
    )
  )
  # Core fix: lower Bootstrap's contrast gate so color-contrast() picks white
  # on brand blues (white on #007AFF is ~4.02:1).
  expect_equal(as.numeric(vars[["min-contrast-ratio"]]), 3)
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

  # text-bg-primary must compile light ink (not color-contrast black)
  expect_true(grepl("text-bg-primary\\{[^}]*color:#fff", css))
  # Solid .bg-primary still carries glass-on ink vars; value boxes are
  # tinted glass with body ink (not white-on-solid).
  expect_match(css, "--glass-on-primary")
  expect_match(css, "bslib-value-box-color")
  expect_match(css, "bslib-value-box\\.bg-primary|bslib-value-box.bg-primary")
})

test_that("glass_on_color matches luminance threshold", {
  # Saturated blue → white ink; light gold → dark ink
  expect_equal(tolower(.glass_on_color("#007AFF")), "#ffffff")
  expect_equal(tolower(.glass_on_color("#AF52DE")), "#ffffff")
  expect_equal(tolower(.glass_on_color("#FFCC00")), "#1d1d1f")
})

test_that("head script sets glass-on-primary for solid fills", {
  skip_if_not_installed("bslib")
  th <- glass_theme(primary = "#007AFF")
  deps <- bslib::bs_theme_dependencies(th)
  preset_deps <- deps[vapply(deps, function(d) d$name, character(1)) == "shinyglass-preset"]
  expect_length(preset_deps, 1)
  head <- preset_deps[[1]]$head
  expect_match(head, "--glass-on-primary")
  expect_match(head, "#ffffff|#FFFFFF")
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
  # Dual-channel: structured shinyglass + legacy glassPreset when preset set
  expect_length(msgs, 2)
  types <- vapply(msgs, `[[`, character(1), "type")
  expect_true("shinyglass" %in% types)
  expect_true("glassPreset" %in% types)
  sg <- msgs[[which(types == "shinyglass")[[1]]]]
  expect_equal(sg$message$preset, "dark")
  expect_equal(sg$message$tint, FALSE)
  expect_equal(sg$message$primary, "#AF52DE")
  expect_equal(msgs[[which(types == "glassPreset")[[1]]]]$message, "dark")
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
  expect_match(html, "glass-theme-toggle")
  expect_match(html, "data-glass-preset-mode")
  expect_match(html, "aria-pressed=\"true\"")
  expect_match(html, "btn-primary")
  expect_match(html, "btn-secondary")
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
  expect_match(css, "--glass-body-color")
  expect_match(css, "glass-scroll-edge")
  expect_match(css, "prefers-reduced-transparency")
  expect_match(css, "glass-theme-settling")
  expect_match(css, "overflow-x:\\s*clip")
  expect_match(css, "vscomp-dropbox")
})

test_that("dark pack does not re-lock default button labels to $primary", {
  scss <- paste(readLines(system.file("scss", "glass.scss", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_false(grepl(
    "color-mix\\(in srgb, \\$primary 88%, #ffffff 12%\\)",
    scss
  ))
})

test_that("glass_resolved_preset prefers client resolved value", {
  expect_equal(glass_resolved_preset(NULL), "light")
  expect_equal(glass_resolved_preset(list(), default = "dark"), "dark")
  expect_equal(
    glass_resolved_preset(list(glass_resolved_preset = "dark", preset = "auto")),
    "dark"
  )
  expect_equal(
    glass_resolved_preset(list(preset = "dark")),
    "dark"
  )
  expect_equal(
    glass_resolved_preset(list(preset = "auto")),
    "light"
  )
})

test_that("compiled CSS styles DT/Bootstrap page-link surfaces (not li-only)", {
  skip_if_not_installed("bslib")
  # Regression guard for black DT chips: DT Bootstrap 5 uses
  # <li.paginate_button.page-item><a.page-link>. Glass must paint .page-link.
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
  expect_match(css, "dataTables_paginate")
  expect_match(css, "page-link")
  expect_match(css, "page-item\\.active|page-item.active")
  expect_match(css, "page-item\\.disabled|paginate_button\\.disabled")
  # Visible chip uses glass surface tokens
  expect_true(grepl(
    "dataTables_paginate[^}]*page-link|page-link[^}]*--glass-bg|page-link[^;]*var\\(--glass-bg\\)",
    css
  ))
})

test_that("compiled CSS covers plotly, gt, waiter, and AdminLTE-plus chrome", {
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
  expect_match(css, "js-plotly-plot")
  expect_match(css, "modebar")
  expect_match(css, "gt_table")
  expect_match(css, "gt_col_heading")
  expect_match(css, "waiter-overlay")
  expect_match(css, "swal2-popup")
  expect_match(css, "user-panel")
  expect_match(css, "handsontable")
  expect_match(css, "datepicker")
  expect_match(css, "shiny-notification")
  expect_match(css, "accordion-button")
  expect_match(css, "btn-close")
})

test_that("audit-glass-contrast harness exists in the source tree", {
  # inst/scripts is intentionally .Rbuildignore'd for CRAN (devtools-only QA).
  # Assert the harness when developing from a full git checkout.
  root <- testthat::test_path("../..")
  audit_r <- file.path(root, "inst", "scripts", "audit-glass-contrast.R")
  audit_js <- file.path(root, "inst", "scripts", "audit-glass-contrast.js")
  qa_md <- file.path(root, "inst", "scripts", "VISUAL-QA.md")
  skip_if_not(
    file.exists(audit_r) && file.exists(audit_js),
    "inst/scripts not present (CRAN tarball / installed package)"
  )
  expect_true(file.exists(qa_md))
  js <- paste(readLines(audit_js, warn = FALSE), collapse = "\n")
  expect_match(js, "runGlassAudit")
  expect_match(js, "solid-black-chip|dt-pagination-structure")
  r_src <- paste(readLines(audit_r, warn = FALSE), collapse = "\n")
  expect_match(r_src, "chrome-kitchen-sink")
  expect_match(r_src, "open-datepicker")
})


test_that("glass_theme intensity is marked in head", {
  skip_if_not_installed("bslib")
  th <- glass_theme(intensity = 0.2)
  deps <- bslib::bs_theme_dependencies(th)
  preset_deps <- deps[vapply(deps, function(d) d$name, character(1)) == "shinyglass-preset"]
  expect_length(preset_deps, 1)
  expect_match(preset_deps[[1]]$head, "var intensity=0\\.2000")
  expect_match(preset_deps[[1]]$head, "glassIntensity=String\\(intensity\\)")
  expect_match(preset_deps[[1]]$head, "--glass-intensity")
})

test_that("iOS 27 scroll-edge assets and Appearance copy ship", {
  js <- paste(readLines(system.file("js", "shiny-glass.js", package = "shinyglass"), warn = FALSE), collapse = "\n")
  scss <- paste(readLines(system.file("scss", "glass.scss", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(js, "glass-scroll-edge")
  expect_match(js, "glass-theme-settling")
  expect_match(js, "beginThemeSettle")
  expect_match(js, "bindGlassOverlayMenus")
  expect_match(js, "dropboxWrapper")
  expect_match(scss, "glass-scroll-edge")
  expect_match(scss, "glass-theme-settling")
  expect_match(scss, "overflow-x: clip")
  html <- as.character(glass_intensity_slider("gi", preview = FALSE))
  expect_match(html, "Appearance")
})

test_that("glass_intensity_slider returns a tag with range input", {
  skip_if_not_installed("htmltools")
  ui <- glass_intensity_slider("gi", value = 0.7, preview = FALSE)
  expect_s3_class(ui, "shiny.tag")
  html <- as.character(ui)
  expect_match(html, "glass-intensity-slider")
  expect_match(html, 'id="gi"')
  expect_match(html, 'value="0.7"')
  expect_match(html, "Ultra Clear")
  expect_match(html, "Tinted")
})

test_that("intensity must be in 0..1", {
  expect_error(glass_theme(intensity = 1.5), "intensity")
  expect_error(glass_theme(intensity = -0.1), "intensity")
})

test_that("update_glass_theme accepts intensity", {
  skip_if_not_installed("shiny")
  # session mock: capture sendCustomMessage
  msgs <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      msgs[[length(msgs) + 1L]] <<- list(type = type, message = message)
    }
  )
  class(session) <- "ShinySession"
  update_glass_theme(session, intensity = 0.8)
  expect_equal(length(msgs), 1L)
  expect_equal(msgs[[1]]$type, "shinyglass")
  expect_equal(msgs[[1]]$message$intensity, 0.8)
})

test_that("update_glass_theme dual-channels preset", {
  skip_if_not_installed("shiny")
  msgs <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      msgs[[length(msgs) + 1L]] <<- list(type = type, message = message)
    }
  )
  class(session) <- "ShinySession"
  update_glass_theme(session, preset = "dark")
  types <- vapply(msgs, `[[`, character(1), "type")
  expect_true("shinyglass" %in% types)
  expect_true("glassPreset" %in% types)
  sg <- msgs[[which(types == "shinyglass")[1]]]
  expect_equal(sg$message$preset, "dark")
  leg <- msgs[[which(types == "glassPreset")[1]]]
  expect_equal(leg$message, "dark")
})

test_that("glass_preset_input marks select for client binding", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("htmltools")
  ui <- glass_preset_input("my_preset", selected = "dark")
  html <- paste(as.character(ui), collapse = "\n")
  expect_match(html, "data-glass-preset-input")
  expect_match(html, "glass-preset-input")
  expect_match(html, 'id="my_preset"')
  expect_match(html, "dark")
})

test_that("persist and scene are marked in the head script", {
  skip_if_not_installed("bslib")
  th <- glass_theme(persist = TRUE, scene = "dusk")
  deps <- bslib::bs_theme_dependencies(th)
  head <- deps[[which(vapply(deps, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
  expect_match(head, "var persist=true")
  expect_match(head, 'var scene="dusk"')
  expect_match(head, "localStorage")
  expect_error(glass_theme(scene = "neon"))
})

test_that("named system colors and wallpaper validation", {
  skip_if_not_installed("bslib")
  expect_equal(unname(glass_system_colors()[["purple"]]), "#AF52DE")
  th <- glass_theme(primary = "purple")
  deps <- bslib::bs_theme_dependencies(th)
  head <- deps[[which(vapply(deps, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
  expect_match(head, "#AF52DE")
  expect_error(glass_theme(wallpaper = "javascript:alert(1)"))
  expect_error(glass_theme(wallpaper = 'https://x.com/"onclick'))
})

test_that("glass_accent_input and glass_page emit controls", {
  skip_if_not_installed("htmltools")
  skip_if_not_installed("bslib")
  skip_if_not_installed("shiny")
  wells <- as.character(glass_accent_input("accent", selected = "orange"))
  expect_match(wells, "glass-accent-well")
  expect_match(wells, "#FF9500")
  expect_match(wells, "is-selected")
  page <- as.character(glass_page(title = "Hi", controls = TRUE, persist = FALSE))
  expect_match(page, "glass-page-controls")
  expect_match(page, "glass-theme-toggle")
  expect_match(page, "glass-intensity-slider")
  expect_match(page, "glass-accent-input")
})

test_that("update_glass_theme sends material and scene", {
  skip_if_not_installed("shiny")
  msgs <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      msgs[[length(msgs) + 1L]] <<- list(type = type, message = message)
    }
  )
  class(session) <- "ShinySession"
  expect_warning(
    update_glass_theme(session, material = "clear", scene = "mesh", ambient_motion = FALSE),
    "deprecated"
  )
  sg <- msgs[[1]]$message
  expect_equal(sg$material, "clear")
  expect_equal(sg$intensity, 0.12)
  expect_equal(sg$scene, "mesh")
  expect_equal(sg$ambient_motion, FALSE)
})

test_that("glass_plot_colors and theme_glass follow preset", {
  pal <- glass_plot_colors("dark")
  expect_equal(pal$ink, "#f5f5f7")
  pal_l <- glass_plot_colors("light")
  expect_equal(pal_l$paper, "rgba(0,0,0,0)")
  pal_o <- glass_plot_colors("light", surface = "opaque")
  expect_equal(pal_o$surface, "opaque")
  expect_equal(pal_o$paper, "rgba(245,245,247,0.94)")
  pal_od <- glass_plot_colors("dark", surface = "opaque")
  expect_equal(pal_od$paper, "rgba(28,28,30,0.94)")
  skip_if_not_installed("ggplot2")
  th <- theme_glass("dark")
  expect_s3_class(th, "theme")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_glass("light")
  expect_silent(ggplot2::ggplotGrob(p))
  p_opaque <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_glass("light", surface = "opaque")
  expect_silent(ggplot2::ggplotGrob(p_opaque))
})

test_that("compiled CSS includes scenes, wells, and forced-colors", {
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
  expect_match(css, "data-glass-scene")
  expect_match(css, "aurora")
  expect_match(css, "harbor")
  expect_match(css, "grove")
  expect_match(css, "glass-wallpaper-wash")
  expect_match(css, "data-glass-flatten")
  expect_match(css, "max-width: 480px")
  expect_match(css, "glass-accent-well")
  expect_match(css, "forced-colors")
  expect_match(css, "prefers-contrast")
  expect_match(css, "--glass-stroke-side")
  expect_match(css, "glass-orb-drift")
  expect_match(css, "data-glass-plot-surface")
  expect_match(css, "glass-plot-surface-opaque")
  expect_match(css, "--glass-plot-panel")
})

test_that("plot_surface is marked in the head script", {
  skip_if_not_installed("bslib")
  th <- glass_theme(plot_surface = "opaque")
  deps <- bslib::bs_theme_dependencies(th)
  head <- deps[[which(vapply(deps, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
  expect_match(head, 'var plotSurface="opaque"', fixed = TRUE)
  expect_match(head, "glassPlotSurface=plotSurface", fixed = TRUE)
  expect_error(glass_theme(plot_surface = "frosted"))
})

test_that("update_glass_theme sends plot_surface", {
  skip_if_not_installed("shiny")
  msgs <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      msgs[[length(msgs) + 1L]] <<- list(type = type, message = message)
    }
  )
  class(session) <- "ShinySession"
  update_glass_theme(session, plot_surface = "opaque")
  expect_equal(msgs[[1]]$type, "shinyglass")
  expect_equal(msgs[[1]]$message$plot_surface, "opaque")
})

test_that("default glass_theme() scene and empty tokens do not error", {
  skip_if_not_installed("bslib")
  expect_s3_class(glass_theme(), "bs_theme")
  expect_equal(.glass_normalize_scene(.glass_scene_names()), "default")
  expect_equal(.glass_normalize_scene(c("default", "tahoe", "dusk")), "default")
  expect_equal(.glass_normalize_token_list(NULL), list())
})

test_that("named scenes include aurora harbor grove", {
  expect_true(all(c("aurora", "harbor", "grove") %in% names(glass_scenes())))
  skip_if_not_installed("bslib")
  th <- glass_theme(scene = "aurora")
  deps <- bslib::bs_theme_dependencies(th)
  head <- deps[[which(vapply(deps, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
  expect_match(head, 'var scene="aurora"', fixed = TRUE)
  expect_error(glass_theme(scene = "neon"))
  skip_if_not_installed("htmltools")
  skip_if_not_installed("shiny")
  ui <- as.character(glass_scene_input("sc", selected = "harbor"))
  expect_match(ui, "data-glass-scene-input")
  expect_match(ui, "harbor")
})

test_that("flatten is marked and update_glass_theme sends it", {
  skip_if_not_installed("bslib")
  th <- glass_theme(flatten = TRUE)
  deps <- bslib::bs_theme_dependencies(th)
  head <- deps[[which(vapply(deps, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
  expect_match(head, "var flatten=true")
  expect_match(head, "glassFlatten")
  css <- paste(readLines(system.file("scss", "glass.scss", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(css, "data-glass-flatten")
  expect_match(css, "@media print")
  expect_match(css, "glass-flatten-mode")
  js <- paste(readLines(system.file("js", "shiny-glass.js", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(js, "setFlatten")
  expect_match(js, "enterFlatten")
  expect_match(js, "glass_flatten")
  msgs <- list()
  session <- list(sendCustomMessage = function(type, message) {
    msgs[[length(msgs) + 1L]] <<- list(type = type, message = message)
  })
  class(session) <- "ShinySession"
  glass_flatten(session, TRUE)
  expect_equal(msgs[[1]]$message$flatten, TRUE)
})

test_that("public tokens catalog and overrides", {
  cat <- glass_css_tokens()
  expect_true(all(c("token", "css_var", "category", "description") %in% names(cat)))
  expect_true("--glass-blur" %in% cat$css_var)
  expect_true("--glass-wallpaper-wash" %in% cat$css_var)
  pack <- glass_token_pack("light")
  expect_equal(pack[["--glass-body-color"]], "#1d1d1f")
  dark <- glass_token_pack("dark")
  expect_equal(dark[["--glass-body-color"]], "#f5f5f7")
  expect_error(glass_add_tokens(glass_theme(), list(not_a_token = "1px")), "Unknown")
  skip_if_not_installed("bslib")
  th <- glass_theme(tokens = list(blur = "28px", radius = "1.25rem"))
  deps <- bslib::bs_theme_dependencies(th)
  token_deps <- deps[vapply(deps, function(d) d$name == "shinyglass-tokens", logical(1))]
  expect_length(token_deps, 1)
  expect_match(token_deps[[1]]$head, "--glass-blur:28px")
  expect_match(token_deps[[1]]$head, "--glass-radius:1.25rem")
  msgs <- list()
  session <- list(sendCustomMessage = function(type, message) {
    msgs[[length(msgs) + 1L]] <<- list(type = type, message = message)
  })
  update_glass_theme(session, tokens = list(blur = "40px"))
  expect_equal(msgs[[1]]$message$tokens[["--glass-blur"]], "40px")
})

test_that("plot surface input and DT options", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("htmltools")
  html <- as.character(glass_plot_surface_input("ps", selected = "opaque"))
  expect_match(html, "data-glass-plot-surface-input")
  expect_match(html, "opaque")
  opts <- dt_options_glass(page_length = 5, scroll_x = TRUE)
  expect_equal(opts$pageLength, 5)
  expect_true(opts$scrollX)
  expect_false(opts$autoWidth)
})

test_that("compiled CSS and JS ship shipping-iOS-27 edge tokens", {
  js <- paste(readLines(system.file("js", "shiny-glass.js", package = "shinyglass"), warn = FALSE), collapse = "\n")
  scss <- paste(readLines(system.file("scss", "glass.scss", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(js, "setPlotSurface")
  expect_match(js, "borderA: 0.42")
  expect_match(js, "specularA: 0.56")
  expect_match(js, "blurScale: 1.08")
  expect_match(js, "blurScale: 1.14")
  expect_match(scss, "--glass-border: rgba\\(255, 255, 255, 0.85\\)")
  expect_match(scss, "--glass-border: rgba\\(255, 255, 255, 0.55\\)")
  expect_match(scss, "--glass-specular: rgba\\(255, 255, 255, 0.95\\)")
  expect_match(scss, "--glass-specular: rgba\\(255, 255, 255, 0.69\\)")
  expect_match(scss, "--glass-specular-top: rgba\\(255, 255, 255, 0.20\\)")
  expect_match(scss, "--glass-sheen-end: 8px", fixed = TRUE)
  expect_match(scss, "--glass-fill-sheen-end: 12px", fixed = TRUE)
  expect_match(js, "highlightA: 0.16")
  expect_match(js, "--glass-sheen-end")
  expect_match(scss, "--glass-refract-brightness")
  expect_match(scss, "--glass-refract-contrast")
})

test_that("default intensity is the iOS 27 midpoint", {
  skip_if_not_installed("bslib")
  th <- glass_theme()
  deps <- bslib::bs_theme_dependencies(th)
  head <- deps[[which(vapply(deps, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
  expect_match(head, "var intensity=0.5000")
  expect_match(head, "prefers-reduced-transparency")
  expect_match(head, "prefers-contrast")
  expect_match(head, "forced-colors")
  expect_match(head, "blurScale:1.08")
  slider <- as.character(glass_intensity_slider())
  expect_match(slider, 'value="0.5"', fixed = TRUE)
  expect_equal(glass_token_pack("light")[["--glass-intensity"]], "0.5")
  expect_equal(glass_token_pack("dark")[["--glass-intensity"]], "0.5")
  expect_true("--glass-refract-a" %in% glass_css_tokens()$css_var)
  expect_true("--glass-refract-b" %in% glass_css_tokens()$css_var)
  expect_true("--glass-refract-brightness" %in% glass_css_tokens()$css_var)
  expect_true("--glass-refract-contrast" %in% glass_css_tokens()$css_var)
  js <- paste(readLines(system.file("js", "shiny-glass.js", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(js, "DEFAULT_INTENSITY = 0.5")
  react <- paste(readLines(system.file("js", "shinyglass-react.js", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(react, "GlassIntensitySlider")
  expect_match(react, "reducedTransparency")
  expect_match(react, "increasedContrast")
  expect_match(react, "forcedColors")
})

test_that("material clear warns and maps to a low intensity", {
  skip_if_not_installed("bslib")
  expect_warning(
    th <- glass_theme(material = "clear"),
    "0.12"
  )
  deps <- bslib::bs_theme_dependencies(th)
  head <- deps[[which(vapply(deps, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
  expect_match(head, "var intensity=0.1200")
  expect_match(head, 'var material="clear"', fixed = TRUE)
  expect_warning(
    kept <- glass_theme(material = "clear", intensity = 0.8),
    "deprecated"
  )
  deps_kept <- bslib::bs_theme_dependencies(kept)
  head_kept <- deps_kept[[which(vapply(deps_kept, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
  expect_match(head_kept, "var intensity=0.8000")
})

test_that("accessibility CSS beats inline glass variables", {
  scss <- paste(readLines(system.file("scss", "glass.scss", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(scss, 'data-glass-contrast="more"')
  expect_match(scss, 'data-glass-forced-colors="active"')
  expect_match(scss, 'data-glass-reduced-transparency="reduce"')
  expect_match(scss, "prefers-contrast: more")
  expect_match(scss, "forced-colors: active")
  expect_match(scss, "prefers-reduced-transparency: reduce")
  expect_match(scss, "--glass-bg: #f5f5f7 !important")
  expect_match(scss, "--glass-blur: 0px !important")
  expect_match(scss, "--glass-border: ButtonBorder !important")
  expect_match(scss, "backdrop-filter: none !important")
  js <- paste(readLines(system.file("js", "shiny-glass.js", package = "shinyglass"), warn = FALSE), collapse = "\n")
  # dataset.glassContrast writes the data-glass-contrast attribute.
  expect_match(js, "dataset.glassContrast")
  expect_match(js, "dataset.glassForcedColors")
  expect_match(js, "dataset.glassReducedTransparency")
  expect_match(js, "prefers-contrast: more")
  expect_match(js, "forced-colors: active")
  expect_match(js, "applyReducedTransparency")
  expect_match(js, "applyForcedColors")
  expect_match(js, "applyIncreasedContrast")
})

test_that("iOS 27 motion defaults are on and the floating sidebar is opt-in", {
  skip_if_not_installed("bslib")
  th <- glass_theme()
  deps <- bslib::bs_theme_dependencies(th)
  head <- deps[[which(vapply(deps, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
  expect_match(head, 'glassRefraction="true"', fixed = TRUE)
  expect_match(head, 'glassMorph="true"', fixed = TRUE)
  expect_match(head, 'glassPress="true"', fixed = TRUE)
  expect_match(head, 'glassScrollEdge="true"', fixed = TRUE)
  expect_match(head, 'glassMinimizeTabs="true"', fixed = TRUE)
  expect_match(head, 'glassIconStyle="clear"', fixed = TRUE)
  expect_match(head, 'glassFloatingSidebar="false"', fixed = TRUE)
  expect_match(head, "--glass-ior")
  js_dep <- deps[[which(vapply(deps, function(d) d$name == "shinyglass", logical(1)))]]
  expect_true(all(c("shiny-glass.js", "glass-ios27.js") %in% unlist(js_dep$script)))

  off <- glass_theme(
    refraction = FALSE,
    morph = FALSE,
    press = FALSE,
    scroll_edge = FALSE,
    minimize_tabs = FALSE,
    icon_style = "color",
    floating_sidebar = TRUE
  )
  off_deps <- bslib::bs_theme_dependencies(off)
  off_head <- off_deps[[which(vapply(off_deps, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
  expect_match(off_head, 'glassRefraction="false"', fixed = TRUE)
  expect_match(off_head, 'glassIconStyle="color"', fixed = TRUE)
  expect_match(off_head, 'glassFloatingSidebar="true"', fixed = TRUE)
  expect_error(glass_theme(icon_style = "neon"), "arg|icon")

  msgs <- list()
  session <- list(sendCustomMessage = function(type, message) {
    msgs[[length(msgs) + 1L]] <<- list(type = type, message = message)
  })
  update_glass_theme(
    session,
    refraction = FALSE,
    morph = FALSE,
    press = FALSE,
    scroll_edge = FALSE,
    minimize_tabs = FALSE,
    icon_style = "all",
    floating_sidebar = TRUE
  )
  payload <- msgs[[1]]$message
  expect_false(payload$refraction)
  expect_false(payload$morph)
  expect_false(payload$press)
  expect_false(payload$scroll_edge)
  expect_false(payload$minimize_tabs)
  expect_identical(payload$icon_style, "all")
  expect_true(payload$floating_sidebar)

  engine <- paste(readLines(system.file("js", "glass-ios27.js", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(engine, "feDisplacementMap")
  expect_match(engine, "REFRACT_CAP = 8")
  expect_match(engine, "prefers-reduced-motion")
  expect_match(engine, "prefers-reduced-transparency")
  expect_match(engine, "buildDisplacementMap")
  expect_match(engine, "isLowTierDevice")
  scss <- paste(readLines(system.file("scss", "glass.scss", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(scss, "glass-morph-indicator")
  expect_match(scss, "glass-tabs-min")
  expect_match(scss, "data-glass-icon-style")
  expect_match(scss, "data-glass-floating-sidebar")
  expect_match(scss, "glass-refract")
  expect_match(scss, "label.switch")
  expect_match(scss, "shiny-chat-input")
  expect_match(scss, ".offcanvas")
  expect_match(engine, "show.bs.offcanvas")
  expect_match(engine, "shiny-chat-messages")
  expect_match(engine, "shiny-chat-page-sidebar-toggle", fixed = TRUE)
  expect_match(engine, "glass-scroll-edge-top")
  expect_match(scss, "glass-scroll-edge-top")
  expect_match(scss, "shiny-chat-message-content")
  expect_match(scss, "rgba(255, 255, 255, 0.92)", fixed = TRUE)
  expect_match(scss, "--shiny-chat-history-bg: transparent", fixed = TRUE)
  expect_match(scss, "shiny-chat-history-item-select", fixed = TRUE)
  expect_match(scss, "shiny-chat-scroll-to-bottom")
  expect_match(scss, "shiny-chat-thinking-header")
  expect_match(scss, "--shiny-chat-btn-send-size: 32px", fixed = TRUE)
  expect_match(scss, "bslib-input-dark-mode")
  expect_match(scss, "shiny-chat-history-itemmenu")
  expect_match(scss, "--speed-fast: 0s", fixed = TRUE)
  expect_match(scss, "min-height: 32px", fixed = TRUE)
  expect_match(scss, "prefers-reduced-motion: reduce", fixed = TRUE)
  expect_match(scss, "body::before", fixed = TRUE)
  expect_match(scss, "safe-area-inset-bottom")
  expect_match(scss, "glass-overflowing")
  expect_match(scss, "--glass-specular-top")
  expect_match(scss, "--glass-edge")
  expect_match(scss, "min-height: 44px", fixed = TRUE)
  expect_match(scss, "data-glass-pointer", fixed = TRUE)
  expect_match(scss, "--glass-safe-top: 59px", fixed = TRUE)
  expect_match(scss, "--glass-safe-bottom: 34px", fixed = TRUE)
  expect_match(scss, "scrollbar-width: none !important", fixed = TRUE)
  expect_match(scss, "file-selector-button", fixed = TRUE)
  expect_match(scss, ".irs-handle, .noUi-handle)::before", fixed = TRUE)
  expect_match(scss, ".harbor-pill, .shiny-aside-pill)::before", fixed = TRUE)
  expect_match(scss, "glass-table-scrim", fixed = TRUE)
  expect_match(scss, "vscomp-dropbox-close-button", fixed = TRUE)
  expect_match(scss, "data-full-screen", fixed = TRUE)
  expect_match(scss, "data-glass-intensity", fixed = TRUE)
  expect_match(engine, "bindOverlayDismiss", fixed = TRUE)
  expect_match(engine, "drop-menu-input", fixed = TRUE)
  expect_true("--glass-ior" %in% glass_css_tokens()$css_var)
  expect_equal(glass_token_pack("light")[["--glass-ior"]], "1.5")
  expect_equal(glass_token_pack("light")[["--glass-icon-clear"]], "#1d1d1f")
  js <- paste(readLines(system.file("js", "shiny-glass.js", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(js, "bindExternalColorMode")
})

test_that("shinychat glass example builds an app", {
  skip_if_not_installed("shinychat", "0.5.0")
  skip_if_not_installed("ellmer", "0.5.0")
  skip_if_not_installed("coro")
  path <- system.file("examples/shinychat-glass", "app.R", package = "shinyglass")
  expect_true(nzchar(path))
  env <- new.env(parent = globalenv())
  sys.source(path, env)
  expect_s3_class(env$app, "shiny.appobj")

  if (!nzchar(Sys.getenv("GEMINI_API_KEY")) && !nzchar(Sys.getenv("GOOGLE_API_KEY"))) {
    expect_null(env$gemini_key())
  }
  if (!nzchar(Sys.getenv("SHINYGLASS_CHAT_MODEL"))) {
    expect_identical(env$gemini_model(), "gemini-3.5-flash-lite")
    expect_identical(
      env$gemini_model_chain(),
      c("gemini-3.5-flash-lite", "gemini-3.8-flash", "gemini-3.7-flash")
    )
  }
  expect_match(env$harbor_system_prompt(), "shinyglass")
  expect_match(env$harbor_system_prompt(), "ordinary conversation")
  expect_match(env$harbor_system_prompt(), "glass_theme()", fixed = TRUE)
  expect_match(env$harbor_system_prompt(), "glass_page()", fixed = TRUE)
  expect_match(env$harbor_system_prompt(), "glass_intensity_slider()", fixed = TRUE)
  expect_match(env$harbor_system_prompt(), "iOS 27", fixed = TRUE)
  expect_match(env$harbor_system_prompt(), "page_chat()", fixed = TRUE)
  expect_match(env$harbor_system_prompt(), "offcanvas()", fixed = TRUE)
  expect_match(env$harbor_system_prompt(), "2 to 4", fixed = TRUE)
  expect_false(grepl("search the web", env$harbor_system_prompt(), fixed = TRUE))
  expect_false(grepl("harbor guide", env$harbor_system_prompt(), fixed = TRUE))
  expect_false(grepl("glassmorphism", env$harbor_system_prompt(), fixed = TRUE))
  expect_lt(nchar(env$harbor_system_prompt()), 800)
  expect_false(grepl("google_tool_web_search", paste(deparse(env$make_client), collapse = "\n"), fixed = TRUE))

  mock <- env$gate_turn("tide", 0L, FALSE)
  expect_identical(mock$action, "mock")
  expect_identical(mock$used, 0L)
  live <- env$gate_turn("tide", 7L, TRUE)
  expect_identical(live$action, "live")
  expect_identical(live$used, 8L)
  capped <- env$gate_turn("again", 8L, TRUE)
  expect_identical(capped$action, "capped")
  expect_identical(capped$used, 8L)
  expect_match(capped$notice, "free messages")
  long <- env$gate_turn(strrep("a", 401), 0L, TRUE)
  expect_identical(long$action, "too_long")
  expect_identical(long$used, 0L)
  expect_false(grepl("aaa", long$notice))
  expect_identical(env$harbor_turn_budget(3L, 7L), 7L)
  expect_identical(env$harbor_turn_budget(7L, 3L), 7L)
  expect_identical(env$harbor_turn_budget(0L, NULL), 0L)
  expect_identical(env$harbor_turn_budget(8L, "nope"), 8L)

  secret <- "sk-TESTSECRET-do-not-leak"
  quota <- simpleError(paste("status 429 quota key=", secret))
  expect_true(env$is_quota_error(quota))
  expect_false(grepl(secret, env$api_notice(quota), fixed = TRUE))
  expect_match(env$api_notice(quota), "free-tier")
  other <- simpleError(paste("boom key=", secret))
  expect_false(env$is_quota_error(other))
  expect_false(grepl(secret, env$api_notice(other), fixed = TRUE))

  notices <- character()
  bad <- coro::gen({
    yield("Hello ")
    stop(paste("status 429 key=", secret))
  })
  guarded <- env$guarded_stream(bad, "tide line", on_fallback = function(notice) {
    notices <<- c(notices, notice)
  })
  parts <- list()
  repeat {
    piece <- guarded()
    if (coro::is_exhausted(piece)) break
    parts[[length(parts) + 1L]] <- piece
    if (length(parts) > 40L) break
  }
  flat <- paste(vapply(parts, function(x) if (is.character(x)) x else "", character(1)), collapse = "\n")
  expect_false(grepl(secret, flat, fixed = TRUE))
  expect_match(flat, "Hello ")
  expect_false(grepl("free-tier limit", flat, fixed = TRUE))
  expect_false(grepl("local note instead.glass_theme", flat, fixed = TRUE))
  expect_match(flat, "1.4 m")
  expect_match(notices[[1]], "free-tier")
  expect_false(grepl(secret, notices[[1]], fixed = TRUE))
  expect_true(any(vapply(parts, function(x) inherits(x, "shinychat_block"), logical(1))))

  chain_error <- function(status, message = NULL) {
    err <- simpleError(message %||% sprintf("HTTP %s", status))
    class(err) <- c(sprintf("httr2_http_%s", status), "error", "condition")
    err
  }
  statuses <- c(503L, 429L, 404L)
  seen <- list()
  step <- 0L
  failed <- env$walk_model_chain(
    c("gemini-3.5-flash-lite", "gemini-3.8-flash", "gemini-3.7-flash"),
    function(model, params) {
      step <<- step + 1L
      seen[[length(seen) + 1L]] <<- list(model = model, plain = is.null(params))
      chain_error(statuses[[step]])
    }
  )
  expect_false(failed$ok)
  expect_match(failed$notice, "local note")
  expect_false(grepl("free-tier", failed$notice, fixed = TRUE))
  expect_identical(
    vapply(seen, function(item) item$model, character(1)),
    c("gemini-3.5-flash-lite", "gemini-3.8-flash", "gemini-3.7-flash")
  )

  step <- 0L
  recovered <- env$walk_model_chain(
    c("gemini-3.5-flash-lite", "gemini-3.8-flash", "gemini-3.7-flash"),
    function(model, params) {
      step <<- step + 1L
      if (step == 1L) return(chain_error(503L, "high demand"))
      if (step == 2L) return(chain_error(429L, "quota"))
      list(ok = TRUE)
    }
  )
  expect_true(recovered$ok)
  expect_identical(recovered$model, "gemini-3.7-flash")
  expect_null(recovered$notice)

  step <- 0L
  thought <- env$walk_model_chain(
    "gemini-3.5-flash-lite",
    function(model, params) {
      step <<- step + 1L
      if (!is.null(params)) return(chain_error(400L, "thinking level is not supported"))
      list(ok = TRUE)
    }
  )
  expect_true(thought$ok)
  expect_false(thought$thinking)
  expect_identical(step, 2L)

  live_html <- as.character(env$harbor_status_ui("live"))
  demo_html <- as.character(env$harbor_status_ui("demo"))
  ready_html <- as.character(env$harbor_status_ui("ready"))
  expect_match(live_html, "data-mode=\"live\"", fixed = TRUE)
  expect_match(live_html, "Live (Gemini)", fixed = TRUE)
  expect_match(demo_html, "data-mode=\"demo\"", fixed = TRUE)
  expect_match(demo_html, "Demo replies", fixed = TRUE)
  expect_match(ready_html, "data-mode=\"ready\"", fixed = TRUE)
  expect_false(grepl("Demo replies", ready_html, fixed = TRUE))

  glued <- env$reply_pieces(
    env$scripted_reply("How does glass_theme work?"),
    "The live model could not answer just now. Here is the local note instead."
  )
  glued_flat <- paste(vapply(glued, function(x) paste(as.character(x), collapse = ""), character(1)), collapse = "\n")
  expect_false(grepl("local note", glued_flat, fixed = TRUE))
  expect_match(glued_flat, "glass_theme")
  expect_match(glued_flat, "harbor-pill", fixed = TRUE)
  expect_match(glued_flat, "<svg", fixed = TRUE)
  expect_false(grepl("duckduckgo", glued_flat, fixed = TRUE))
  expect_false(grepl("shiny-aside", glued_flat, fixed = TRUE))

  pill <- as.character(env$source_pills_html(env$docs_citations()[1]))
  expect_match(pill, "harbor-pill-icon", fixed = TRUE)
  expect_match(pill, "github.io/shinyglass", fixed = TRUE)

  legacy <- env$migrate_stored_transcript(list(
    v = 1L,
    messages = list(list(
      role = "assistant",
      text = paste0(
        "The live model could not answer just now. Here is the local note instead.",
        "glass_theme() builds a Liquid Glass bslib theme. shinyglass docs +5"
      ),
      thinking = "Looking through the theme API."
    )),
    citations = list(list(
      title = "shinyglass docs",
      url = "https://ericrayanderson.github.io/shinyglass/",
      note = "Theme"
    )),
    notice = ""
  ))
  expect_identical(legacy$v, 3L)
  expect_match(legacy$notice, "local note", fixed = TRUE)
  expect_false(grepl("local note", legacy$messages[[1L]]$text, fixed = TRUE))
  expect_false(grepl("+5", legacy$messages[[1L]]$text, fixed = TRUE))
  expect_false(grepl("duckduckgo", legacy$messages[[1L]]$text, fixed = TRUE))
  expect_match(legacy$messages[[1L]]$text, "glass_theme")
  expect_identical(legacy$messages[[1L]]$thinking, "Looking through the theme API.")
  expect_true(any(vapply(
    legacy$messages[[1L]]$citations,
    function(item) grepl("github.io/shinyglass", item$url, fixed = TRUE),
    logical(1)
  )))

  dirty <- env$migrate_stored_transcript(list(
    messages = list(list(
      role = "assistant",
      text = paste(
        "Answer <shiny-aside label=\"shinyglass docs\" url=\"https://ericrayanderson.github.io/shinyglass/\">docs</shiny-aside>",
        "<img src=\"https://icons.duckduckgo.com/ip3/ericrayanderson.github.io.ico\">"
      )
    ))
  ))
  expect_false(grepl("duckduckgo", dirty$messages[[1L]]$text, fixed = TRUE))
  expect_false(grepl("shiny-aside", dirty$messages[[1L]]$text, fixed = TRUE))
  expect_match(dirty$messages[[1L]]$text, "Answer", fixed = TRUE)
  expect_true(any(vapply(
    dirty$messages[[1L]]$citations,
    function(item) grepl("github.io/shinyglass", item$url, fixed = TRUE),
    logical(1)
  )))

  expect_false(env$harbor_fallback_requested(""))
  expect_true(env$harbor_fallback_requested("?harbor_fallback=1"))
  expect_true(env$harbor_fallback_requested("?x=1&harbor_fallback=1"))
  expect_false(env$harbor_fallback_requested("?harbor_fallback=0"))
  old_force <- Sys.getenv("SHINYGLASS_CHAT_FORCE_FALLBACK", unset = NA_character_)
  on.exit({
    if (is.na(old_force)) {
      Sys.unsetenv("SHINYGLASS_CHAT_FORCE_FALLBACK")
    } else {
      Sys.setenv(SHINYGLASS_CHAT_FORCE_FALLBACK = old_force)
    }
  }, add = TRUE)
  Sys.setenv(SHINYGLASS_CHAT_FORCE_FALLBACK = "1")
  expect_true(env$harbor_fallback_requested(""))
  Sys.unsetenv("SHINYGLASS_CHAT_FORCE_FALLBACK")
  expect_false(env$harbor_fallback_requested(""))

  restored <- env$normalize_restore(list(
    role = c("user", "assistant"),
    text = c("Hi", "glass_theme() builds a theme."),
    thinking = c("", "Looking through the theme API.")
  ))
  expect_identical(restored[[2L]]$thinking, "Looking through the theme API.")
  expect_false(grepl("Looking through", restored[[2L]]$text, fixed = TRUE))

  theme <- env$scripted_reply("How does glass_theme work?")
  expect_false(grepl("You asked", theme$body, fixed = TRUE))
  expect_match(theme$body, "glass_theme")
  expect_true(length(theme$citations) >= 1L)
  tide <- env$scripted_reply("What's the tide at dawn?")
  expect_false(grepl("You asked", tide$body, fixed = TRUE))
  expect_false(grepl("?.", tide$body, fixed = TRUE))
  expect_length(tide$citations, 0L)
  expect_match(tide$body, "1.4 m")

  glass_cites <- env$curated_citations("How does glass_theme work?")
  glass_urls <- vapply(glass_cites, function(item) item$url, character(1))
  expect_true(any(grepl("github.io/shinyglass", glass_urls, fixed = TRUE)))
  expect_true(any(grepl("human-interface-guidelines", glass_urls, fixed = TRUE)))
  expect_true(any(grepl("shiny.posit.co", glass_urls, fixed = TRUE)))
  expect_false(any(grepl("shinychat", glass_urls, fixed = TRUE)))

  chat_cites <- env$curated_citations("Style a Shiny chat")
  chat_urls <- vapply(chat_cites, function(item) item$url, character(1))
  expect_true(any(grepl("shinychat", chat_urls, fixed = TRUE)))
  expect_true(any(grepl("shiny.posit.co", chat_urls, fixed = TRUE)))
  expect_false(any(grepl("human-interface-guidelines", chat_urls, fixed = TRUE)))

  expect_length(env$curated_citations("What's the tide at dawn?"), 0L)
  expect_length(env$curated_citations("Hello there"), 0L)

  icon <- env$harbor_icon_src()
  expect_true(startsWith(icon, "data:image/svg+xml;base64,PHN2Zy"))
  # Base64 fragment of stop-color="#007AFF", so the check does not need jsonlite.
  expect_true(grepl("IiMwMDdBRkY", icon, fixed = TRUE))

  old_mock <- Sys.getenv("SHINYGLASS_CHAT_MOCK_LIVE", unset = NA_character_)
  on.exit({
    if (is.na(old_mock)) {
      Sys.unsetenv("SHINYGLASS_CHAT_MOCK_LIVE")
    } else {
      Sys.setenv(SHINYGLASS_CHAT_MOCK_LIVE = old_mock)
    }
  }, add = TRUE)
  Sys.setenv(SHINYGLASS_CHAT_MOCK_LIVE = "1")
  built <- env$make_client()
  expect_true(built$live)
  gen <- built$client$stream_async("How does glass_theme work?", stream = "content")
  first <- gen()
  second <- gen()
  expect_true(inherits(first, "ellmer::ContentThinking"))
  expect_match(first@thinking, "theme API")
  expect_true(inherits(second, "ellmer::ContentText"))
  expect_true(coro::is_exhausted(gen()))
  flash <- env$gemini_params("gemini-3.7-flash")
  expect_identical(flash$reasoning_effort, "low")
  lite <- env$gemini_params("gemini-3.5-flash-lite")
  expect_identical(lite$reasoning_effort, "low")
  expect_null(lite$reasoning_tokens)
  older_lite <- env$gemini_params("gemini-2.5-flash-lite")
  expect_identical(older_lite$reasoning_tokens, 256L)
  older <- env$gemini_params("gemini-2.5-flash")
  expect_identical(older$reasoning_tokens, 1024L)

  old_model <- Sys.getenv("SHINYGLASS_CHAT_MODEL", unset = NA_character_)
  on.exit({
    if (is.na(old_model)) {
      Sys.unsetenv("SHINYGLASS_CHAT_MODEL")
    } else {
      Sys.setenv(SHINYGLASS_CHAT_MODEL = old_model)
    }
  }, add = TRUE)
  Sys.setenv(SHINYGLASS_CHAT_MODEL = "gemini-3.8-flash")
  expect_identical(env$gemini_model(), "gemini-3.8-flash")
  expect_identical(env$gemini_model_chain()[[1L]], "gemini-3.8-flash")
  expect_true("gemini-3.5-flash-lite" %in% env$gemini_model_chain())
})

test_that("dark value boxes, map tiles, and table headers stay readable", {
  scss <- paste(readLines(system.file("scss", "glass.scss", package = "shinyglass"), warn = FALSE), collapse = "\n")
  expect_match(scss, ".leaflet-container {", fixed = TRUE)
  expect_match(scss, "overflow: hidden !important;", fixed = TRUE)
  expect_match(scss, "body .small-box,\n  body .info-box,\n  .bslib-value-box", fixed = TRUE)
  expect_match(scss, "background: #1c1c1e !important;", fixed = TRUE)
  expect_match(scss, ".apexcharts-canvas .apexcharts-text", fixed = TRUE)
})

test_that("the contrast audit checks value-box showcase coverage", {
  # inst/scripts is Rbuildignored, so the installed package has no copy.
  js_path <- system.file("scripts", "audit-glass-contrast.js", package = "shinyglass")
  skip_if(!nzchar(js_path), "audit script is not installed")
  js <- paste(readLines(js_path, warn = FALSE), collapse = "\n")
  expect_match(js, "function glassAuditValueBoxShowcase", fixed = TRUE)
  expect_match(js, "value-box-showcase", fixed = TRUE)
  expect_match(js, "value-box-covered", fixed = TRUE)
})

test_that("compatibility example builds an app", {
  skip_if_not_installed("bslib")
  path <- system.file("examples", "compat-glass.R", package = "shinyglass")
  expect_true(nzchar(path))
  env <- new.env(parent = globalenv())
  sys.source(path, env)
  expect_s3_class(env$app, "shiny.appobj")
})
