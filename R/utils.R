
`%||%` <- function(x, value_if_null) {
  if (is.null(x)) value_if_null else x
}

# define a list of utilities to be made available when rendering
render_time_utils <- list(
  `%||%` = `%||%`
)
