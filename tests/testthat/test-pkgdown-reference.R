test_that("pkgdown reference lists every export", {
  yml_path <- testthat::test_path("../../_pkgdown.yml")
  skip_if_not(
    file.exists(yml_path),
    "pkgdown config is not part of the installed package"
  )
  yml <- readLines(yml_path, warn = FALSE)
  ref_start <- grep("^reference:", yml)[1]
  art_start <- grep("^articles:", yml)[1]
  expect_true(is.finite(ref_start) && is.finite(art_start) && art_start > ref_start)
  ref <- yml[ref_start:(art_start - 1L)]
  listed <- sub(
    "^\\s*-\\s*",
    "",
    grep("^\\s*-\\s*[A-Za-z]", ref, value = TRUE)
  )
  listed <- trimws(listed)
  exports <- setdiff(getNamespaceExports("shinyglass"), "shinyglass")
  missing <- setdiff(exports, listed)
  expect_identical(missing, character())
})
