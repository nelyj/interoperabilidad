class SchemaVersion < ApplicationRecord
  belongs_to :schema
  validates :spec, swagger_schema_object: true
end
