class DataCategory < ApplicationRecord
  has_many :service_data_categories, dependent: :destroy
  has_many :schema_data_categories, dependent: :destroy
  has_many :services, through: :service_data_categories
  has_many :schemas, through: :schema_data_categories
end
