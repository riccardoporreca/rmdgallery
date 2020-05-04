common_meta <- list(
  gallery_config = list(
    include_before = '<hr><a href="https://example.com">before - Author: {{author}}</a><hr/>',
    include_after = '{{htmltools::tagList(htmltools::hr(), "after -", title, htmltools::hr())}}'
  ),
  title = 'A: "Foo" & Bar\'s',
  author = "Me"
)

.test_template <- function(template, ...) {
  testthat::test_that(paste("template", sQuote(template), "can be filled and rendered"), {
    filled <- from_template(
      meta = c(common_meta, list(template = template, ...))
    )
    rmd <- tempfile(template, fileext = ".rmd")
    writeLines(filled, rmd)
    html <- testthat::expect_error(rmarkdown::render(rmd, params = attr(filled, "params")), NA)
    if (interactive()) browseURL(html)
  })
}

.test_template(
  template = "embed-html",
  content = '<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Oh nice! Riccardo Porreca from Mirai Solutions showing a Shiny app developed as a package, and deployed using Kubernetes. Lots of awesome technical knowledge in this talk - will def be looking up the slides later! ❤️ <a href="https://twitter.com/hashtag/rstats?src=hash&amp;ref_src=twsrc%5Etfw">#rstats</a> <a href="https://twitter.com/hashtag/user2019?src=hash&amp;ref_src=twsrc%5Etfw">#user2019</a> <a href="https://t.co/bFkWlvVO95">pic.twitter.com/bFkWlvVO95</a></p>&mdash; Nic Crane (@nic_crane) <a href="https://twitter.com/nic_crane/status/1148899196965142528?ref_src=twsrc%5Etfw">July 10, 2019</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> '
)

.test_template(
  template = "embed-script",
  content = "https://gist.github.com/riccardoporreca/8fdf653d79be44ed1ad5a90e34bcbeb1.js"
)

.test_template(
  template = "embed-url",
  content = "https://miraisolutions.shinyapps.io/rTRhexNG"
)

.test_template(
  template = "embed-url",
  content = "https://mirai-solutions.ch/techguides",
  css = list(height = "67vh")
)
