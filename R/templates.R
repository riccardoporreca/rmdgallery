read_meta <- function(file) {
  jsonlite::read_json(file)
}

fill_template <- function(meta, template) {
  glue::glue_data(
    meta,
    paste(template, collapse = "\n"),
    .open = "{{", .close = "}}"
  )
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
    stop("No template found for ", sQuote(template), " in ", toString(sQuote(paths)))
  }
  template_file
}

from_template <- function(meta, paths = character(0)) {
  template <- find_template(meta$template, paths)
  fill_template(meta, readLines(template))

}
