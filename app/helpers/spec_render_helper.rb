module SpecRenderHelper

  def json_pointer_path(base, *new_components)
    return base if new_components.empty?
    base = '' if base == '/' # Avoid doubling slashes
    encoded_components = new_components.map do |arg|
      arg.gsub('~', '~0').gsub('/', '~1') # As per RFC 6901
    end
    encoded_components.unshift(base).join('/')
  end

  def join_markup(buffers)
    buffers.reduce(ActiveSupport::SafeBuffer.new) do |result, buffer|
      result.concat buffer
    end
  end

  def schema_markup(schema_version)
    name = schema_version.schema.name
    spec = schema_version.spec_with_resolved_refs['definition']
    references = schema_version.spec_with_resolved_refs['references']
    content_tag(:div, class: "schema-panel-set detail", data: {name: name, version: schema_version.version_number}) do
      inner_markup = case spec["type"]
      when "object"
        schema_object_spec_markup(spec, '/', references)
      else
        schema_object_property_markup('', spec, false, '/', references)
      end
      content_tag(:h3, s(schema_version.schema.name)) + inner_markup
    end
  end

  def schema_object_spec_markup(schema_object, json_pointer, references)
    properties = schema_object['properties'] || {}
    join_markup(properties.map do |name, property_definition|
      required = (
        schema_object.has_key?("required") &&
        schema_object["required"].include?(name)
      )
      schema_object_property_markup(
        name, property_definition, required,
        json_pointer_path(json_pointer, 'properties', name), references
      )
    end)
  end

  def schema_object_property_markup(name, property_definition, required, json_pointer, references)
    property_definition['type'] ||= 'object'
    if property_definition["type"] == "object"
      schema_object_complex_property_markup(
        name, property_definition, required, json_pointer, references
      )
    elsif property_definition["type"] == "array"
      schema_object_array_property_markup(
        name, property_definition, required, json_pointer, references
      )
    else
      schema_object_primitive_property_markup(
        name, property_definition, required, json_pointer, references
      )
    end
  end

  # Return true if the uri seems to point to our own schema pages
  def looks_like_standard_schema_uri?(uri)
    recognized_path = Rails.application.routes.recognize_path(URI(uri).path)
    return (
      recognized_path[:controller] == "schema_versions" &&
      recognized_path[:action] == "show"
    )
  rescue
    false
  end

  def schema_link_if_reference_present(json_pointer, references)
    ref_key = "#" + json_pointer
    if references[ref_key] && references[ref_key]['type'] == 'remote'
      uri = references[ref_key]['uri']
      if looks_like_standard_schema_uri?(uri)
        # Instead of sending the user to the raw JSON of the referenced
        # schema, send them to the nice HTML page of our own web app :)
        uri.gsub!(/\.json$/, "")
      end
      content_tag(:a, class: "btn btn-static link-schema", href: uri, rel: "noopener noreferrer", target: "_blank") do
        content_tag(:span, "schema")
      end
    else
      "".html_safe
    end
  end

  # IMPORTANT NOTE: We use the `s_` prefix to denote variables already sanitized
  # from html. Also note that the `s()` function is an alias for sanitize()
  # defined at the end of this helper.
  #
  # That way, if we spot any variable not prefixed by `s_` and not
  # wrappend in `s()` being concatenated into HTML markup, it most likely means
  # we are introducing a XSS vulnerability

  def dynamic_component_structure(s_name_markup, property_definition, required, json_pointer, references)
    s_type_and_format = s(property_definition['type']) || ''
    if property_definition.has_key?('format')
      s_type_and_format += "(#{s(property_definition['format'])})"
    end
    content_tag(:div, nil, class: "panel-group", data: {pointer: json_pointer}) do
      content_tag(:div, nil, class: "panel panel-schema") do
        content_tag(:div, nil, class: "panel-heading clearfix") do
          content_tag(:div, nil, class: "panel-title " + (required ? "required" : "")) do
            content_tag(:div, nil, class: "col-md-6") do
              s_name_markup +
              content_tag(:p, s_type_and_format, class: "data-type") +
              content_tag(:div, nil, class: "description") do
                markdown.render(property_definition['description'] || '').html_safe
              end
            end +
            content_tag(:div, nil, class: "col-md-6 text-right") do
              schema_link_if_reference_present(json_pointer, references) +
              content_tag(:ul) do
                schema_object_specific_markup(property_definition) +
                schema_object_common_markup(property_definition)
              end
            end
          end
        end +
        content_tag(:div, nil, class: "panel-collapse collapse") do
          yield if block_given?
        end
      end
    end
  end

  def schema_object_primitive_property_markup(name, primitive_property_definition, required, json_pointer, references)
    css_class = "name"
    css_class.concat(" anonymous") if name.empty?
    s_name_markup = content_tag(:span, s(name), class: css_class)
    dynamic_component_structure(
      s_name_markup, primitive_property_definition, required,
      json_pointer, references
    )
  end

  def schema_object_complex_property_markup(name, property_definition, required, json_pointer, references)
    active_name = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, s(name), class: "name")
    end
    inactive_name = content_tag(:span, s(name), class: "name")
    s_name_markup = property_definition['properties'].present? ? active_name : inactive_name
    dynamic_component_structure(
      s_name_markup, property_definition, required, json_pointer, references
    ) do
      if property_definition['properties'].present?
        content_tag(:div, nil, class: "panel-body") do
          schema_object_spec_markup(property_definition, json_pointer, references)
        end
      end
    end
  end

  def schema_object_array_property_markup(name, property_definition, required, json_pointer, references)
    s_name_markup = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, s(name), class: "name")
    end
    dynamic_component_structure(
      s_name_markup, property_definition, required, json_pointer, references
    ) do
      content_tag(:div, nil, class: "panel-body") do
        schema_object_property_markup(
          "(elementos)".html_safe, property_definition["items"], false,
          json_pointer_path(json_pointer, "items"), references
        )
      end
    end
  end

  def schema_object_specific_markup(property_definition)
    case s(property_definition['type'])
    when "string"
      string_primitive_markup(property_definition)
    when "integer"
      numeric_primitive_markup(property_definition)
    when "number"
      numeric_primitive_markup(property_definition)
    when "array"
      array_specific_markup(property_definition)
    when "object"
      object_specific_markup(property_definition)
    else
      "".html_safe
    end
  end

  def schema_object_common_markup(property_definition)
    schema_object_common_markup_default(property_definition) +
      schema_object_common_markup_enum(property_definition)
  end

  def schema_object_common_markup_default(property_definition)
    if property_definition['default'].present?
      content_tag(:li, 'default ' + s(property_definition['default'].to_s))
    else
      "".html_safe
    end
  end

  def schema_object_common_markup_enum(property_definition)
    if property_definition['enum'].present?
      content_tag :li, (
        "enum: ".html_safe +
        join_markup(property_definition['enum'].map do |element|
          s(element) + '<br>'.html_safe
        end)
      )
    else
      "".html_safe
    end
  end

  def markup_humanizer(name = '', suffix = '', max: nil, min: nil)
    if max.present? && min.present?
      if max == min
        content_tag(:li, "largo #{s(max.to_s)} #{name}" +
          (max!=1 ? "#{suffix}" : ""))
      else
        content_tag(:li, "rango #{s(min.to_s)}-#{s(max.to_s)} #{name}" +
          (max!=1 ? "#{suffix}" : ""))
      end
    else
      if max.present?
        content_tag(:li, "máximo #{s(max.to_s)} #{name}" +
          (max!=1 ? "#{suffix}" : ""))
      elsif min.present?
        content_tag(:li, "mínimo #{s(min.to_s)} #{name}" +
          (min!=1 ? "#{suffix}" : ""))
      else
        "".html_safe
      end
    end
  end

  def object_specific_markup(property_definition)
    max = property_definition['maxProperties']
    min = property_definition['minProperties']
    markup_humanizer("propiedad", "es", max: max, min: min)
  end

  def array_specific_markup(property_definition)
    max = property_definition['maxItems']
    min = property_definition['minItems']
    array_specific_markup_unique_items(property_definition) +
      markup_humanizer("elemento", "s", max: max, min: min)
  end

  def array_specific_markup_unique_items(property_definition)
    if property_definition['uniqueItems'].present?
      content_tag(:li, "elementos únicos")
    else
      "".html_safe
    end
  end

  def numeric_primitive_markup(primitive)
    numeric_primitive_markup_multiple_of(primitive) +
      numeric_primitive_markup_bounds(primitive)
  end

  def numeric_primitive_markup_multiple_of(primitive)
    if primitive['multipleOf'].present?
      content_tag(:li, "múltiplo de #{s(primitive['multipleOf'].to_s)}")
    else
      "".html_safe
    end
  end

  def numeric_primitive_markup_bounds(primitive)
    max = primitive['maximum']
    min = primitive['minimum']
    exclusiveMax = primitive['exclusiveMaximum']
    exclusiveMin = primitive['exclusiveMinimum']
    if max.present? && min.present?
      content_tag(:li, "#{s(min.to_s)} " + (exclusiveMin ? "<" : "≤") +
        " x " + (exclusiveMax ? "<" : "≤") + " #{s(max.to_s)}")
    else
      if min.present?
        content_tag(:li, "x " + (exclusiveMin ? ">" : "≥") +
          " #{s(min.to_s)}")
      elsif max.present?
        content_tag(:li, "x " + (exclusiveMax ? "<" : "≤") +
          " #{s(max.to_s)}")
      else
        "".html_safe
      end
    end
  end

  def string_primitive_markup(primitive)
    max = primitive['maxLength']
    min = primitive['minLength']
    string_primitive_markup_pattern(primitive) +
      markup_humanizer("caracter", "es", max: max, min: min)
  end

  def string_primitive_markup_pattern(primitive)
    if primitive['pattern'].present?
      content_tag(:li, class: "reg-exp") do
        content_tag(:span, "/#{s(primitive['pattern'])}/")
      end
    else
      "".html_safe
    end
  end

  def s(content)
    sanitize(content)
  end
end
