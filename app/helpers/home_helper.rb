module HomeHelper

  def schema_markup(schema_version)
    content_tag(:div, class: "schema-panel-set detail") do
      content_tag(:h3, schema_version.schema.name) +
      if schema_version.spec["type"] == "object"
        schema_object_spec_markup(schema_version.spec)
      else
        schema_object_property_markup('', schema_version.spec, false)
      end
    end
  end

  def schema_object_spec_markup(schema_object)
    # TODO: Handle primitives on the root of the schema object. The following
    #       line only sidelines the problem not rendering anything at all.
    return "" unless schema_object.has_key? 'properties'
    schema_object['properties'].map do |name, property_definition|
      required = schema_object["required"].include?(name) if schema_object["required"].present?
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

  def dinamic_component_structure(name, property_definition, required)
  type_and_format = property_definition['type'] || ''
  type_and_format += ' (' + property_definition['format'] + ')' if property_definition['format'].present?
  content_tag(:div, nil, class: "panel-group") do
      content_tag(:div, nil, class: "panel panel-schema") do
        content_tag(:div, nil, class: "panel-heading clearfix") do
          content_tag(:div, nil, class: "panel-title " + (required ? "required" : "")) do
            content_tag(:div, nil, class: "col-md-6") do
              name +
              content_tag(:p, type_and_format, class: "data-type") +
              content_tag(:p, property_definition['description'] || '', class: "description")
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
    customized_name = content_tag(:span, name, class: "name")
    dinamic_component_structure(customized_name, primitive_property_definition, required)
  end

  def schema_object_complex_property_markup(name, property_definition, required)
    customized_name = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, name, class: "name")
    end
    dinamic_component_structure(customized_name, property_definition, required){
      content_tag(:div, nil, class: "panel-body") do
        schema_object_spec_markup(property_definition)
      end
    }
  end

  def schema_object_array_property_markup(name, property_definition, required)
    customized_name = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, name, class: "name")
    end
    dinamic_component_structure(customized_name, property_definition, required){
      content_tag(:div, nil, class: "panel-body") do
         schema_object_property_markup("(elementos)", property_definition["items"], false)
      end
    }
  end

  def schema_object_specific_markup(property_definition)
    case property_definition['type']
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
      concat(content_tag(:li, 'por defecto ' + property_definition['default'].to_s))
    end
    if property_definition['enum'].present?
      elements = "enum: "
      property_definition['enum'].each do |element|
         elements += element + '<br>'
      end
      concat(content_tag(:li, elements.html_safe))
    end
  end

  def markup_humanizer(name = '', suffix = '', max, min)
    if max.present? && min.present?
      if max == min
        concat(content_tag(:li, "largo #{max} #{name}" + (max!=1 ? "#{suffix}" : "")))
      else
        concat(content_tag(:li, "rango #{min}-#{max} #{name}" + (max!=1 ? "#{suffix}" : "")))
      end
    else
      concat(content_tag(:li, "máximo #{max} #{name}" + (max!=1 ? "#{suffix}" : ""))) if max.present?
      concat(content_tag(:li, "mínimo #{min} #{name}" + (min!=1 ? "#{suffix}" : ""))) if min.present?
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
      concat(content_tag(:li, "items únicos"))
    end
    markup_humanizer("elemento", "s", max, min)
  end

  def numeric_primitive_markup(primitive)
    max = primitive['maximum']
    min = primitive['minimum']
    exclusiveMax = primitive['exclusiveMaximum']
    exclusiveMin = primitive['exclusiveMinimum']
    if primitive['multipleOf'].present?
      concat(content_tag(:li, "múltiplo de #{primitive['multipleOf']}"))
    end
    if max.present? && min.present?
      concat(content_tag(:li, "#{min} " + (exclusiveMin ? "<" : "≤") + " x " +
        (exclusiveMax ? "<" : "≤") + " #{max}"))
    else
      concat(content_tag(:li, "x " + (exclusiveMin ? ">" : "≥") + " #{min}")) if min.present?
      concat(content_tag(:li, "x " + (exclusiveMax ? "<" : "≤") + " #{max}")) if max.present?
    end
  end

  def string_primitive_markup(primitive)
    max = primitive['maxLength']
    min = primitive['minLength']
    if primitive['pattern'].present?
      concat(content_tag(:li, class: "reg-exp") do
        content_tag(:span, "#{primitive['pattern']}")
      end)
    end
    markup_humanizer(max, min)
  end
end