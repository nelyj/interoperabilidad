class SchemaVersion < ApplicationRecord
  belongs_to :schema
  validates :spec, swagger_schema_object: true
  before_create :set_version_number
  after_save :update_search_metadata

  def spec_file
    @spec_file
  end

  def spec_file=(spec_file)
    @spec_file = spec_file
    self.spec = JSON.parse(spec_file.read)
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

  def update_search_metadata
    schema.update_search_metadata if self.version_number == schema.last_version_number
  end
end
