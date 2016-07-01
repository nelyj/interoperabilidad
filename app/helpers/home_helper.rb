module HomeHelper

  def schema_markup(schema_version)
    spec = schema_version.spec_with_resolved_refs['definition']
    content_tag(:div, class: "schema-panel-set detail") do
      content_tag(:h3, s(schema_version.schema.name)) +
      if spec["type"] == "object"
        schema_object_spec_markup(spec)
      else
        schema_object_property_markup('', spec, false)
      end
    end
  end

  def schema_object_spec_markup(schema_object)
    schema_object['properties'].map do |name, property_definition|
      required = schema_object["required"].
        include?(name) if schema_object["required"].present?
      schema_object_property_markup(name, property_definition, required)
    end.join("").html_safe
  end

  def schema_object_property_markup(name, property_definition, required)
    if property_definition["type"] == "object"
      schema_object_complex_property_markup(name, property_definition, required)
    elsif property_definition["type"] == "array"
      schema_object_array_property_markup(name, property_definition, required)
    else
      schema_object_primitive_property_markup(name, property_definition, required)
    end
  end

  def dynamic_component_structure(name, property_definition, required)
    type_and_format = s(property_definition['type']) || ''
    type_and_format += ' (' + s(property_definition['format']) +
      ')' if property_definition['format'].present?
    content_tag(:div, nil, class: "panel-group") do
      content_tag(:div, nil, class: "panel panel-schema") do
        content_tag(:div, nil, class: "panel-heading clearfix") do
          content_tag(:div, nil, class: "panel-title " + (required ? "required" : "")) do
            content_tag(:div, nil, class: "col-md-6") do
              name +
              content_tag(:p, type_and_format, class: "data-type") +
              content_tag(:p, s(property_definition['description']) || '', 
                class: "description")
            end +
            content_tag(:div, nil, class: "col-md-6 text-right") do
              content_tag(:a, class: "btn btn-static link-schema") do
                content_tag(:span, "schema")
              end +
              content_tag(:ul) do
                schema_object_specific_markup(property_definition)
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

  def schema_object_primitive_property_markup(name, primitive_property_definition, required)
    customized_name = content_tag(:span, s(name), class: "name")
    dynamic_component_structure(customized_name, primitive_property_definition, required)
  end

  def schema_object_complex_property_markup(name, property_definition, required)
    customized_name = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, s(name), class: "name")
    end
    dynamic_component_structure(customized_name, property_definition, required){
      content_tag(:div, nil, class: "panel-body") do
        schema_object_spec_markup(property_definition)
      end
    }
  end

  def schema_object_array_property_markup(name, property_definition, required)
    customized_name = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, s(name), class: "name")
    end
    dynamic_component_structure(customized_name, property_definition, required){
      content_tag(:div, nil, class: "panel-body") do
         schema_object_property_markup("(elementos)", property_definition["items"], false)
      end
    }
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
    end
  end

  def schema_object_common_markup(property_definition)
    if property_definition['default'].present?
      concat(content_tag(:li, 'por defecto ' + s(property_definition['default'].to_s)))
    end
    if property_definition['enum'].present?
      elements = "enum: "
      property_definition['enum'].each do |element|
         elements += s(element) + '<br>'.html_safe
      end
      concat(content_tag(:li, elements.html_safe))
    end
  end

  def markup_humanizer(name = '', suffix = '', max, min)
    if max.present? && min.present?
      if max == min
        concat(content_tag(:li, "largo #{s(max.to_s)} #{name}" +
          (max!=1 ? "#{suffix}" : "")))
      else
        concat(content_tag(:li, "rango #{s(min.to_s)}-#{s(max.to_s)} #{name}" +
          (max!=1 ? "#{suffix}" : "")))
      end
    else
      concat(content_tag(:li, "máximo #{s(max.to_s)} #{name}" +
        (max!=1 ? "#{suffix}" : ""))) if max.present?
      concat(content_tag(:li, "mínimo #{s(min.to_s)} #{name}" +
        (min!=1 ? "#{suffix}" : ""))) if min.present?
    end
  end

  def object_specific_markup(property_definition)
    max = property_definition['maxProperties']
    min = property_definition['minProperties']
    markup_humanizer("propiedad", "es", max, min)
  end

  def array_specific_markup(property_definition)
    max = property_definition['maxItems']
    min = property_definition['minItems']
    if property_definition['uniqueItems'].present?
      concat(content_tag(:li, "elementos únicos"))
    end
    markup_humanizer("elemento", "s", max, min)
  end

  def numeric_primitive_markup(primitive)
    max = primitive['maximum']
    min = primitive['minimum']
    exclusiveMax = primitive['exclusiveMaximum']
    exclusiveMin = primitive['exclusiveMinimum']
    if primitive['multipleOf'].present?
      concat(content_tag(:li, "múltiplo de #{s(primitive['multipleOf'].to_s)}"))
    end
    if max.present? && min.present?
      concat(content_tag(:li, "#{s(min.to_s)} " + (exclusiveMin ? "<" : "≤") +
        " x " + (exclusiveMax ? "<" : "≤") + " #{s(max.to_s)}"))
    else
      concat(content_tag(:li, "x " + (exclusiveMin ? ">" : "≥") +
        " #{s(min.to_s)}")) if min.present?
      concat(content_tag(:li, "x " + (exclusiveMax ? "<" : "≤") +
        " #{s(max.to_s)}")) if max.present?
    end
  end

  def string_primitive_markup(primitive)
    max = primitive['maxLength']
    min = primitive['minLength']
    if primitive['pattern'].present?
      concat(content_tag(:li, class: "reg-exp") do
        content_tag(:span, "#{s(primitive['pattern'])}")
      end)
    end
    markup_humanizer(max, min)
  end

  def s(content)
    sanitize(content)
  end
end
