meta_ext <- c(".json", ".yml", ".yaml")
meta_writer <- list(
  .json = function(...) jsonlite::write_json(..., auto_unbox = TRUE),
  .yml = yaml::write_yaml,
  .yaml = yaml::write_yaml
)

.write_meta <- function(meta, file) {
  ext <- sprintf(".%s", tools::file_ext(file))
  meta_writer[[ext]](meta, file)
  file
}

test_that("Metadata files with supported extensions are detected", {
  meta_dir <- tempfile("meta")
  dir.create(meta_dir)
  meta_files <- tempfile(tmpdir = meta_dir, fileext = meta_ext)
  other_files <- tempfile(tmpdir = meta_dir, fileext = c(".foo", ".bar", ""))
  file.create(c(meta_files, other_files))
  message(site_meta_files(meta_dir))
  testthat::expect_setequal(
    site_meta_files(meta_dir),
    meta_files
  )
  unlink(meta_dir, recursive = TRUE)
})

# include some characters requiring escaping
meta <- list(
  "f\"o'o" = 'foo "bar" \n \\foo\\ \'bar\'',
  bar = list(
    barfoo = "bar foo",
    foobar = "foo bar"
  )
)

test_that("Metadata files with supported extensions are read correctly", {
  mapply(
    function(ext) {
      file <- .write_meta(meta, tempfile(fileext = ext))
      expect_identical(
        read_meta_file(file),
        meta,
        info = ext
      )
      unlink(file)
    },
    meta_ext
  )
})

test_that("Metadata are correctly extracted from metadata files", {
  meta_1 <- list(a = meta, b = meta)
  meta_2 <- list(c = meta, d = meta)
  file_1 <- .write_meta(meta_1, file.path(tempdir(), "meta.json"))
  file_2 <- .write_meta(meta_2, file.path(tempdir(), "meta.yml"))
  all_meta <- read_meta(c(file_1, file_2))
  # include tha file path as "source"
  expected <- c(
    lapply(meta_1, c, list(source = "meta.json")),
    lapply(meta_2, c, list(source = "meta.yml"))
  )
  expect_identical(all_meta, expected)
})

test_that("Metadata are correctly extracted from single_meta files", {
  meta_1 <- meta
  meta_2 <- meta
  file_1 <- .write_meta(meta_1, file.path(tempdir(), "meta_1.json"))
  file_2 <- .write_meta(meta_2, file.path(tempdir(), "meta_2.yml"))
  all_meta <- read_meta(c(file_1, file_2), single = TRUE)
  # include tha file path as "source"
  expected <- list(
    meta_1 = c(meta_1, list(source = "meta_1.json")),
    meta_2 = c(meta_2, list(source = "meta_2.yml"))
  )
  expect_identical(all_meta, expected)
})

test_that("Duplicated names are detected across different files", {
  meta_1 <- list(a = meta, b = meta, c = meta)
  meta_2 <- list(d = meta, b = meta, a = meta)
  file_1 <- .write_meta(meta_1, file.path(tempdir(), "meta.json"))
  file_2 <- .write_meta(meta_2, file.path(tempdir(), "meta.yml"))
  expect_error(
    read_meta(c(file_1, file_2)),
    paste("duplicate", toQuotedString(c("b", "a")), sep = ".*"), ignore.case = TRUE
  )
})

test_that("Duplicated names are detected across single_meta files", {
  meta_1 <- meta
  meta_2 <- meta
  file_1 <- .write_meta(meta_1, file.path(tempdir(), "meta.json"))
  file_2 <- .write_meta(meta_2, file.path(tempdir(), "meta.yml"))
  expect_error(
    read_meta(c(file_1, file_2), single = TRUE),
    paste("duplicate", toQuotedString("meta"), sep = ".*"), ignore.case = TRUE
  )
})
