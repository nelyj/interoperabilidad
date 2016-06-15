class Service < ApplicationRecord
  belongs_to :organization
  has_many :service_versions

  validates :name, uniqueness: true

  attr_accessor :spec_file

  def to_param
    name
  end

  def create_first_version(user)
    service_versions.create(spec_file: self.spec_file, user: user)
  end

  def last_version_number
    service_versions.maximum(:version_number) || 0
  end

  def can_be_updated_by?(user)
    user.organizations.exists?(id: organization.id)
  end
end
