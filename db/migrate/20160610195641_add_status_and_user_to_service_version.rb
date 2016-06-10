class AddStatusAndUserToServiceVersion < ActiveRecord::Migration[5.0]
  def change
    add_column :service_versions, :status, :integer, default: 0
    add_column :service_versions, :user_id, :integer, null: false
    add_foreign_key :service_versions, :users
  end
end
