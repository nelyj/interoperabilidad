class Agreement <ApplicationRecord
  belongs_to :service_provider_organization, :class_name => 'Organization'
  belongs_to :service_consumer_organization, :class_name => 'Organization'
  has_many :organizations
  has_many :agreement_revisions
  attr_accessor :purpose, :legal_base, :services

  def create_first_revision(user)
    revision = agreement_revisions.create(purpose: self.purpose, user: user,
      legal_base: self.legal_base, service_ids: self.services)
  end
end
