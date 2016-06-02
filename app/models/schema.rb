class Schema < ApplicationRecord
  belongs_to :schema_category
  has_many :schema_versions
end
