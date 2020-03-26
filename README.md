
# rmdgallery

<!-- badges: start -->
[![R build status](https://github.com/riccardoporreca/rmdgallery/workflows/R-CMD-check/badge.svg)](https://github.com/riccardoporreca/rmdgallery/actions)
[![Travis build status](https://travis-ci.com/riccardoporreca/rmdgallery.svg?branch=master)](https://travis-ci.com/riccardoporreca/rmdgallery)
<!-- badges: end -->

The goal of **rmdgallery** is to provide an R Markdown [site generator](https://bookdown.org/yihui/rmarkdown/rmarkdown-site.html#custom-site-generators) that supports the inclusion of a gallery of (embedded) pages created in a dynamic way based on metadata in JSON format.

An example of using **rmdgallery** can can be found in the [rmd-gallery-example](https://github.com/riccardoporreca/rmd-gallery-example#readme) GitHub repository.


## Installation

You can install the **rmdgallery** package from GitHub with:

``` r
remotes::install_github("riccardoporreca/rmdgallery")
```

If you have a website R project, you can define **rmdgallery** as a dependency in the `DESCRIPTION` file, with the corresponding entry in the `Remotes:` field (possibly specifying which release tag to use):
```
Imports:
  rmdgallery
Remotes:
  riccardoporreca/rmdgallery
```
See e.g. [rmd-gallery-example](https://github.com/riccardoporreca/rmd-gallery-example/blob/master/DESCRIPTION).

## Using rmdgallery

The provided `rmdgallery::gallery_site` function (or it alias `rmdgallery::gallery_site_generator`) can be used as [custom site generator](https://bookdown.org/yihui/rmarkdown/rmarkdown-site.html#custom-site-generators) for rendering a [simple R Markdown website](https://bookdown.org/yihui/rmarkdown/rmarkdown-site.html) via `rmarkdown::render_site()`. As such it must be specified as `site:` field of `index.(R)md`

```yaml
---
title: "My Website"
site: rmdgallery::gallery_site
---
```

Below we describe how the **_metadata_** for multiple pages are defined and used to render pages based on alternative **_templates_**, and how specific site **_configuration_** is added to the standard `_site.yml` configuration file.


### Page metadata and templates

At the core of **rmdgallery** are R Markdown templates for the pages to be included in the website, containing placeholders for metadata. The details behind how templates define and make use of metadata are covered in section ['Custom templates'](#custom-templates) below.

The specific metadata of each individual page are defined in JSON file(s) in the `meta` directory of the website project. For example, the following JSON
```json
{
  "foo": {
    "title": "Embed raw html content",
    "menu_entry": "HTML example",
    "template": "embed-html",
    "content": "<h3>Hello Rmd Gallery</h3>"
  },
  "bar": {
    "title": "Embed content from an external URL",
    "menu_entry": "URL example",
    "template": "embed-url",
    "content": "https://example.com"
  }
}
```
defines the metadata for pages rendered as `foo.html` and `bar.html` with the given page `title`, also adding the specified `menu_entry` to the [site navigation bar](https://bookdown.org/yihui/rmarkdown/rmarkdown-site.html#site-navigation).

The way metadata, especially the `content`, are used to produce the resulting page depends on the specified `template`. Templates might in general make use of additional specific metadata fields, which can also be used for additional content included in the custom site [configuration](#configuration-and-customization).

The predefined templates provided by **rmdgallery** are described next.

#### `"template": "embed-url"`

Embed a page given its URL, using `<ifame src={{content}}>`, where `{{content}}` is the embedded page URL specified as `content` in the metadata. In addition, an optional `css` field in the metadata allows to fine-tune the CSS style of the `<iframe>`. In particular, `height` can be useful for defining the height (in valid CSS units) of the embedded non-responsive content, as in the following example:
``` json
{
  "title": "My Title",
  "template": "embed-url",
  "content": "https://bookdown.org/yihui/rmarkdown",
  "css": {
    "height": "80vh"
  }
}
```

#### `"template": "embed-html"`

Embed the HTML code defined in the `content` field of the metadata. This can be used for cases where more complex, custom embedding code must be supplied (e.g. social media, videos)

#### `"template": "embed-script"`

Embed based on JavaScript, using `<script src={{content}}>`, where `{{content}}` is the URL of a `.js` script. This is a special case of `embed-html`, useful e.g. for embedding a GitHub [gist](https://help.github.com/en/github/writing-on-github/editing-and-sharing-content-with-gists).


### Configuration and customization

Configuration and customization of the website specific to `rmdgallery::gallery_site_generator` are defined by adding a `gallery:` field to the standard `_site.yml` configuration file. The following examples describe the available options:

``` yaml
name: "my-website"
navbar:
  title: "My Website"
  left:
    - text: "Home"
      href: index.html
gallery:
  meta_dir: "meta"
  single_meta: false
  template_dir: "path/to/cutom/templates"
  navbar:
    left:
      - text: "Gallery"
        icon: fa-gear
  include_before: |
    <hr>include_before for {{title}}<hr/>
  after: |
    {{htmltools::tagList(
        htmltools::hr(),
        "include_after for", title,
        htmltools::hr()
    )}}
```

- `meta_dir:` Optional name of the directory containing the `.json` metadata files. Defaults to `meta` if not specified.
- `single_meta:` Optional `true` or `false` defining whether the `.json` files define metadata for individual pages, in which case a file `foo.json` would contain only the metadata for the `foo.html` page. Defaults to `false` if not specified.
- `template_dir:` Optional location of additional custom templates.
- `navbar:` The gallery navigation menu to be included in the standard `navbar:` of `_site.yml`. The menu is populated with the `menu_entry` of each page from the metadata. Can be omitted if no such menu should be included.
- `include_before:`, `include_after:` Custom content to be included before and after the main `content`. Both are included for each page and may be defined in terms of fields from the metadata via using `{{...}}`. Such placeholders are then processed using `glue::glue_data(meta)`, where `meta` is the list of metadata for a given page. This allows to use simple string replacements of raw HTML code (like in `include_before:` in the example) or R expression constructing HTML elements via [**htmltools**](https://cran.r-project.org/package=htmltools) (like in ``include_after:`).

You can see the various elements of the configuration in action in the [rmd-gallery-example](https://github.com/riccardoporreca/rmd-gallery-example#readme) GitHub repository

### Custom templates

Besides the templates provided with **rmdgallery** (described above), it is possible to define custom R Markdown templates. These are standard R Markdown documents (as you would normally include in a [simple R Markdown website](https://bookdown.org/yihui/rmarkdown/rmarkdown-site.html)), which however will be populated with specific page metadata using two mechanisms:

- Similar to what described for `include_before:`, `include_after:` above, any expression `{{...}}` is evaluated via `glue::glue_data(meta)` by looking up values from the list of metadata extracted from the JSON file(s). For example, the placeholder `{{toupper(title)}}` will be replaced with the uppercase version of the `title:` entry in the metadata. Such elements can be placed anywhere in the R Markdown document (not necessarily a code chunk), and make use of [**htmltools**](https://cran.r-project.org/package=htmltools) (see again `include_before:`, `include_after:` from the `gallery:` configuration above).

- When the template is rendered for a given page, the metadata are also passed as `params` list. As such, templates work like [parameterized reports](https://bookdown.org/yihui/rmarkdown/parameterized-reports.html) and the relevant metadata should be declared as `params:` in the YAML front matter, along with sensible defaults. Metadata defined in this way are then evaluated as e.g. `params$content` in R code chunks or via <code>\`r params$content\`</code> inline.

The two approaches can coexist, but keep in mind that rendering the template as parameterized report happens **after** evaluating `{{...}}` placeholders. Also note that `params` cannot be used in the YAML front matter, so you should only use `{{...}}` there, which is always the case with `title: {{title}}`.

In addition to the metadata in the JSON template, a `gallery_config` element with the content of `gallery:` from the `_site.yml` configuration is also available when processing the template. In particular, `gallery_config$include_before` and `gallery_config$include_after` are added with placeholder expressions already evaluated, and templates should explicitly make use them to include them in the rendered page content.

Function `rmdgallery::gallery_content()` facilitates the construction of the content in a standardized way and it usage is recommended. In particular, it handles `gallery_config$include_before` and `gallery_config$include_after` and provides a common set of classed HTML elements (see below).

The templates provided within the package can be seen under 'inst/templates' in the source package, and are available at `system.file("templates", package = "rmdgallery")` for the installed package.

### CSS customization

The content of gallery pages constructed using the provided templates (or any custom template making use of `rmdgallery::gallery_content()`) have the following general structure (see also `?rmdgallery::gallery_content`)
```html
<div class="gallery-container {template/metadata-specific classes}">
  <div class="gallery-before">{include_before}</div>
  <div class="gallery-main">{main content}</div>
  <div class="gallery-before">{include_after}</div>
</div>
```
which provide a convenient basis for styling the elements using CSS selectors.


