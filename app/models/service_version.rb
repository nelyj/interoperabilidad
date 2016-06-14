class ServiceVersion < ApplicationRecord
  belongs_to :service
  belongs_to :user
  validates :spec, swagger_spec: true
  before_create :set_version_number
  before_validation :read_spec

  # proposed: 0, current: 1, rejected: 2, retracted:3 , outdated:4 , retired:5
  # Always add new states at the end.
  enum status: [:proposed, :current, :rejected, :retracted, :outdated, :retired]

  attr_accessor :spec_file

  def to_param
    version_number.to_s
  end

  def set_version_number
    self.version_number = service.last_version_number + 1
  end

  def read_spec
    self.spec = JSON.parse(self.spec_file.read)
  end
end
