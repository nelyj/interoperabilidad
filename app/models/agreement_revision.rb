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
  # Until it is "validated" by consumer fiscal, where a "validated_draft" is generated.
  # Then, it is reviewed by consumer undersecretary, and a "signed_draft" is crated.
  # If the "validated_draft" isn't approved, it becomes objected and can ve reviewed again by the fiscal.
  # A "signed_draft" is reviewed by the provider fiscal.
  # If it's approved a "validated" revision is born.
  # and it's send to the provider organization undersecretary.
  # If the "signed_draft" is objected by the provider organization fiscal, it can be reviewed again by the consumer organization fiscal.
  # An "approved" agreement, can be "signed" by provider organization undersecretary, and the it's send to the "Signing Proces".
  # If the "approved" agreement, is "objected" by the undersecretary, it goes back to the fiscal, who can "validate" it again, or "object" again, so it goes back to the consumer fiscal.
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
    new_object.acl = :public_read
    new_object.content_type = 'application/pdf'
    new_object.save
    self.file = new_object.url
  end
end
