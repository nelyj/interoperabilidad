class AgreementRevision <ApplicationRecord
  include S3Configuration
  belongs_to :agreement
  belongs_to :user
  before_create :set_revision_number

  # draft: 0, validated_draft: 1, rejected: 2, signed_draft:3 , validated:4 , rejected_sign:5, signed:6
  #
  # The lifecycle is as follows:
  #
  # A new agreement revision is born as "draft".
  # Until it is validated by same organization fiscal, where it becomes "validated_draft".
  # Then, it is reviewed by same Organization undersecretary,
  # Also, once a subsequent version is accepted and becomes "current", the
  # previously current version becomes "outdated" if the change is backwards
  # compatible. If the change is NOT backwards compatible, it becomes "retired"
  #
  # ALWAYS add new states at the end.
  enum state: [:draft, :validated_draft, :rejected, :signed_draft, :validated, :rejected_sign, :signed]

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
