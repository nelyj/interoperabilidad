class SchemaVersion < ApplicationRecord
  belongs_to :schema
  validates :spec, swagger_schema_object: true
  before_create :set_version_number
  before_validation :read_spec

  attr_accessor :spec_file

  def to_param
    version_number.to_s
  end

  def set_version_number
    self.version_number = schema.last_version_number + 1
  end

  def read_spec
    self.spec = self.spec_file.read
  end
end
