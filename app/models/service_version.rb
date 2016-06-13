class ServiceVersion < ApplicationRecord
  belongs_to :service
  belongs_to :user
  validates :spec, swagger_spec: true
  before_create :set_version_number
  before_validation :read_spec

  enum status: {pending: 0, approved: 1, rejected: -1}

  attr_accessor :spec_file

  def to_param
    version_number.to_s
  end

  def set_version_number
    self.version_number = service.last_version_number + 1
  end

  def read_spec
    self.spec = self.spec_file.read
  end
end
