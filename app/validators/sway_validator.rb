require 'open3'

class SwayValidator <  ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.present?
    warnings, errors = run_validation(value)
    unless warnings.empty? && errors.empty?
      (warnings + errors).each do |item|
        record.errors.add attribute,
          "#{item['path'].join('/')}:#{item['message']}"
      end
    end
  end

  def validation_command
    raise NotImplementedError, "subclass must implement this method with the
      right sway-validate command for its purposes"
  end

  def run_validation(spec)
    output, _ = Open3.capture2(validation_command, :stdin_data => spec.to_json)
    parsed_output = JSON.parse(output)
    return parsed_output['warnings'], parsed_output['errors']
  end
end
