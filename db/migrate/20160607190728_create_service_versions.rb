class CreateServiceVersions < ActiveRecord::Migration[5.0]
  def change
    create_table :service_versions do |t|
      t.integer :service_id, null: false
      t.integer :version_number, null: false
      t.jsonb :spec, null: false

      t.timestamps
    end
    add_foreign_key :service_versions, :services
  end
end
