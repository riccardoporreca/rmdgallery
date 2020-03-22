#' Site configuration for the [gallery_site()] generator.
#'
#' @inheritParams rmarkdown::site_config
#'
#' @return The function returns the contents of `_site.yml` as an \R list, with
#'   an additional element `$gallery$meta`, a list containing the metadata of
#'   the pages to be generated, as read from the `.json` file.
#'
#' @export
gallery_site_config <- function(input = ".") {
  config <- rmarkdown::site_config(input)
  if (!is.null(config$gallery)) {
    meta_dir <- config$gallery$meta_dir %||% "meta"
    single_meta <- config$gallery$single_meta %||% FALSE
    meta_files <- site_meta_files(file.path(input, meta_dir))
    config$gallery$meta <- read_meta(meta_files, single_meta)
  }
  config
}
