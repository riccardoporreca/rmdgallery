
site_meta_files <- function(path) {
  list.files(path, "[.]json$", full.names = TRUE)
}

read_meta <- function(files, single = FALSE) {
  do.call(
    c,
    lapply(files, function(file) {
      meta <- jsonlite::read_json(file)
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
}
