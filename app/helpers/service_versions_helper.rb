module ServiceVersionsHelper

  def service_params_markup(service_version)
    name = service_version.service.name
    spec = service_version.spec_with_resolved_refs['definition']
    references = service_version.spec_with_resolved_refs['references']
    content_tag(:div, class: "schema-panel-set detail", data: {name: name, version: service_version.version_number}) do
      content_tag(:h3, "Paths") + service_path_markup(spec, '/', references)
    end
  end

  def service_path_markup(service_spec, json_pointer, references)
    join_markup(service_spec['paths'].map do |path, operations|
      service_path_operation_markup(
        path, operations, json_pointer_path(json_pointer, path), references
      )
    end)
  end

  def service_operations(service_spec)
    join_markup(service_spec['paths'].map do |path, operations|
      join_markup(operations.map do |verb, operation|
        if verb != 'parameters'
          content_tag(:li) do
            content_tag(:a) do
              content_tag(:span, verb, class: 'btn btn-status '+ class_definer(verb) + ' full') +
              content_tag(:span, path, class: 'path')
            end
          end
        end
      end)
    end)
  end

  def service_path_operation_markup(path, operations, json_pointer, references)
    common_parameters = operations.extract!('parameters')['parameters'] || []
    content_tag(:ul, class: 'list-operations') do
      join_markup(operations.map do |verb, operation|
        service_operation_content_markup(path, verb, operation, common_parameters,
          json_pointer, references) + '<br>'.html_safe
      end)
    end
  end

  def class_definer(verb)
    options = {
      'get' => 'info', 'post' => 'success', 'put' => 'warning', 'delete' => 'danger'
    }
    options[verb] || ''
  end

  def service_operation_content_markup(path, verb, operation, common_parameters, json_pointer, references)
    if operation['parameters'].present?
        common_parameters = common_parameters + operation['parameters']
    end
    content_tag(:li) do
      content_tag(:a) do
        content_tag(:span, verb, class: 'btn btn-status '+
          class_definer(verb) + ' full') + path + '<br>'.html_safe +
          content_tag(:h3, operation['summary']) +
          content_tag(:h2, 'Parámetros') +
          service_operation_parameters_distribution(common_parameters) +
          content_tag(:h2, 'Respuestas') +
          service_operation_responses_markup(operation['responses'])
      end
    end
  end

  def service_operation_responses_markup(responses)
    join_markup(responses.map do |name, response|
      content_tag(:h3, name) +
      content_tag(:p, response['description']) +
      response_schema_object_markup(response['schema']) +
      response_headers_markup(response['headers'])
    end)
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

  def service_distributed_parameter_markup(location, parameters)
    content_tag(:h3, location) +
    content_tag(:div, class: "schema-panel-set detail") do
      join_markup(parameters.map do |parameter|
        #service_parameter_markup(parameter) +
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

  def service_parameter_markup(parameter)
    content_tag(:p, parameter['description']) +
    content_tag(:p, parameter['required'])
  end

  def service_operation_parameters_schema_markup(schema, json_pointer, references)
    schema_object_complex_property_markup(
      schema['title'], schema['properties'], true, json_pointer, references
    )
  end
end
