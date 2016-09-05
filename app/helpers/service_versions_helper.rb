module ServiceVersionsHelper


  def service_operation_responses_markup(service_version, verb, path)
    service_operation_responses_content_markup(
      service_version.operation(verb, path)['responses'],
      json_pointer_path('/paths', path, verb, 'responses'),
      service_version.spec_with_resolved_refs['references']
    )
  end

  def service_operation_parameters_markup(service_version, verb, path, location)
    path_parameters = service_version.path_parameters(path, location)
    operation_parameters = service_version.operation_parameters(verb, path, location)
    join_markup(path_parameters.map do |index, parameter|
      service_parameter_markup(
        location, parameter,
        json_pointer_path('/paths', path, 'parameters', index.to_s),
        service_version.spec_with_resolved_refs['references']
      )
    end) +
    join_markup(operation_parameters.map do |index, parameter|
      service_parameter_markup(
        location, parameter,
        json_pointer_path('/paths', path, verb, 'parameters', index.to_s),
        service_version.spec_with_resolved_refs['references']
      )
    end)
  end

  def service_operation_parameters_form(service_version, verb, path, location)
    path_parameters = service_version.path_parameters(path, location)
    operation_parameters = service_version.operation_parameters(verb, path, location)
    join_markup(path_parameters.map do |index, parameter|
      service_parameter_form(
        location, parameter,
        json_pointer_path('/paths', path, 'parameters', index.to_s), '/',
        service_version.spec_with_resolved_refs['references']
      )
    end) +
    join_markup(operation_parameters.map do |index, parameter|
      service_parameter_form(
        location, parameter,
        json_pointer_path('/paths', path, verb, 'parameters', index.to_s), '/',
        service_version.spec_with_resolved_refs['references']
      )
    end)
  end

  def css_class_for_http_verb(verb)
    {
      'get' => 'info',
      'post' => 'success',
      'put' => 'warning',
      'delete' => 'danger'
    }[verb] || ''
  end

  def service_operation_responses_content_markup(responses, json_pointer, references)
    join_markup(responses.map do |name, response|
      content_tag(:h3, name) +
      content_tag(:p, response['description']) +
      response_schema_object_markup(
        response['schema'],
        json_pointer_path(json_pointer, 'schema'), references
      ) +
      response_headers_markup(
        response['headers'],
        json_pointer_path(json_pointer, 'headers'), references
      ) +
      response_example_markup(response['examples'])
    end)
  end

  def response_example_markup(example)
    if example.present?
      content_tag(:div, class: 'box-code-example') do
        content_tag(:code, class: 'json') do
          preserve(JSON.pretty_generate example)
        end
      end
    else
      ''
    end
  end

  def response_headers_markup(headers, json_pointer, references)
    if headers.present?
      content_tag(:div, class: 'schema-panel-set detail') do
        join_markup(headers.map do |name, header|
          schema_object_property_markup(
            name, header, false,
            json_pointer_path(json_pointer, name), references
          )
        end)
      end
    end
  end

  def response_schema_object_markup(schema, json_pointer, references)
    if schema.present?
      content_tag(:div, class: 'schema-panel-set detail') do
        case schema["type"]
        when "object"
          schema_object_spec_markup(schema, json_pointer, references)
        else
          schema_object_property_markup(
            '', schema, false, json_pointer, references
          )
        end
      end
    else
      return ''
    end
  end

  def parameter_section_name(location)
    {
      'body' => 'Body',
      'query' => 'URL: Query',
      'header' => 'Header',
      'path' => 'URL: Path',
      'formData' => 'Body (form data)'
    }[location]
  end

  def service_parameter_markup(location, parameter, json_pointer, references)
    if location == 'body'
      if parameter['schema']['description'].blank?
        parameter['schema'].merge!('description' => parameter['description'])
      end
      schema_object_property_markup(parameter['name'],
        parameter['schema'], parameter['required'],
        json_pointer_path(json_pointer, 'schema'), references)
    else
      schema_object_property_markup(parameter['name'],
        parameter, parameter['required'],  json_pointer, references)
    end
  end

  def display_service_alert_msg(status)
    {
      'rejected' => {
        'title' => t(:version_rejected),
        'msg' => t(:version_rejected_msg),
        },
      'proposed' => {
        'title' => t(:service_pending_approval),
        'msg' => ''
        }
    }[status] || ''
  end

  def service_parameter_form(location, parameter, json_pointer, target_json_pointer, references)
    if location == 'body'
      if parameter['schema']['description'].blank?
        parameter['schema'].merge!('description' => parameter['description'])
      end
      schema_object_property_form(parameter['name'],
        parameter['schema'], parameter['required'],
        json_pointer_path(json_pointer, 'schema'), target_json_pointer, references)
    else
      schema_object_property_form(parameter['name'],
        parameter, parameter['required'],
        json_pointer, json_pointer_path(target_json_pointer, parameter['name']),
        references)
    end
  end

  def schema_object_property_form(name, property_definition, required, json_pointer, target_json_pointer, references)
    if property_definition["type"] == "object"
      schema_object_complex_property_form(
        name, property_definition, required, json_pointer, target_json_pointer, references
      )
    elsif property_definition["type"] == "array"
      schema_object_array_property_form(
        name, property_definition, required, json_pointer, target_json_pointer, references
      )
    else
      schema_object_primitive_property_form(
        name, property_definition, required, json_pointer, target_json_pointer, references
      )
    end
  end

  def dynamic_component_structure_form(field_name, s_name_markup, property_definition, required, json_pointer, target_json_pointer, references)
    s_type_and_format = s(property_definition['type']) || ''
    if property_definition.has_key?('format')
      s_type_and_format += "(#{s(property_definition['format'])})"
    end
    content_tag(:div, nil, class: "panel-group", data: {pointer: json_pointer, target: target_json_pointer }) do
      content_tag(:div, nil, class: "panel panel-schema") do
        editable_css =  %w(object array).include?(property_definition['type']) ? '' : 'editable '
        content_tag(:div, nil, class: "panel-heading #{editable_css}clearfix") do
          content_tag(:div, nil, class: "panel-title " + (required ? "required" : "")) do
            content_tag(:div, nil, class: "col-md-6") do
              s_name_markup
            end +
            content_tag(:div, nil, class: "col-md-6 text-right") do
              form_primitive_specifics(property_definition, field_name, required)
            end
          end
        end +
        content_tag(:div, nil, class: "panel-collapse collapse") do
          yield if block_given?
        end
      end
    end
  end

  def form_primitive_specifics(primitive, name, required)
    if primitive['enum']
      options = {'data-type' => primitive['type'], include_blank: !required}
      select_tag(name, options_for_select(primitive['enum']), options)
    else
      case s(primitive['type'])
      when "string"
        string_primitive_form(primitive, name, required)
      when "integer"
        integer_primitive_form(primitive, name, required)
      when "number"
        number_primitive_form(primitive, name, required)
      when "boolean"
        boolean_primitive_form(primitive, name, required)
      else
        "".html_safe
      end
    end
  end

  def string_primitive_form(primitive, name, required)
    options = {
      placeholder: "[ingresa texto]",
      required: required,
      maxlength: primitive['maxLength'],
      pattern: primitive['pattern'],
      data: {
        minLength: primitive['minLength']
      }
    }
    if primitive['format'].present?
      case s(primitive['format'])
      when 'password'
        password_field_tag(name, primitive['default'].to_s, options)
      when 'date-time'
        datetime_local_field_tag(name, primitive['default'].to_s, options)
      when 'date'
        date_field_tag(name, primitive['default'].to_s, options)
      else
        text_field_tag(name, primitive['default'].to_s, options)
      end
    else
      text_field_tag(name, primitive['default'].to_s, options)
    end
  end

  def integer_primitive_form(primitive, name, required)
    options = {
      placeholder: '[ingresa número]',
      required: required,
      data: {type: 'integer'}
    }
    numeric_primitive_form(primitive, name, options)
  end

  def number_primitive_form(primitive, name, required)
    options = {step: 'any', placeholder: '[ingresa número]', required: required, data: {type: 'number'}}
    numeric_primitive_form(primitive, name, options)
  end

  def numeric_primitive_form(primitive, name, options)
    options[:max] = primitive['maximum']
    options[:min] = primitive['minimum']
    options[:data] = {
      exclusiveMaximum: primitive['exclusiveMaximum'],
      exclusiveMinimum: primitive['exclusiveMinimum'],
      multipleOf: primitive['multipleOf']
    }
    number_field_tag(name, primitive['default'].to_s, options)
  end

  def boolean_primitive_form(primitive, name, required)
    check_box_tag(name, "true", primitive['default'] == 'true', required: required)
  end

  def schema_object_primitive_property_form(name, primitive_property_definition, required, json_pointer, target_json_pointer, references)
    css_class = "name"
    css_class.concat(" anonymous") if name.empty?
    s_name_markup = content_tag(:span, s(name), class: css_class)
    dynamic_component_structure_form(
      name, s_name_markup, primitive_property_definition, required,
      json_pointer, target_json_pointer, references
    )
  end

  def schema_object_complex_property_form(name, property_definition, required, json_pointer, target_json_pointer, references)
    s_name_markup = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, s(name), class: "name")
    end
    dynamic_component_structure_form(
      name, s_name_markup, property_definition, required, json_pointer, target_json_pointer, references
    ) do
      content_tag(:div, nil, class: "panel-body") do
        schema_object_spec_form(property_definition, json_pointer, target_json_pointer, references)
      end
    end
  end

  def schema_object_array_property_form(name, property_definition, required, json_pointer, target_json_pointer, references)
    s_name_markup = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, s(name), class: "name")
    end
    dynamic_component_structure_form(
      name, s_name_markup, property_definition, required, json_pointer, target_json_pointer, references
    ) do
      schema_object_array_property_initial_inputs_form(
        0, property_definition, json_pointer, target_json_pointer, references,
        is_template: true
      ) +
      (
        if required
          schema_object_array_property_initial_inputs_form(
            0, property_definition, json_pointer, target_json_pointer, references,
            is_template: false)
        else
          "".html_safe
        end
      ) +
      content_tag(:div, class: 'text-right') do
        content_tag(:a, "Agregar Elemento", class: "btn add-element", data: {context: target_json_pointer})
      end
    end
  end

  def schema_object_array_property_initial_inputs_form(index, property_definition, json_pointer, target_json_pointer, references, is_template: true)
    content_tag(:div, nil, class: "panel-body #{is_template ? 'clonable' : 'clone'}") do
      schema_object_property_form(
        "[#{index}]".html_safe, property_definition["items"], false,
        json_pointer_path(json_pointer, "items"), json_pointer_path(target_json_pointer, index.to_s), references
      )
    end
  end

  def schema_object_spec_form(schema_object, json_pointer, target_json_pointer, references)
    properties = schema_object['properties'] || {}
    join_markup(properties.map do |name, property_definition|
      required = (
        schema_object.has_key?("required") &&
        schema_object["required"].include?(name)
      )
      schema_object_property_form(
        name, property_definition, required,
        json_pointer_path(json_pointer, 'properties', name), json_pointer_path(target_json_pointer, name), references
      )
    end)
  end
end
