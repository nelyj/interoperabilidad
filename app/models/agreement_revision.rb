class AgreementRevision <ApplicationRecord
  include S3Configuration
  belongs_to :agreement
  belongs_to :user
  before_create :set_revision_number
  attr_readonly :state
  default_scope -> { order('created_at DESC') }

  # draft: 0, validated_draft: 1, objected: 2, signed_draft:3 , validated:4 , rejected_sign:5, signed:6
  #
  # The lifecycle is as follows:
  #
  # A new agreement revision is born as "draft".
  # Until it is "validated" by consumer prosecutor, where a "validated_draft" is generated.
  # Then, it is reviewed by consumer undersecretary, and a "signed_draft" is crated.
  # If the "validated_draft" isn't approved, it becomes objected and can ve reviewed again by the prosecutor.
  # A "signed_draft" is reviewed by the provider prosecutor.
  # If it's approved a "validated" revision is born.
  # and it's send to the provider organization undersecretary.
  # If the "signed_draft" is objected by the provider organization prosecutor, it can be reviewed again by the consumer organization prosecutor.
  # An "approved" agreement, can be "signed" by provider organization undersecretary, and the it's send to the "Signing Proces".
  # If the "approved" agreement, is "objected" by the undersecretary, it goes back to the prosecutor, who can "validate" it again, or "object" again, so it goes back to the consumer prosecutor.
  #
  # ALWAYS add new states at the end.
  enum state: [:draft, :validated_draft, :objected, :signed_draft, :validated, :rejected_sign, :signed]

  def to_param
    revision_number.to_s
  end

  def set_revision_number
    self.revision_number = agreement.last_revision_number + 1
  end

  def upload_pdf(file_name, file_path)
    new_object = codegen_bucket.objects.build(file_name)
    new_object.content = open(file_path)
    new_object.content_type = 'application/pdf'
    new_object.save
    self.file = file_name
  end

  def request_pdf_url
    object = codegen_bucket.objects.find(self.file)
    object.temporary_url
  end

  def create_new_notification
    org = Organization.where(dipres_id: "AB01")
    Role.where(name: "Service Provider", organization: org).each do |role|
      role.user.notifications.create(subject: self,
        message: log, email: role.email
      )
    end
  end

  def create_state_change_notification(status)
    email = user.roles.where(organization: organization, name: "Service Provider").first.email
    user.notifications.create(subject: self,
      message: I18n.t(:create_state_change_notification, name: name,
        version: self.version_number.to_s, status: status), email: email
    )
  end

  def responsable_email
    case state
    when 'draft', 'objected','validated_draft', 'signed_draft'
      role = user.roles.where(name: AgreementRevision.state_to_role(state), organization: agreement.service_consumer_organization).first
      return role.email unless role.nil?
    when 'validated', 'rejected_sign', 'signed'
      role = user.roles.where(name: AgreementRevision.state_to_role(state), organization: agreement.service_provider_organization).first
      return role.email unless role.nil?
    end
    return ''
  end

  def self.state_to_role(state)
    case state
    when 'draft', 'objected'
      return "Create Agreement"
    when 'validated_draft', 'validated', 'rejected_sign'
      return "Validate Agreement"
    when 'signed_draft', 'signed'
      return "Sign Agreement"
    end
  end

end
