
test_that("Extracting templates by type works", {
  type <- c(a = "A", b = "C", c = "A", d = "B")
  result <- get_type_template(type, list(A = "tplA", B = "tplB"))
  expect_identical(
    result,
    c(a = "tplA", b = NA_character_,  c = "tplA", d = "tplB")
  )
  result <- get_type_template(type, NULL)
  expect_identical(
    result,
    c(a = NA_character_, b = NA_character_,  c = NA_character_, d = NA_character_)
  )
})

meta <- list(
  a = list(foo = "foo", bar = "bar", type = "typeA"),
  b = list(foo = "ofo", template = "tpl"),
  c = list(foo = "oof", bar = "bar", type = "typeB"),
  d = list(foo = "ofo")
)

test_that("Setting templates by type errors if templates are missing for certain types", {
  expect_error(
    assign_type_template(meta, "type", list(foo = "bar")),
    glob2rx(paste("*missing*type(s)", toQuotedString(c("typeA", "typeB")))),
    ignore.case = TRUE
  )
  expect_error(
    assign_type_template(meta, "type", list(typeB = "bar")),
    glob2rx(paste("*missing*type(s)", toQuotedString(c("typeA")))),
    ignore.case = TRUE
  )
})