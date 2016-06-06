class AddRoleNameToRoles < ActiveRecord::Migration[5.0]
  def change
    add_column :roles, :name, :string, null: false
  end
end
