gallery_div <- function(class, content) {
  if (!is.null(content)) {
    htmltools::div(
      class = class,
      if (is.character(content)) {
        htmltools::HTML(content)
      } else {
        content
      }
    )
  }
}


#' Gallery page content
#'
#' Create the content of a gallery page based on arbitrary page content and
#' gallery configuration.
#'
#' @param ... Unnamed items defining the main content of the page.
#' @param gallery_config The gallery site configuration. Elements
#'   `$include_before` and `$include_after` (if present) are included before and
#'   after the main content. If character, their value is wrapped inside
#'   [htmltools::HTML()].
#' @param class Character vector of custom classes, added to
#'   `"gallery-container"`.
#'
#' @return
#'
#' The function constructs and returns the page content as a parent
#' [htmltools::div()] HTML tag object with class `"gallery-container"` with
#' three `div()` children.
#' - One containing `gallery_config$include_before` (if present), with class
#' `"gallery-before"`.
#' - One wrapping the main content items `...` via [htmltools::tagList()]
#' content, with class `"gallery-main"`.
#' - One containing `gallery_config$include_after` (if present), with class
#' `"gallery-after"`, and are wrapped in a parent `<div>` with class
#'
#' The returned value can be rendered as HTML using `as.character()`.
#'
#' @examples
#' gallery_content(
#'   htmltools::h2("Hello world"),
#'   "Welcome to the gallery content world",
#'   gallery_config = list(
#'     include_before = "before<hr/>",
#'     include_after = htmltools::tagList(htmltools::hr(), "after")
#'   ),
#'   class = "hello-gallery"
#' )
#'
#' @export
gallery_content <- function(..., gallery_config = NULL, class = NULL) {
  htmltools::div(
    class = paste(c("gallery-container", class), collapse = " "),
    gallery_div(
      class = "gallery-before",
      gallery_config$include_before
    ),
    gallery_div(
      class = "gallery-main",
      htmltools::tagList(...)
    ),
    gallery_div(
      class = "gallery-after",
      gallery_config$include_after
    )
  )
}


fill <- function(x, with, envir = parent.frame()) {
  y <- glue::glue_data(
    with,
    x,
    .open = "{{", .close = "}}",
    .envir = envir
  )
  class(y) <- class(x)
  y
}

fill_template <- function(meta, template, envir = parent.frame()) {
  if (length(meta$gallery_config$include_before) > 0L) {
    meta$gallery_config$include_before <-
      fill(meta$gallery_config$include_before, meta, envir)
  }
  if (length(meta$gallery_config$include_after) > 0L) {
    meta$gallery_config$include_after <-
      fill(meta$gallery_config$include_after, meta, envir)
  }
  filled <- fill(paste(template, collapse = "\n"), meta, envir)
  knit_params <- names(knitr::knit_params(filled, evaluate = FALSE))
  attr(filled, "params") <- meta[names(meta) %in% knit_params]
  filled
}

find_template <- function(template, paths = character(0)) {
  paths = c(system.file("templates", package = "rmdgallery"), paths)
  basename <- sprintf("%s.Rmd", template)
  template_file <- NULL
  for (path in paths) {
    if (file.exists(file.path(path, basename))) {
      template_file <- file.path(path, basename)
    }
  }
  if (is.null(template_file)) {
    stop("No template found for ", toQuotedString(template), " in ", toQuotedString(paths))
  }
  template_file
}

from_template <- function(meta, paths = character(0), envir = parent.frame()) {
  template <- find_template(meta$template, paths)
  fill_template(meta, readLines(template), envir)
}
