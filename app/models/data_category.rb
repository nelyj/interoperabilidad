class DataCategory < ApplicationRecord
  has_many :service_data_categories
  has_many :services, through: :service_data_categories
end
