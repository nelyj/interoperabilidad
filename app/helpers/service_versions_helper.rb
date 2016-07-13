module ServiceVersionsHelper
  def service_operation_markup(service_version, verb, path)
    service_operation_content_markup(
      path, verb,
      service_version.operation(verb, path),
      service_version.common_parameters_for_path(path),
      json_pointer_path('/paths', path, verb),
      service_version.spec_with_resolved_refs['references']
    )
  end

  def css_class_for_http_verb(verb)
    {
      'get' => 'info',
      'post' => 'success',
      'put' => 'warning',
      'delete' => 'danger'
    }[verb] || ''
  end

  def service_operation_content_markup(path, verb, operation, common_parameters, json_pointer, references)
    if operation['parameters'].present?
      common_parameters += operation['parameters']
    end
    content_tag(:h2, 'Parámetros') +
    service_operation_parameters_distribution(common_parameters) +
    content_tag(:h2, 'Respuestas') +
    service_operation_responses_markup(operation['responses'])
  end

  def service_operation_responses_markup(responses)
    join_markup(responses.map do |name, response|
      content_tag(:h3, name) +
      content_tag(:p, response['description']) +
      response_schema_object_markup(response['schema']) +
      response_headers_markup(response['headers']) +
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

  def response_headers_markup(headers)
    if headers.present?
      join_markup(headers.map do |name, header|
        schema_object_property_markup(name, header, false, '/', '')
      end)
    end
  end

  def response_schema_object_markup(schema)
    if schema.present?
      case schema["type"]
        when "object"
          schema_object_spec_markup(schema, '/', '')
        else
          schema_object_property_markup('', schema, false, '/', '')
        end
    else
      return ''
    end
  end

  def service_operation_parameters_distribution(parameters)
    distributed_params = {
      'body' => [], 'query' => [], 'header' => [], 'path' => [], 'formData' => []
    }
    parameters.each do |parameter|
      distributed_params[parameter['in']].push(parameter)
    end
    if distributed_params.values.join.empty?
      content_tag(:p, "Esta operación no posee parametros")
    else
      service_distributed_parameters(distributed_params)
    end
  end

  def service_distributed_parameters(distributed_params)
    join_markup(distributed_params.map do |location, parameters|
      service_distributed_parameter_markup(location, parameters) unless parameters.empty?
    end)
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

  def service_distributed_parameter_markup(location, parameters)
    content_tag(:h3, parameter_section_name(location)) +
    content_tag(:div, class: "schema-panel-set detail") do
      join_markup(parameters.map do |parameter|
        if location == 'body'
          if parameter['schema']['description'].blank?
            parameter['schema'].merge!({ 'description' => parameter['description'] })
          end
          schema_object_property_markup(parameter['name'],
            parameter['schema'], parameter['required'], '', '')
        else
          schema_object_property_markup(parameter['name'],
            parameter, parameter['required'], '', '')
        end
      end)
    end
  end

  def service_operation_parameters_schema_markup(schema, json_pointer, references)
    schema_object_complex_property_markup(
      schema['title'], schema['properties'], true, json_pointer, references
    )
  end
end
