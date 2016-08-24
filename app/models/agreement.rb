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
      log: I18n.t(:created_draft)
      )
  end

  def last_revision_number
    agreement_revisions.maximum(:revision_number) || 0
  end

  def last_revision
    agreement_revisions.first
  end

  def new_revision(user,new_state,log,message)
    agreement_revisions.create(
      user: user,
      state: new_state,
      purpose: last_revision.purpose,
      legal_base: last_revision.legal_base,
      log: log,
      file: last_revision.file,
      objection_message: message
    )
  end

  def next_step
    case state
    when 'draft'
      'validated_draft'
    when 'validated_draft'
      'signed_draft'
    when 'objected'
      'draft'
    when 'signed_draft'
      'validated'
    when 'validated'
      'signed'
    when 'rejected_sign'
      'signed'
    else
      ''
    end
  end

  def user_can_update_agreement_status?(user, org)
    role = AgreementRevision.state_to_role(next_step)
    user.roles.where(organization: org, name: role).exists?
  end

  def validate_draft(user)
    new_state = AgreementRevision.states['validated_draft']
    #check if user is a prosecutor and state alows the change.
    return nil unless user_can_update_agreement_status?(user, service_consumer_organization) && last_revision.draft?
    new_revision(user,new_state, I18n.t(:sent_draft),"")
  end

  def object_draft(user, message)
    new_state = AgreementRevision.states['objected']
    return nil unless user_can_update_agreement_status?(user, service_consumer_organization) && last_revision.validated_draft?
    new_revision(user, new_state, I18n.t(:objected_draft), message)
  end

  def sign_draft(user)
    new_state = AgreementRevision.states['signed_draft']
    return nil unless user_can_update_agreement_status?(user, service_consumer_organization) && last_revision.validated_draft?
    new_revision(user, new_state, I18n.t(:signed_draft), "")
  end

  def validate_revision(user)
    new_state = AgreementRevision.states['validated']
    return nil unless user_can_update_agreement_status?(user, service_provider_organization) && last_revision.signed_draft?
    new_revision(user, new_state, I18n.t(:validated_agreement), "")
  end

  def sign(user)
    new_state = AgreementRevision.states['signed']
    return nil unless user_can_update_agreement_status?(user, service_provider_organization) && last_revision.validated?
    new_revision(user, new_state, I18n.t(:signed_agreement), "")
  end

  def reject_sign(user, message)
    new_state = AgreementRevision.states['rejected_sign']
    return nil unless user_can_update_agreement_status?(user, service_provider_organization) && last_revision.validated?
    new_revision(user, new_state, I18n.t(:rejected_sign), message)
  end

end
