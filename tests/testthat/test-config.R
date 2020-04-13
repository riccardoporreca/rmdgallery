
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

test_that("Setting templates by type handles no type_field", {
  expect_identical(
    with_type_template(meta, list()),
    meta
  )
})

test_that("Setting defaults works", {
  defaults <- list(
    template = "def_tpl", # partly-specified field
    new = "def_new", # brand-new field
    foo = "def_def" # fully-specified field
  )
  result <- with_defaults(meta, list(defaults = defaults))
  expect_identical(
    get_meta_field(result, "template"),
    get_meta_field(meta, "template") %|NA|% defaults$template,
    info = "partly-specified field"
  )
  expect_identical(
    get_meta_field(result, "new"),
    get_meta_field(meta, "new") %|NA|% defaults$new,
    info = "brand-new field"
  )
  expect_identical(
    get_meta_field(result, "foo"),
    get_meta_field(meta, "foo"),
    info = "fully-specified field"
  )
})

test_that("navbar_menu_entry() behaves correctly", {
  # separate menu_fields
  meta_fields <- list(
    menu_entry = "txt", menu_icon = "ico", page_name = "foo"
  )
  # single field with text and icon elements
  meta_navbar <- list(
    menu_entry = list(text = "txt", icon = "ico"), page_name = "foo"
  )
  expected <- list(
    text = "txt", icon = "ico", href = "foo.html"
  )
  expect_null(navbar_menu_entry(list()))
  expect_equal(
    navbar_menu_entry(meta_fields[c("menu_entry", "page_name")]),
    expected[c("text", "href")]
  )
  expect_equal(
    navbar_menu_entry(meta_fields[c("menu_icon", "page_name")]),
    expected[c("icon", "href")]
  )
  expect_equal(
    navbar_menu_entry(meta_fields),
    expected
  )
  expect_equal(
    navbar_menu_entry(meta_navbar),
    expected
  )
})

meta <- list(
  a = list(menu_entry = "txta", menu_icon = "ico", page_name = "foo"),
  b = list(menu_entry = "txtb", menu_icon = "ico", page_name = "bar")
)

test_that("The gallery navbar menu is constructed correctly", {
  meta <- list(
    a = list(menu_entry = "txta", menu_icon = "ico", page_name = "foo"),
    b = list(menu_entry = "txtb", menu_icon = "ico", page_name = "bar")
  )
  expected <- list(
    list(text = "txta", icon = "ico", href = "foo.html"),
    list(text = "txtb", icon = "ico", href = "bar.html")
  )
  expect_equal(
    gallery_navbar_menu(meta),
    expected
  )
  # error on duplicated keys
  meta$b <- meta$a
  expect_error(
    gallery_navbar_menu(meta),
    glob2rx(paste("*duplicate*", toQuotedString("ico txta"))),
    ignore.case = TRUE
  )
})

test_that("The gallery navbar is added correctly", {
  config <- list(
    navbar = list(
      left = list(list(text = "home", href = "home.html")),
      right = list(list(text = "office", href = "office.html"))
    ),
    gallery = list(
      navbar = list(left = list(list(text = "gallery"))),
      meta = meta
    )
  )
  expected <- config$navbar
  expected$left <- c(
    expected$left,
    list(list(text = "gallery", menu = gallery_navbar_menu(meta)))
  )
  expect_equal(
    navbar_with_gallery(config),
    expected
  )

  # no gallery$navbar
  expect_equal(
    navbar_with_gallery(config["navbar"]),
    config$navbar
  )
  # only gallery$navbar
  expect_equal(
    navbar_with_gallery(config["gallery"]),
    list(left = expected$left[2])
  )
  # no gallery$navbar
  expect_null(
    navbar_with_gallery(list(dummy = "dummy"))
  )
})
