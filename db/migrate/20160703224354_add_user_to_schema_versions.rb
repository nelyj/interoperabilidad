class AddUserToSchemaVersions < ActiveRecord::Migration[5.0]
  def up
    add_column :schema_versions, :user_id, :integer
    execute 'UPDATE schema_versions SET user_id = (SELECT id FROM users LIMIT 1)'
    change_column_null :schema_versions, :user_id, false
    add_foreign_key :schema_versions, :users
  end

  def down
    remove_column :schema_versions, :user_id
  end
end
