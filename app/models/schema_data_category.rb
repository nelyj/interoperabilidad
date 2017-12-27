class SchemaDataCategory < ApplicationRecord
  belongs_to :schema
  belongs_to :data_category
end
  