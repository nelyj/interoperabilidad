class Schema < ApplicationRecord
  belongs_to :schema_category
  has_many :schema_versions

  validates :name, uniqueness: true

  after_create :create_first_version

  attr_accessor :spec

  def to_param
    name
  end

  def create_first_version
    schema_versions.create(spec: self.spec)
  end

  def last_version_number
    schema_versions.maximum(:version_number) || 0
  end
end
