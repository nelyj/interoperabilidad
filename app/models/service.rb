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

  def self.search(text)
    Service.find_by_sql(
      "SELECT id, name, organization_id, public, document
        FROM(
          SELECT  service_versions.service_id as id,
            services.name,
            services.organization_id,
            services.public,
            service_versions.tsv ||
            services.tsv AS document
          FROM service_versions
          JOIN services ON service_versions.service_id = services.id
        ) s_search
      WHERE s_search.document @@ plainto_tsquery('es', '#{text}')
      ORDER BY ts_rank(s_search.document, plainto_tsquery('es', '#{text}')) DESC;")
  end
end
