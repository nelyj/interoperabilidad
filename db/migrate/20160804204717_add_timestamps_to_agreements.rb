class AddTimestampsToAgreements < ActiveRecord::Migration[5.0]
  def change
    change_table :agreements do |t|
      t.timestamps
    end
    change_table :agreement_revisions do |t|
      t.timestamps
    end
  end
end
