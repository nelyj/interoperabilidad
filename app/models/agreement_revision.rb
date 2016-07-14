class AgreementRevision <ApplicationRecord
  belongs_to :agreement
  belongs_to :user
  has_and_belongs_to_many :services

  #enum status: [:proposed, :current, :rejected, :retracted, :outdated, :retired]
end
