class ServiceVersion < ApplicationRecord
  belongs_to :service
  validates :spec, swagger_spec: true
  before_create :set_version_number

  def to_param
    version_number.to_s
  end

  def set_version_number
    self.version_number = service.last_version_number + 1
  end
end
