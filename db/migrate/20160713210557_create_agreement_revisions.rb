class CreateAgreementRevisions < ActiveRecord::Migration[5.0]
  def change
    create_table :agreement_revisions do |t|
      t.references :agreement
      t.references :user
      t.integer :state
      t.text :purpose
      t.text :legal_base
      t.string :log
      t.string :file
      t.text :objection_message
    end

    create_table :agreement_revisions_services do |t|
      t.belongs_to :agreement_revision, index: true
      t.belongs_to :service, index: true
    end

  end
end
