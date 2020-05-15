testthat::test_that("render_time_env returns a working site_path()", {
  env <- render_time_env("foo")
  expect_is(env$site_path, "function")
  expect_identical(
    env$site_path("bar", "dummy"),
    file.path("foo", "bar", "dummy")
  )
})

testthat::test_that("render_time_env includes all render_time_utils", {
  env <- render_time_env("foo")
  expect_identical(
    as.list(env)[names(render_time_utils)],
    render_time_utils
  )
})

testthat::test_that("render_time_env includes the provided parent", {
  env <- render_time_env("foo", parent = list2env(list(bar = "bar")))
  expect_error(
    get("bar", envir = env, inherits = FALSE),
    "'bar' not found"
  )
  expect_identical(get("bar", envir = env), "bar")
})
