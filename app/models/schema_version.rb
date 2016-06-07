class SchemaVersion < ApplicationRecord
  belongs_to :schema
  validates :spec, swagger_schema_object: true
  before_create :set_version_number

  def to_param
    version_number.to_s
  end

  def set_version_number
    self.version_number = last_version_number + 1
  end

  def last_version_number
    schema.schema_versions.maximum(:version_number) || 0
  end
end
