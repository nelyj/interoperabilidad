class AddRevisionNumberToAgreementRevision < ActiveRecord::Migration[5.0]
  def change
    add_column :agreement_revisions, :revision_number, :integer
  end
end
