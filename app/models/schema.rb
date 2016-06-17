class Schema < ApplicationRecord
  belongs_to :schema_category
  has_many :schema_versions

  validates :name, uniqueness: true
  attr_accessor :spec
  validates :spec, swagger_schema_object: true
  after_create :create_first_version

  def spec_file
    @spec_file
  end

  def spec_file=(spec_file)
    @spec_file = spec_file
    self.spec = JSON.parse(spec_file.read)
  end

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
