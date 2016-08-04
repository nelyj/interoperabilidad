class AddTimestampsToAgreementRevisions < ActiveRecord::Migration[5.0]
  def change
    add_column :agreement_revisions, :created_at, :datetime
    add_column :agreement_revisions, :updated_at, :datetime
  end
end
