
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

toQuotedString <- function(x) {
  toString(sQuote(x, q = FALSE))
}
