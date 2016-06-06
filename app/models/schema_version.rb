class SchemaVersion < ApplicationRecord
  belongs_to :schema
  validates :spec, swagger_schema_object: true
  before_create :set_version_number

  def to_param
    version_number.to_s
  end

  def set_version_number
    last_version = schema.schema_versions.maximum(:version_number) || 0
    self.version_number = last_version.to_i + 1
  end
end
