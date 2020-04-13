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
#'   default field values specified as `gallery$defaults` are also applied. The
#'   metadata in `$gallery$meta` also include an additional field `page_name`
#'   containing the names of the metadata list itself, serving as names for the
#'   HTML pages that will be generated.
#'
#' @export
gallery_site_config <- function(input = ".") {
  config <- rmarkdown::site_config(input)
  if (!is.null(config$gallery)) {
    meta_dir <- config$gallery$meta_dir %||% "meta"
    single_meta <- config$gallery$single_meta %||% FALSE
    meta_files <- site_meta_files(file.path(input, meta_dir))
    meta <- read_meta(meta_files, single_meta)
    meta <- with_name_field(meta, "page_name")
    meta <- with_type_template(meta, config$gallery)
    meta <- with_defaults(meta, config$gallery)
    meta <- sort_meta(meta, config$gallery$order_by %||% "page_name")
    check_missing_template(meta)
    config$gallery$meta <- meta
    config$gallery <- with_includes(config$gallery, input)
  }
  config
}

with_type_template <- function(meta, gallery_config) {
  if (!is.null(gallery_config$type_field)) {
    meta <- assign_type_template(
      meta,
      gallery_config$type_field,
      gallery_config$type_template
    )
  }
  meta
}

assign_type_template <- function(meta, type_field, type_templates) {
  template <- get_meta_field(meta, "template")
  type <- get_meta_field(meta, type_field)
  with_type <- is.na(template) & !is.na(type)
  template_from_type <- get_type_template(type[with_type], type_templates)
  miss_template <- is.na(template_from_type)
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

with_includes <- function(gallery_config, path = ".") {
  includes <- intersect(
    c("include_before", "include_after"),
    names(gallery_config)
  )
  gallery_config[includes] <- lapply(
    gallery_config[includes], function(include) {
      include_file <- file.path(path, include)
      if (!file.exists(include_file)) {
        .Deprecated(msg = paste(
          "Inline definition of `include_before` and `include_after` is deprecated.",
          "They should define the path to a file with the content to be included."
        ))
        include
      } else {
        paste(readLines(include_file), collapse = "\n")
      }
    }
  )
  gallery_config
}

navbar_menu_entry <- function(meta) {
  entry <- meta$menu_entry
  if (!is.list(entry)) {
    entry <- list()
    entry$text = meta$menu_entry
    entry$icon = meta$menu_icon
  }
  if (length(entry) > 0L) {
    stopifnot(length(meta$page_name) == 1L)
    entry$href <- file_with_ext(meta$page_name, "html")
    entry
  } else {
    NULL
  }
}

gallery_navbar_menu <- function(meta) {
  gallery_entries <- lapply(meta, navbar_menu_entry)
  names(gallery_entries) <- NULL
  has_entry <- sapply(gallery_entries, length) != 0L
  gallery_entries <- gallery_entries[has_entry]
  gallery_keys <- vapply(gallery_entries, FUN.VALUE = "", function(x) {
    paste(c(x$icon, x$text), collapse = " ")
  })
  duplicated <- duplicated(gallery_keys)
  if (any(duplicated)) {
    stop(
      "Found duplicate navbar menu entries: ",
      toQuotedString(gallery_keys[duplicated]))
  }
  gallery_entries
}

navbar_with_gallery <- function(config) {
  gallery_navbar <- config$gallery$navbar
  navbar <- config$navbar
  if (!is.null(gallery_navbar)) {
    # must have one element, which is the location, e.g. $left
    stopifnot(length(gallery_navbar) == 1L)
    gallery_navbar[[1L]][[1L]]$menu <- gallery_navbar_menu(config$gallery$meta)
    # add to the user-defined navbar from the main site configuration
    navbar[[names(gallery_navbar)]] <- c(
      navbar[[names(gallery_navbar)]],
      gallery_navbar[[1]]
    )
  }
  navbar
}
