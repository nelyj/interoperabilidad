class CreateSchemaVersions < ActiveRecord::Migration[5.0]
  def change
    create_table :schema_versions do |t|
      t.integer :schema_id, null: false
      t.integer :version_number, null: false
      t.jsonb :spec, null: false

      t.timestamps
    end

    add_foreign_key :schema_versions, :schemas
  end
end
