
`%||%` <- function(x, value_if_null) {
  if (is.null(x)) value_if_null else x
}

`%|NA|%` <- function(x, value_if_na) {
  x[is.na(x)] <- value_if_na
  x
}

# define a list of utilities to be made available when rendering
render_time_utils <- list(
  `%||%` = `%||%`
)

# environment with render-time utilities, including site_path()
render_time_env <- function(input, parent = parent.frame()) {
  env <- list2env(render_time_utils, parent = parent)
  env$site_path <- function(...) file.path(input, ...)
  env
}


toQuotedString <- function(x) {
  toString(sQuote(x, q = FALSE))
}
