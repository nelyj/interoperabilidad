class AddStatusAndUserToServiceVersion < ActiveRecord::Migration[5.0]
  def change
    add_column :service_versions, :status, :integer, default: 0
    add_column :service_versions, :user_id, :integer
    execute 'UPDATE service_versions SET user_id = (SELECT id FROM users LIMIT 1)'
    change_column_null :service_versions, :user_id, false

    add_foreign_key :service_versions, :users
  end
end
