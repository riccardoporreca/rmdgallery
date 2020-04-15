# rmdgallery 0.3.0

## New features

- `include_before` and `include_after` in the `gallery` site configuration now define the path to a file with the included content (#14). The old inline content definition is still supported but triggers a deprecation warning.
- A new field `order_by` in the `gallery` site configuration allows specifying a set of fields the metadata should be ordered by (#15).
- A new metadata field `page_name` is included for each page, containing the name of the corresponding element in the metadata list eventually used for the resulting HTML page (#15).
- Icons for the gallery navigation bar menu are now supported in the metadata, and specified as a new field `menu_icon` or by defining the `menu_entry` field with two components `text` and `icon` (#16).

# Fix

- The `gallery_site()` generator now works with an empty list of metadata (#20).


# rmdgallery 0.2.2

## Patch release

- The `gallery_site()` generator now works when `rmarkdown::render_site()` is called with any path to a directory containing the website sources (#11).

# rmdgallery 0.2.1

## Patch release

- Fix handling of missing `type_field` in the `gallery` site configuration (#10).

# rmdgallery 0.2.0

## New features

- Metadata in YAML format are now also supported (#2).
- Custom _page types_ are now supported as an alternative to the `template` field of the metadata. Page types are defined and mapped to actual templates in the `gallery` site configuration, using new fields `type_field` and `type_template` (#4).
- Default values for unspecified fields in the metadata can now be defined using the new `defaults` field in the `gallery` site configuration (#3).

## Maintenance

- Updated package README to cover new features and point to branch `develop` for using the development version.
- Extended test coverage for new as well as existing utilities.

# rmdgallery 0.1.0

## First versioned release

- The package provides the `gallery_site` website generator to be used with `rmarkdown::render_site()`. This generates a simple R Markdown website including a gallery of pages with embedded content, based on metadata in JSON format and custom site configuration options.
- Three templates are provided for including different content in gallery pages: `embed-url` (embed an external page given its URL), `embed-html` (include raw HTML for embedding arbitrary content), `embed-script` (generate embedded content by including JavaScript code).
- Custom templates are supported and can be defined with the help of the provided `gallery_content()` function.
- Usage and behavior extensively described in the package README.
