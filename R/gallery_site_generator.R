#' Gallery website generator.
#'
#' @inheritParams rmarkdown::default_site_generator
#'
#' @details See [rmarkdown::default_site_generator()]
#'
#' @export
gallery_site_generator <- function(input, ...) {

  # get the site config
  config <- site_config(input)
  if (is.null(config))
    stop("No site configuration (_site.yml) file found.")

  config$meta <- ifelse(is.null(config$meta), "meta", config$meta)

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
        "[Rr]?md$"
      }
    )
    files <- list.files(input, pattern)
    if (is.character(config$autospin)) files <- c(files, config$autospin)
    files <- files[!grepl("^README\\.R?md$", files)]
    files <- c(files, file.path(config$meta, list.files(file.path(input, config$meta), "[.]json$")))
    files
  }

  # define render function (use ... to gracefully handle future args)
  render <- function(input_file,
                     output_format,
                     envir,
                     quiet,
                     ...) {

    gallery_idx <- which(vapply(config$navbar$left, `[[`, "text", FUN.VALUE = "") == "Gallery")
    meta <- list.files(config$meta, "[.]json$", full.names = TRUE)
    gallery_links <- file_with_ext(basename(meta), "html")
    gallery_entry <- sapply(meta, function(x) jsonlite::read_json(x)$menu_entry)
    config$navbar$left[[gallery_idx]]$menu <- mapply(
      SIMPLIFY = FALSE, USE.NAMES = FALSE,
      function(text, href) {
        list(text = text, href = href)
      },
      gallery_entry, gallery_links
    )
    file.copy(navbar_html(config$navbar), "_navbar.html", overwrite = TRUE)
    on.exit(unlink("_navbar.html"))

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
    sapply(files, function(x) {
      render_one <- if (isTRUE(config$new_session)) {
        render_new_session
      } else {
        render_current_session
      }

      # log the file being rendered
      output_file <- NULL
      if (!quiet) message("\nRendering: ", x)

      if (tools::file_ext(x) == "json") {
        meta <- read_meta(x)
        if (length(config$before_embed) > 0L) {
          meta$before_embed <- glue::glue_data(meta, config$before_embed, .open = "{{", .close = "}}")
        }
        if (length(config$after_embed) > 0L) {
          meta$after_embed <- glue::glue_data(meta, config$after_embed, .open = "{{", .close = ".}}")
        }
        output_file <- file.path(input, file_with_ext(basename(x), "html"))
        if (!quiet) message("\nRendering to : ", output_file)
        x <- file.path(input, file_with_ext(sprintf(".tmp_%s", basename(x)), "Rmd"))
        writeLines(from_template(meta), x)
        on.exit(unlink(x))
      }

      output <- render_one(input = x,
                           output_format = output_format, output_file = output_file,
                           output_options = list(lib_dir = "site_libs",
                                                 self_contained = FALSE),
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
environment(gallery_site_generator) <- list2env(
  as.list(environment(rmarkdown::default_site_generator)),
  parent = environment(gallery_site_generator)
)
