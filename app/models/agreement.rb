class Agreement <ApplicationRecord
  belongs_to :service_provider_organization, :class_name => 'Organization'
  belongs_to :service_consumer_organization, :class_name => 'Organization'
  has_many :organizations
  has_many :agreement_revisions, -> { order('revision_number DESC') }
  has_and_belongs_to_many :services
  after_create :create_first_revision
  validates :service_provider_organization, presence: true
  validates :services, presence: true
  attr_accessor :purpose, :legal_base, :user

  def create_first_revision
    agreement_revisions.create!(purpose: self.purpose, user: self.user,
      legal_base: self.legal_base, revision_number: 1)
  end

  def last_revision_number
    agreement_revisions.maximum(:revision_number) || 0
  end

  def last_revision
    agreement_revisions.first
  end

end
