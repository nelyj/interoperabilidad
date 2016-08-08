class Agreement <ApplicationRecord
  belongs_to :service_provider_organization, :class_name => 'Organization'
  belongs_to :service_consumer_organization, :class_name => 'Organization'
  has_many :organizations
  has_many :agreement_revisions
  after_create :create_first_revision
  attr_accessor :purpose, :legal_base, :user

  def services_list
    @services_list
  end

  def services_list=(services_list)
    @services_list = services_list.delete_if(&:blank?)
  end

  def create_first_revision
    agreement_revisions.create!(purpose: self.purpose, user: self.user,
      legal_base: self.legal_base, service_ids: self.services_list, revision_number: 1)
  end

  def last_revision_number
    agreement_revisions.maximum(:revision_number) || 0
  end

  def last_revision
    agreement_revisions.order('revision_number desc').first
  end

end
