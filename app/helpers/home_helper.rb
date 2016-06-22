module HomeHelper

  def schema_markup(schema_version)
    content_tag(:div, class: "schema-spec-block") do #ID unico, el de schema
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
    content_tag(:div, nil, class: "panel-group", id: "#{name}" ) do
      content_tag(:div, nil, class: "panel panel-schema level-x") do
        content_tag(:div, nil, class: "panel-heading") do
          content_tag(:div, nil, class: "panel-title required") do
            content_tag(:p, name) +
            content_tag(:a, nil, data: {parent: "#{name}"}) do
              content_tag(:span, nil, class: "dot")
            end +
            content_tag(:h3, property_definition['type'] || '', class: "property-type") +
            content_tag(:p, property_definition['description'] || '', class: "property-description")
          end
        end +
        content_tag(:div, nil, class: "panel-collapse collapse", id: "#{name}") do
          content_tag(:div, nil, class: "panel-body") do
            schema_object_property_markup("(elementos)", property_definition["items"], required_properties)
          end
        end
      end
    end
  end

  def schema_object_complex_property_markup(name, property_definition, required_properties)
    content_tag(:div, nil, class: "panel-group", id: "#{name}" ) do
      content_tag(:div, nil, class: "panel panel-schema level-x") do
        content_tag(:div, nil, class: "panel-heading") do
          content_tag(:div, nil, class: "panel-title required") do
            content_tag(:p, name) +
            content_tag(:a, nil, data: {parent: "#{name}"}) do
              content_tag(:span, nil, class: "dot")
            end +
            content_tag(:h3, property_definition['type'] || '', class: "property-type") +
            content_tag(:p, property_definition['description'] || '', class: "property-description")
          end
        end +
        content_tag(:div, nil, class: "panel-collapse collapse", id: "#{name}") do
          content_tag(:div, nil, class: "panel-body") do
            schema_object_spec_markup(property_definition)
          end
        end
      end
    end
  end

  def schema_object_primitive_property_markup(name, primitive_property_definition, required_properties)
    content_tag(:div, nil, class: "panel-group", id: "#{name}" ) do
      content_tag(:div, nil, class: "panel panel-schema level-x") do
        content_tag(:div, nil, class: "panel-heading") do
          content_tag(:div, nil, class: "panel-title required") do
            content_tag(:p, name) +
            content_tag(:a, nil, data: {parent: "#{name}"}) do
              content_tag(:span, nil, class: "dot")
            end +
            content_tag(:h3, primitive_property_definition['type'] || '', class: "property-type") +
            content_tag(:p, primitive_property_definition['description'] || '', class: "property-description")
          end
        end
      end
    end
  end

  def schema_object_primitive_specific_markup(primitive_property_definition)
    case primitive_property_definition['type']
    when "string"
      string_primitive_markup(primitive_property_definition)
    end
  end

  def string_primitive_markup(primitive)
    max = primitive['maxLength']
    min = primitive['minLength']
    #if primitive['pattern'].present?
    #  content_tag(:p, "pattern #{primitive['pattern']}", class: "primitive-specific")
    #end
    if max.present? && min.present?
      if max == min
        content_tag(:p, "largo #{max}", class: "primitive-specific")
      else
        content_tag(:p, "rango #{min}-#{max}", class: "primitive-specific")
      end
    else
      content_tag(:p, "máximo #{max}", class: "primitive-specific") +
      content_tag(:p, "mínimo #{min}", class: "primitive-specific")
    end
  end
end