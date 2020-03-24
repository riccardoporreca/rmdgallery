# rmarkdown/R/render_site.R ----
# https://github.com/rstudio/rmarkdown/blob/947b87259333b43f47b5f59e91dc9a1ea10d1c4d/R/render_site.R

#' Gallery website generator.
#'
#' @inheritParams rmarkdown::default_site_generator
#'
#' @details See [rmarkdown::default_site_generator()], from which the
#'   implementation was adapted.
#'
#' @export
gallery_site <- function(input, ...) {

  # get the site config
  config <- gallery_site_config(input)
  if (is.null(config))
    stop("No site configuration (_site.yml) file found.")

  # helper function to get all input files. includes all .Rmd and
  # .md files that don't start with "_" (note that we don't do this
  # recursively because rmarkdown in general handles applying common
  # options/elements across subdirectories poorly). Also excludes
  # README.R?md as those files are intended for GitHub. If
  # config$autospin is TRUE, we also spin and render .R files.
  input_files <- function() {
    pattern <- sprintf(
      "^[^_].*\\.%s$", if (isTRUE(config$autospin)) {
        "([Rr]|[Rr]?md)"
      } else {
        "[Rr]?md"
      }
    )
    files <- list.files(input, pattern)
    if (is.character(config$autospin)) files <- c(files, config$autospin)
    files[!grepl("^README\\.R?md$", files)]
  }

  # helper function constructing the gallery navbar entry
  navbar_with_gallery <- function() {
    if (!is.null(config$gallery$navbar)) {
      gallery_navbar <- config$gallery$navbar
      meta <- config$gallery$meta
      # must have one element, which is the location, e.g. $left
      stopifnot(length(gallery_navbar) == 1L)
      gallery_links <- file_with_ext(names(meta), "html")
      gallery_entry <- vapply(meta, FUN.VALUE = "", function(x) {
        x$menu_entry %||% NA_character_
      })
      has_entry <- !is.na(gallery_entry)
      duplicated <- duplicated(gallery_entry[has_entry])
      if (any(duplicated)) {
        stop(
          "Found duplicate navbar menu entries: ",
          toString(sQuote(gallery_entry[has_entry][duplicated])))
      }
      gallery_navbar[[1L]][[1]]$menu <- mapply(
        SIMPLIFY = FALSE, USE.NAMES = FALSE,
        function(text, href) {
          list(text = text, href = href)
        },
        gallery_entry[has_entry], gallery_links[has_entry]
      )
      # add to the user-defined navbar from the main site configuration
      navbar <- config$navbar
      navbar[[names(gallery_navbar)]] <- c(
        navbar[[names(gallery_navbar)]],
        gallery_navbar[[1]]
      )
      navbar
    }
  }

  # define render function (use ... to gracefully handle future args)
  render <- function(input_file,
                     output_format,
                     envir,
                     quiet,
                     ...) {

    navbar <- navbar_with_gallery()
    if (!is.null(navbar) == 1L) {
      custom_navbar <- file.path(input, "_navbar.html")
      file.copy(rmarkdown::navbar_html(navbar), custom_navbar, overwrite = TRUE)
      on.exit(unlink(custom_navbar))
    }

    # track outputs
    outputs <- c()

    # see if this is an incremental render
    incremental <- !is.null(input_file)

    # files list is either a single file (for incremental) or all
    # file within the input directory
    if (incremental)
      files <- input_file
    else {
      files <- file.path(input, input_files())
    }
    files <- c(files, file_with_ext(names(config$gallery$meta), "meta"))

    sapply(files, function(x) {
      render_one <- if (isTRUE(config$new_session)) {
        render_new_session
      } else {
        render_current_session
      }

      # log the file being rendered
      output_file <- NULL
      if (!quiet) message("\nRendering: ", x)

      if (tools::file_ext(x) == "meta") {
        name <- tools::file_path_sans_ext(x)
        meta <- config$gallery$meta[[name]]
        if (!quiet) message("\nMetadata from: ", meta$source)
        # gallery config:
        meta$gallery_config <- if (is.null(config$gallery)) list() else config$gallery
        output_file <- file.path(input, file_with_ext(name, "html"))
        x <- file.path(input, file_with_ext(sprintf(".tmp_%s", name), "Rmd"))
        template_dir <- if (!is.null(config$gallery$template_dir)) {
          file.path(input, config$gallery$template_dir)
        }
        rmd_content <- from_template(meta, template_dir)
        knit_params <- attr(rmd_content, "params")
        writeLines(rmd_content, x)
        on.exit(unlink(x))
      }

      # make some useful utils available when rendering
      envir <- list2env(render_time_utils, parent = envir)

      output <- render_one(input = x,
                           output_format = output_format, output_file = output_file,
                           output_options = list(lib_dir = "site_libs",
                                                 self_contained = FALSE),
                           params = knit_params,
                           envir = envir,
                           quiet = quiet)

      # add to global list of outputs
      outputs <<- c(outputs, output)

      # check for files dir and add that as well
      sidecar_files_dir <- knitr_files_dir(output)
      files_dir_info <- file.info(sidecar_files_dir)
      if (isTRUE(files_dir_info$isdir))
        outputs <<- c(outputs, sidecar_files_dir)
    })

    # do we have a relative output directory? if so then remove,
    # recreate, and copy outputs to it (we don't however remove
    # it for incremental builds)
    if (config$output_dir != '.') {

      # remove and recreate output dir if necessary
      output_dir <- file.path(input, config$output_dir)
      if (file.exists(output_dir)) {
        if (!incremental) {
          unlink(output_dir, recursive = TRUE)
          dir.create(output_dir)
        }
      } else {
        dir.create(output_dir)
      }

      # move outputs
      for (output in outputs) {

        # don't move it if it's a _files dir that has a _cache dir
        if (grepl("^.*_files$", output)) {
          cache_dir <- gsub("_files$", "_cache", output)
          if (dir_exists(cache_dir))
            next;
        }

        output_dest <- file.path(output_dir, basename(output))
        if (dir_exists(output_dest))
          unlink(output_dest, recursive = TRUE)
        file.rename(output, output_dest)
      }

      # copy lib dir a directory at a time (allows it to work with incremental)
      lib_dir <- file.path(input, "site_libs")
      output_lib_dir <- file.path(output_dir, "site_libs")
      if (!file.exists(output_lib_dir))
        dir.create(output_lib_dir)
      libs <- list.files(lib_dir)
      for (lib in libs)
        file.copy(file.path(lib_dir, lib), output_lib_dir, recursive = TRUE)
      unlink(lib_dir, recursive = TRUE)

      # copy other files
      copy_site_resources(input)
    }

    # Print output created for rstudio preview
    if (!quiet) {
      # determine output file
      output_file <- ifelse(is.null(input_file),
                            "index.html",
                            file_with_ext(basename(input_file), "html"))
      if (config$output_dir != ".")
        output_file <- file.path(config$output_dir, output_file)
      message("\nOutput created: ", output_file)
    }
  }

  # define clean function
  clean <- function() {

    # build list of generated files
    generated <- c()

    # enumerate rendered markdown files
    files <- input_files()

    # get html files
    html_files <- file_with_ext(files, "html")

    # _files peers are always removed (they could be here due to
    # output_dir == "." or due to a _cache existing for the page)
    html_supporting <- paste0(knitr_files_dir(html_files), '/')
    generated <- c(generated, html_supporting)

    # _cache peers are always removed
    html_cache <- paste0(knitr_root_cache_dir(html_files), '/')
    generated <- c(generated, html_cache)

    # for rendering in the current directory we need to eliminate
    # output files for our inputs (including _files) and the lib dir
    if (config$output_dir == ".") {

      # .html peers
      generated <- c(generated, html_files)

      # site_libs dir
      generated <- c(generated, "site_libs/")

      # for an explicit output_dir just remove the directory
    } else {
      generated <- c(generated, paste0(config$output_dir, '/'))
    }

    # filter out by existence
    generated[file.exists(file.path(input, generated))]
  }

  # return site generator
  list(
    name = config$name,
    output_dir = config$output_dir,
    render = render,
    clean = clean
  )
}


