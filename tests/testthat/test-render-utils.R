testthat::test_that("fill_render_env returns a working site_path()", {
  env <- fill_render_env("foo")
  expect_is(env$site_path, "function")
  expect_identical(
    env$site_path("bar", "dummy"),
    file.path("foo", "bar", "dummy")
  )
})

testthat::test_that("fill_render_env includes all fill_render_utils", {
  env <- fill_render_env("foo")
  expect_identical(
    as.list(env)[names(fill_render_utils)],
    fill_render_utils
  )
})

testthat::test_that("fill_render_env includes the provided parent", {
  env <- fill_render_env("foo", parent = list2env(list(bar = "bar")))
  expect_error(
    get("bar", envir = env, inherits = FALSE),
    "'bar' not found"
  )
  expect_identical(get("bar", envir = env), "bar")
})
