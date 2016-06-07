class CreateServices < ActiveRecord::Migration[5.0]
  def change
    create_table :services do |t|
      t.string :name, null: false
      t.integer :organization_id, null: false

      t.timestamps
    end
    add_foreign_key :services, :organizations
  end
end
