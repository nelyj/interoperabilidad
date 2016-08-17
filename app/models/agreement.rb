class Agreement <ApplicationRecord
  belongs_to :service_provider_organization, :class_name => 'Organization'
  belongs_to :service_consumer_organization, :class_name => 'Organization'
  has_many :organizations
  has_many :agreement_revisions, -> { order('revision_number DESC') }
  has_and_belongs_to_many :services
  after_create :create_first_revision
  validates :service_provider_organization, presence: true
  validates :services, presence: true
  delegate :state, to: :last_revision
  attr_accessor :purpose, :legal_base, :user

  def create_first_revision
    agreement_revisions.create!(
      purpose: self.purpose,
      user: self.user,
      legal_base: self.legal_base,
      revision_number: 1,
      log: "First Revision Created"
      )
  end

  def last_revision_number
    agreement_revisions.maximum(:revision_number) || 0
  end

  def last_revision
    agreement_revisions.first
  end

  def validate_draft(user)
    #check if user is a fiscal
    #check if state permits
    if last_revision.draft?
      #create new revision with validated_draft state
      agreement_revisions.create(
        user: user,
        state: AgreementRevision.states['validated_draft'],
        purpose: last_revision.purpose,
        legal_base: last_revision.legal_base,
        log: "Draft validated",
        file: last_revision.file
      )
    else
      return nil
    end
  end

  def object_revision(user, message)
    #check if state permits
    if last_revision.validated_draft?
      #create new objected revision
      agreement_revisions.create(
        user: user,
        state: AgreementRevision.states['objected'],
        purpose: last_revision.purpose,
        legal_base: last_revision.legal_base,
        log: "Draft objected",
        file: last_revision.file,
        objection_message: message
      )
    else
      return nil
    end
  end

  def sign_draft(user)
    #check if state permits
    if last_revision.validated_draft?
      #create new object as signed_draft
      agreement_revisions.create(
        user: user,
        state: AgreementRevision.states['signed_draft'],
        purpose: last_revision.purpose,
        legal_base: last_revision.legal_base,
        log: "Draft Signed",
        file: last_revision.file,
      )
    else
      return nil
    end
  end

  def validate_revision(user)
    #check if state permits
    if last_revision.signed_draft?
      #create new object as validated
      agreement_revisions.create(
        user: user,
        state: AgreementRevision.states['validated'],
        purpose: last_revision.purpose,
        legal_base: last_revision.legal_base,
        log: "Agreement Validated",
        file: last_revision.file,
      )
    else
      return nil
    end
  end

  def sign(user)
    #check if state permits
    if last_revision.validated?
      #create new object as signed
      agreement_revisions.create(
        user: user,
        state: AgreementRevision.states['signed'],
        purpose: last_revision.purpose,
        legal_base: last_revision.legal_base,
        log: "Agreement Signed",
        file: last_revision.file,
      )
    else
      return nil
    end
  end

  def reject_sign(user, message)
    #check if state permits
    if last_revision.validated?
      #create new object as rejected_sign
      agreement_revisions.create(
        user: user,
        state: AgreementRevision.states['rejected_sign'],
        purpose: last_revision.purpose,
        legal_base: last_revision.legal_base,
        log: "Agreement Signature Rejected",
        file: last_revision.file,
      )
    else
      return nil
    end
  end

end
