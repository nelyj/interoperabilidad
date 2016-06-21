module HomeHelper

  def schema_markup(schema_version)
    content_tag(:div, class: "schema-spec-block") do
      content_tag(:h1, schema_version.schema.name) +
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
      # OMG, inception
      schema_object_complex_property_markup(name, property_definition, required_properties)
    elsif property_definition["type"] == "array"
      # Damn, weird inception
      content_tag(:div, class: required_properties.include?(name) ? "property-required" : "property") do
        content_tag(:h2, name, class: "property-name") +
        content_tag(:h3, property_definition['type'] || '', class: "property-type") +
        content_tag(:p, property_definition['description'] || '', class: "property-description")+
        schema_object_property_markup("(elementos)", property_definition["items"], required_properties)
      end
      #TODO
    else
      schema_object_primitive_property_markup(name, property_definition, required_properties)
    end
  end

  def schema_object_complex_property_markup(name, property_definition, required_properties)
    content_tag(:div, class: required_properties.include?(name) ? "property-required" : "property") do
      content_tag(:h2, name, class: "property-name") +
      content_tag(:h3, property_definition['type'] || '', class: "property-type") +
      content_tag(:p, property_definition['description'] || '', class: "property-description") +
      schema_object_spec_markup(property_definition)
      # etc, etc
    end
  end

  def schema_object_primitive_property_markup(name, primitive_property_definition, required_properties)
    content_tag(:div, class: required_properties.include?(name) ? "property-required" : "property") do
      content_tag(:h2, name, class: "property-name") +
      content_tag(:h3, primitive_property_definition['type'] || '', class: "property-type") +
      content_tag(:p, primitive_property_definition['description'] || '', class: "property-description")
      # etc, etc
    end
  end
end