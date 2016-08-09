class RenameAgreementRevisionsServicesToAgreementsServices < ActiveRecord::Migration[5.0]
  def change

    rename_column :agreement_revisions_services, :agreement_revision_id, :agreement_id
    rename_table :agreement_revisions_services, :agreements_services

  end
end
