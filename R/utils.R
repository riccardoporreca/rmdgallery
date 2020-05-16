
`%||%` <- function(x, value_if_null) {
  if (is.null(x)) value_if_null else x
}

`%|NA|%` <- function(x, value_if_na) {
  x[is.na(x)] <- value_if_na
  x
}

# list of utilities to be made available when filling templates / rendering
fill_render_utils <- list(
  `%||%` = `%||%`
)

# environment with fill- / render-time utilities, including `site_path()` for
# constructing paths relative to side_dir
fill_render_env <- function(site_dir, parent = parent.frame()) {
  env <- list2env(fill_render_utils, parent = parent)
  env$site_path <- function(...) file.path(site_dir, ...)
  env
}


toQuotedString <- function(x) {
  toString(sQuote(x, q = FALSE))
}
