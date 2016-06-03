class Schema < ApplicationRecord
  belongs_to :schema_category
  has_many :schema_versions

  def to_param
    name
  end
end
