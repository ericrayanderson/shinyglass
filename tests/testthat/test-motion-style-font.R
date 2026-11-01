.preset_head <- function(th) {
  deps <- bslib::bs_theme_dependencies(th)
  deps[[which(vapply(deps, function(d) d$name == "shinyglass-preset", logical(1)))]]$head
}

.dep_names <- function(th) {
  vapply(bslib::bs_theme_dependencies(th), function(d) d$name, character(1))
}

test_that("pointer specular and nav pill flags reach the head script", {
  head <- .preset_head(glass_theme())
  expect_match(head, 'glassPointerSpecular="true"', fixed = TRUE)
  expect_match(head, 'glassNavPill="true"', fixed = TRUE)
  head <- .preset_head(glass_theme(pointer_specular = FALSE, nav_pill = FALSE))
  expect_match(head, 'glassPointerSpecular="false"', fixed = TRUE)
  expect_match(head, 'glassNavPill="false"', fixed = TRUE)
  expect_error(glass_theme(pointer_specular = NA))
  expect_error(glass_theme(nav_pill = "yes"))
})

test_that("motion = FALSE turns every motion effect off", {
  head <- .preset_head(glass_theme(motion = FALSE))
  for (flag in c("Motion", "AmbientMotion", "Morph", "Press", "NavMorph",
                 "MinimizeTabs", "PointerSpecular", "NavPill")) {
    expect_match(head, sprintf('glass%s="false"', flag), fixed = TRUE)
  }
  expect_match(head, 'glassScrollEdge="true"', fixed = TRUE)
})

test_that("style sets the starting intensity unless intensity is given", {
  expect_match(.preset_head(glass_theme(style = "tinted")), "var intensity=1.0000;", fixed = TRUE)
  expect_match(.preset_head(glass_theme(style = "clear")), "var intensity=0.1200;", fixed = TRUE)
  expect_match(.preset_head(glass_theme()), "var intensity=0.5000;", fixed = TRUE)
  expect_match(.preset_head(glass_theme(style = "tinted", intensity = 0.7)), "var intensity=0.7000;", fixed = TRUE)
  expect_match(.preset_head(glass_theme(style = "tinted")), 'glassStyle="tinted"', fixed = TRUE)
  expect_error(glass_theme(style = "frosted"))
})

test_that("update_glass_theme sends the new options", {
  sent <- NULL
  session <- list(sendCustomMessage = function(type, message) sent <<- message)
  update_glass_theme(session, pointer_specular = FALSE, nav_pill = TRUE, style = "tinted", motion = FALSE)
  expect_false(sent$pointer_specular)
  expect_true(sent$nav_pill)
  expect_identical(sent$style, "tinted")
  expect_identical(sent$intensity, 1)
  expect_false(sent$motion)
  expect_error(update_glass_theme(session, style = "x"))
})

test_that("bundled Inter is a local dependency by default", {
  expect_true("shinyglass-inter" %in% .dep_names(glass_theme()))
  expect_false("shinyglass-inter" %in% .dep_names(glass_theme(font = "system")))
  dir <- system.file("fonts", "inter", package = "shinyglass")
  expect_true(file.exists(file.path(dir, "InterVariable-latin.woff2")))
  expect_true(file.exists(file.path(dir, "OFL.txt")))
  css <- paste(readLines(file.path(dir, "shinyglass-inter.css")), collapse = "\n")
  expect_match(css, 'url("InterVariable-latin.woff2")', fixed = TRUE)
  expect_false(grepl("https?://", css))
  expect_match(.preset_head(glass_theme()), 'glassFont="matched"', fixed = TRUE)
  expect_error(glass_theme(font = "inter"))
})
