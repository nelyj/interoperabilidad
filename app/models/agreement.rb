class Agreement <ApplicationRecord
  belongs_to :service_provider_organization, :class_name => 'Organization'
  belongs_to :service_consumer_organization, :class_name => 'Organization'
  has_many :organizations
  has_many :agreement_revisions
  after_create :create_first_revision
  attr_accessor :purpose, :legal_base, :services, :user

  def create_first_revision
    agreement_revisions.create(purpose: self.purpose, user: self.user,
      legal_base: self.legal_base, service_ids: self.services, revision_number: 1)
  end
end
