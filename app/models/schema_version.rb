require 'open3'

class SchemaVersion < ApplicationRecord
  belongs_to :schema
  validates :spec, swagger_schema_object: true
  before_create :set_version_number
  before_save :update_spec_with_resolved_refs
  after_save :update_search_metadata
  validate :spec_file_must_be_parseable
  attr_accessor :spec_file_parse_exception

  def spec_file_must_be_parseable
    if self.spec_file_parse_exception
      errors.add(:spec_file, "Archivo no está en formato JSON o YAML: #{spec_file_parse_exception}")
    end
  end

  def spec_file
    @spec_file
  end

  def spec_file=(spec_file)
    self.spec_file_parse_exception = nil
    @spec_file = spec_file
    self.spec = YAML.safe_load(spec_file.read)
  rescue Psych::SyntaxError => e
    self.spec_file_parse_exception = e
  end

  def to_param
    version_number.to_s
  end

  def set_version_number
    self.version_number = schema.last_version_number + 1
  end

  def description
    spec['description']
  end

  def update_spec_with_resolved_refs
    output, _ = Open3.capture2("sway-resolve -s", :stdin_data => spec.to_json)
    # spec_with_resolved_refs will have two keys:
    # - `spec_with_resolved_refs['definition']`, will mirror `self.spec`
    #   but with all $refs replaced by the resolved/expanded content
    # - `spec_with_resolved_refs['references']` will contain a hash with an
    #   entry for every reference that has been resolved. Each entry in the hash
    #   will have the JSON Pointer of the parent element where a $ref was found
    #   as a key. And the value will include 'uri' (with the original ref URI),
    #  'type' (which can take the values 'local', 'remote'), among others. See
    #  the output of the sway-resolve command for more details.
    self.spec_with_resolved_refs = JSON.parse(output)
  end

  def update_search_metadata
    schema.update_search_metadata if self.version_number == schema.last_version_number
  end

  def example
    self.spec['example']
  end

  def has_previous_version?
    return !previous_version.nil?
  end

  def previous_version
    self.schema.schema_versions.where(version_number: self.version_number - 1).take
  end

  def has_next_version?
    return !next_version.nil?
  end

  def next_version
    self.schema.schema_versions.where(version_number: self.version_number + 1).take
  end
end