#' @rdname gallery_site
#' @export
gallery_site_generator <- gallery_site

# > internals ----

# we suppress messages during render so that "Output created" isn't emitted
# (which could result in RStudio previewing the wrong file)
render_current_session <- function(...) suppressMessages(rmarkdown::render(...))

render_new_session <- function(...) {
  if (!requireNamespace("callr", quietly = TRUE)) {
    stop("The callr package must be installed when `new_session: true`.")
  }
  callr::r(
    function(...) { suppressMessages(rmarkdown::render(...)) },
    args = list(...),
    block_callback = function(x) cat(x)
  )
}

# utility function to copy all files into the _site directory
copy_site_resources <- function(input) {

  # get the site config
  config <- rmarkdown::site_config(input)

  if (config$output_dir != ".") {

    # get the list of files
    files <- copyable_site_resources(input = input, config = config)

    # perform the copy
    output_dir <- file.path(input, config$output_dir)
    file.copy(from = file.path(input, files),
              to = output_dir,
              recursive = TRUE)
  }
}

# utility function to list the files that should be copied
copyable_site_resources <- function(input, config = rmarkdown::site_config(input)) {

  include <- config$include

  exclude <- config$exclude
  if (config$output_dir != ".")
    exclude <- c(exclude, config$output_dir)

  rmarkdown::site_resources(input, include, exclude)
}


# rmarkdown/R/util.R ----
# https://github.com/rstudio/rmarkdown/blob/947b87259333b43f47b5f59e91dc9a1ea10d1c4d/R/util.R

dir_exists <- function(x) {
  length(x) > 0 && utils::file_test('-d', x)
}

file_with_ext <- function(file, ext) {
  paste(tools::file_path_sans_ext(file), ".", ext, sep = "")
}

knitr_files_dir <- function(file) {
  paste(tools::file_path_sans_ext(file), "_files", sep = "")
}

knitr_root_cache_dir <- function(file) {
  paste(tools::file_path_sans_ext(file), "_cache", sep = "")
}
