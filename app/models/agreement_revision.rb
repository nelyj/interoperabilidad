class AgreementRevision <ApplicationRecord
  include S3Configuration
  belongs_to :agreement
  belongs_to :user
  before_create :set_revision_number

  #enum status: [:proposed, :current, :rejected, :retracted, :outdated, :retired]

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
