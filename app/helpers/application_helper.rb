module ApplicationHelper
  def markdown
    # We want to render Github's flavored markdown, as per Swagger 2.0 spec
    # Options taken from https://george-hawkins.github.io/basic-gfm-jekyll/redcarpet-extensions.html
    Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(
        with_toc_data: false,
        hard_wrap: false,
        xhtml: false,
        prettify: false,
        filter_html: true,
        safe_links_only: true
      ),
      no_intra_emphasis: true,
      tables: true,
      fenced_code_blocks: true,
      autolink: true,
      disable_indented_code_blocks: false,
      strikethrough: true,
      lax_spacing: true,
      space_after_headers: true,
      superscript: false,
      underline: false,
      highlight: false,
      quote: false,
      footnotes: false
    )
  end
end
