
site_meta_files <- function(path) {
  list.files(path, "[.](json|ya?ml)$", full.names = TRUE)
}

read_meta_file <- function(file, ...) {
  ext <- tools::file_ext(basename(file))
  reader <- list(
    json = jsonlite::read_json,
    yaml = yaml::read_yaml,
    yml = yaml::read_yaml
  )[[ext]]
  if (is.null(ext)) {
    stop("Extension .", ext, " not supported.")
  }
  reader(file, ...)
}

read_meta <- function(files, single = FALSE) {
  meta <- do.call(
    c,
    lapply(files, function(file) {
      meta <- read_meta_file(file)
      if (isTRUE(single)) {
        meta <- list(meta)
        names(meta) <- tools::file_path_sans_ext(basename(file))
      }
      meta <- lapply(meta, c, list(.meta_file = basename(file)))
      meta
    })
  )
  dup_meta <- duplicated(names(meta))
  if (any(dup_meta)) {
    stop(
      "Duplicated page names found in the metadata: ",
      toQuotedString(unique(names(meta)[dup_meta]))
    )
  }
  meta
}

get_meta_field <- function(meta, field, missing_value = NA_character_) {
  vapply(
    meta, FUN.VALUE = missing_value,
    function(x) x[[field]] %||% missing_value
  )
}

set_meta_field <- function(meta, field, value) {
  Map(
    function(x, value) {
      x[[field]] <- if (!is.na(value)) value
      x
    },
    meta, value
  )
}

with_name_field <- function(meta, name_field) {
  name_values <- get_meta_field(meta, name_field)
  # the specified field should not exist
  if (any(!is.na(name_values))) {
    stop(
      "Field ", toQuotedString(name_field), " cannot be used",
      " for storing the matadata names since it is already in use.")
  }
  set_meta_field(meta, name_field, names(meta))
}
