#' Gallery site configuration
#'
#' Site configuration for the [gallery_site()] generator.
#'
#' @inheritParams rmarkdown::site_config
#'
#' @return The function returns the contents of `_site.yml` as an \R list, with
#'   an additional element `$gallery$meta`, a list containing the metadata of
#'   the pages to be generated, as read from the `.json`, `.yml` and `yaml`
#'   files, where `$gallery$type_field` and `gallery$type_template` (if present)
#'   have been already used to lookup the actual `template`. In addition,
#'   default field values specified as `gallery$defaults` are also applied.
#'
#' @export
gallery_site_config <- function(input = ".") {
  config <- rmarkdown::site_config(input)
  if (!is.null(config$gallery)) {
    meta_dir <- config$gallery$meta_dir %||% "meta"
    single_meta <- config$gallery$single_meta %||% FALSE
    meta_files <- site_meta_files(file.path(input, meta_dir))
    meta <- read_meta(meta_files, single_meta)
    meta <- with_type_template(meta, config$gallery)
    meta <- with_defaults(meta, config$gallery)
    check_missing_template(meta)
    config$gallery$meta <- meta
  }
  config
}

with_type_template <- function(meta, gallery_config)(
  if (!is.null(gallery_config$type_field)) {
    meta <- assign_type_template(
      meta,
      gallery_config$type_field,
      gallery_config$type_template
    )
  }
)

assign_type_template <- function(meta, type_field, type_templates) {
  template <- get_meta_field(meta, "template")
  type <- get_meta_field(meta, type_field)
  with_type <- is.na(template) & !is.na(type)
  template_from_type <- get_type_template(type[with_type], type_templates)
  miss_template <- is.na(template_from_type )
  if (any(miss_template)) {
    stop(
      "Missing template specification for custom type(s) ",
      toQuotedString(unique(type[with_type][miss_template]))
    )
  }
  meta[with_type] <- set_meta_field(
    meta[with_type],
    "template", template_from_type
  )
  meta
}

get_type_template <- function(type, type_templates) {
  vapply(
    type, FUN.VALUE = NA_character_,
    function(x) type_templates[[x]] %||% NA_character_
  )
}

with_defaults <- function(meta, gallery_config) {
  default_fields <- names(gallery_config$defaults)
  for (field in default_fields) {
    values <- get_meta_field(meta, field)
    values <- values %|NA|% gallery_config$defaults[[field]]
    meta <- set_meta_field(meta, field, values)
  }
  meta
}

check_missing_template <- function(meta) {
  miss_template <- is.na(get_meta_field(meta, "template"))
  if (any(miss_template)) {
    stop(
      "Missing template specification for: ",
      toQuotedString(names(meta)[miss_template])
    )
  }
  invisible(meta)
}

