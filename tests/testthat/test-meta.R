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
  # include tha file path as ".meta_file"
  expected <- c(
    lapply(meta_1, c, list(.meta_file = "meta.json")),
    lapply(meta_2, c, list(.meta_file = "meta.yml"))
  )
  expect_identical(all_meta, expected)
})

test_that("Metadata are correctly extracted from single_meta files", {
  meta_1 <- meta
  meta_2 <- meta
  file_1 <- .write_meta(meta_1, file.path(tempdir(), "meta_1.json"))
  file_2 <- .write_meta(meta_2, file.path(tempdir(), "meta_2.yml"))
  all_meta <- read_meta(c(file_1, file_2), single = TRUE)
  # include tha file path as ".meta_file"
  expected <- list(
    meta_1 = c(meta_1, list(.meta_file = "meta_1.json")),
    meta_2 = c(meta_2, list(.meta_file = "meta_2.yml"))
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
    glob2rx(paste("*duplicate*metadata:", toQuotedString(c("b", "a")))),
    ignore.case = TRUE
  )
})

test_that("Duplicated names are detected across single_meta files", {
  meta_1 <- meta
  meta_2 <- meta
  file_1 <- .write_meta(meta_1, file.path(tempdir(), "meta.json"))
  file_2 <- .write_meta(meta_2, file.path(tempdir(), "meta.yml"))
  expect_error(
    read_meta(c(file_1, file_2), single = TRUE),
    glob2rx(paste("*duplicate*metadata:", toQuotedString("meta"))),
    ignore.case = TRUE
  )
})

meta <- list(
  a = list(foo = "foo", bar = "bar", dummy = "dummy"),
  b = list(foo = "ofo", dummy = "dummy"),
  c = list(foo = "oof", bar = "bar", dummy = "dummy")
)

test_that("Extracting a metadata field works", {
  expect_identical(
    get_meta_field(meta, "foo"),
    c(a = "foo", b = "ofo", c = "oof")
  )
  expect_identical(
    get_meta_field(meta, "bar"),
    c(a = "bar", b = NA_character_, c = "bar")
  )
})

test_that("Setting a metadata field works", {
  expect_identical(
    set_meta_field(meta, "bar", letters[3:1]),
    Map(`[[<-`, meta, "bar", letters[3:1])
  )
  expect_identical(
    set_meta_field(meta, "foo", c("a", NA_character_, "c")),
    Map(`[[<-`, meta, "foo", list("a", NULL, "c"))
  )
})

test_that("Get/set round-trip does not alter metadata", {
  meta <- list(
    a = list(foo = "A"),
    b = list(foo = "B"),
    c = list(bar = "C"),
    d = list(foo = "D")
  )
  expect_identical(
    set_meta_field(meta, "foo", get_meta_field(meta, "foo")),
    meta
  )
})

test_that("Metadata name field is added correctly", {
  meta <- list(
    a = list(foo = "A"), b = list(foo = "B"), c = list(foo = "C")
  )
  expected <- meta
  expected$a$name <- "a"
  expected$b$name <- "b"
  expected$c$name <- "c"
  expect_identical(
    with_name_field(meta, "name"),
    expected
  )
})

test_that("Error if the name field is already present correctly", {
  meta <- list(
    a = list(foo = "A"), b = list(foo = "B", name = "_b_"), c = list(foo = "C")
  )
  expect_error(
    with_name_field(meta, "name"),
    glob2rx(paste("*", toQuotedString("name"), "*already in use*")),
    ignore.case = TRUE
  )
})

test_that("`order_by` configuration is parsed correctly" , {
  expect_identical(
    parse_order_by(c("foo", "desc(bar)", "desc(foo(bar))", "foo(desc(bar))")),
    list(
      field = c("foo", "bar", "foo(bar)", "foo(desc(bar))"),
      decreasing = c(FALSE, TRUE, TRUE, FALSE)
    )
  )
})

test_that("Metadata are ordered correctly", {
  meta <- list(
    b = list(foo = "A", bar = "B", zoo = "A"), # 2
    d = list(foo = "B", bar = "B", zoo = "B"), # 5
    e = list(foo = "B", bar = "B", zoo = "A"), # 1
    a = list(           bar = "B", zoo = "A"), # 3
    c = list(foo = "B", bar = "B", zoo = "B")  # 4
  )
  expect_identical(
    sort_meta(meta, by = c("zoo", "desc(foo)")),
    meta[c("e", "b", "a", "c", "d")]
  )
  expect_identical(
    sort_meta(meta),
    meta[letters[1:5]]
  )
  expect_identical(
    sort_meta(meta, "dummy"),
    meta[letters[1:5]]
  )
})

