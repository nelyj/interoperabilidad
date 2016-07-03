class SchemaCategory < ApplicationRecord
  has_many :schemas
  scope :with_schemas, -> { joins(:schemas).distinct }
  default_scope -> { order('name ASC') }
end
