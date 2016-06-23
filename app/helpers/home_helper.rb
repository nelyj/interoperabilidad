module HomeHelper

  def schema_markup(schema_version)
    content_tag(:div, class: "schema-panel-set") do #ID unico, el de schema
      content_tag(:h1, schema_version.schema.name) +  #Remover, el nombre va fuera del colapsable
      schema_object_spec_markup(schema_version.spec)
    end
  end

  def schema_object_spec_markup(schema_object)
    schema_object['properties'].map do |name, property_definition|
      schema_object_property_markup(name, property_definition,  schema_object["required"] || [])
    end.join("").html_safe
  end

  def schema_object_property_markup(name, property_definition, required_properties)
    if property_definition["type"] == "object"
      schema_object_complex_property_markup(name, property_definition, required_properties)
    elsif property_definition["type"] == "array"
      schema_object_array_property_markup(name, property_definition, required_properties)
    else
      schema_object_primitive_property_markup(name, property_definition, required_properties)
    end
  end

  def schema_object_array_property_markup(name, property_definition, required_properties)
    content_tag(:div, nil, class: "panel-group") do
      content_tag(:div, nil, class: "panel panel-schema") do
        content_tag(:div, nil, class: "panel-heading clearfix") do
          content_tag(:div, nil, class: "panel-title required") do #required
            content_tag(:div, nil, class: "col-md-6") do
              content_tag(:a, nil, data: {toggle: "collapse-next"}) do
                content_tag(:span, name, class: "name")
              end +
              content_tag(:p, property_definition['type'] || '', class: "data-type") +
              content_tag(:p, property_definition['description'] || '', class: "description")
            end +
            content_tag(:div, nil, class: "col-md-6 text-right") do
              content_tag(:a, class: "btn btn-static link-schema") do
                content_tag(:span, "schema")
              end +
              content_tag(:ul) do
                schema_object_specific_markup(property_definition)
              end
            end
          end
        end +
        content_tag(:div, nil, class: "panel-collapse collapse") do
          content_tag(:div, nil, class: "panel-body") do
            schema_object_property_markup("(elementos)", property_definition["items"], required_properties)
          end
        end
      end
    end
  end

  def schema_object_complex_property_markup(name, property_definition, required_properties)
    content_tag(:div, nil, class: "panel-group") do
      content_tag(:div, nil, class: "panel panel-schema") do
        content_tag(:div, nil, class: "panel-heading clearfix") do
          content_tag(:div, nil, class: "panel-title required") do #required
            content_tag(:div, nil, class: "col-md-6") do
              content_tag(:a, nil, data: {toggle: "collapse-next"}) do
                content_tag(:span, name, class: "dot")
              end +
              content_tag(:p, property_definition['type'] || '', class: "data-type") +
              content_tag(:p, property_definition['description'] || '', class: "description")
            end +
            content_tag(:div, nil, class: "col-md-6 text-right") do
              content_tag(:a, class: "btn btn-static link-schema") do
                content_tag(:span, "schema")
              end
            end
          end
        end +
        content_tag(:div, nil, class: "panel-collapse collapse") do
          content_tag(:div, nil, class: "panel-body") do
            schema_object_spec_markup(property_definition)
          end
        end
      end
    end
  end

  def schema_object_primitive_property_markup(name, primitive_property_definition, required_properties)
    content_tag(:div, nil, class: "panel-group") do
      content_tag(:div, nil, class: "panel panel-schema") do
        content_tag(:div, nil, class: "panel-heading clearfix") do
          content_tag(:div, nil, class: "panel-title required") do #required
            content_tag(:div, nil, class: "col-md-6") do
              content_tag(:span, name, class: "name") +
              content_tag(:p, primitive_property_definition['type'] || '', class: "data-type") +
              content_tag(:p, primitive_property_definition['description'] || '', class: "description")
            end +
            content_tag(:div, nil, class: "col-md-6 text-right") do
              content_tag(:a, class: "btn btn-static link-schema") do
                content_tag(:span, "schema")
              end +
              content_tag(:ul) do
                schema_object_specific_markup(primitive_property_definition)
              end
            end
          end
        end
      end
    end
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
    end
  end

  def array_specific_markup(property_definition)
    max = property_definition['maxItems']
    min = property_definition['minItems']
    if property_definition['uniqueItems'].present?
      concat(content_tag(:li, "items únicos"))
    end
    if max.present? && min.present?
      if max == min
        concat(content_tag(:li, "largo #{max} elemento" + (max!=1 ? "s" : "")))
      else
        concat(content_tag(:li, "rango #{min}-#{max}"))
      end
    else
      concat(content_tag(:li, "máximo #{max} elemento" + (max!=1 ? "s" : ""))) if max.present?
      concat(content_tag(:li, "mínimo #{min} elemento" + (min!=1 ? "s" : ""))) if min.present?
    end
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
    if max.present? && min.present?
      if max == min
        concat(content_tag(:li, "largo #{max}"))
      else
        concat(content_tag(:li, "rango #{min}-#{max}"))
      end
    else
      concat(content_tag(:li, "máximo #{max}")) if max.present?
      concat(content_tag(:li, "mínimo #{min}")) if min.present?
    end
  end
end