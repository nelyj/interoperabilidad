class SchemaCategory < ApplicationRecord
  has_and_belongs_to_many :schemas
  scope :with_schemas, -> { joins(:schemas).distinct }
  default_scope -> { order('name ASC') }
end
