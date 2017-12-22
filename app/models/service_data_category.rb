class ServiceDataCategory < ApplicationRecord
  belongs_to :service
  belongs_to :data_category
end
