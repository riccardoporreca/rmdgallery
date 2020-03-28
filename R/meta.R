
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
      meta <- lapply(meta, function(x) {
        x$source <- basename(file)
        x
      })
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
