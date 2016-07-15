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
      join_markup(headers.map do |name, header|
        schema_object_property_markup(
          name, header, false,
          json_pointer_path(json_pointer, name), references
        )
      end)
    end
  end

  def response_schema_object_markup(schema, json_pointer, references)
    if schema.present?
      case schema["type"]
      when "object"
        schema_object_spec_markup(schema, json_pointer, references)
      else
        schema_object_property_markup(
          '', schema, false, json_pointer, references
        )
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
end
