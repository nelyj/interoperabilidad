class AgreementRevision <ApplicationRecord
  belongs_to :agreement
  belongs_to :user
  before_create :set_revision_number

  #enum status: [:proposed, :current, :rejected, :retracted, :outdated, :retired]

  def set_revision_number
    self.revision_number = agreement.last_revision_number + 1
  end

end
