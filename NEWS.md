# rmdgallery (development version)

- Metadata in YAML format are now also supported (#2).
- Custom _page types_ are now supported as an alternative to the `template` field of the metadata. Page types are defined and mapped to actual templates in the `gallery` site configuration, using new fields `type_field` and `type_template` (#4).
- Default values for unspecified fields in the metadata can now be defined using the new `defaults` field in the `gallery` site configuration (#3).

# rmdgallery 0.1.0

## First versioned release

- The package provides the `gallery_site` website generator to be used with `rmarkdown::render_site()`. This generates a simple R Markdown website including a gallery of pages with embedded content, based on metadata in JSON format and custom site configuration options.
- Three templates are provided for including different content in gallery pages: `embed-url` (embed an external page given its URL), `embed-html` (include raw HTML for embedding arbitrary content), `embed-script` (generate embedded content by including JavaScript code).
- Custom templates are supported and can be defined with the help of the provided `gallery_content()` function.
- Usage and behavior extensively described in the package README.
